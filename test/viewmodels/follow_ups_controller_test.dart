import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_query.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/application_validation.dart';
import 'package:jobtrack_desktop/features/applications/models/follow_up_policy.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/applications_controller.dart';
import 'package:jobtrack_desktop/features/follow_ups/viewmodels/follow_ups_controller.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 28, 10);
  final today = LocalDate(2026, 10, 28);
  LocalDate ago(int days) => today.addDays(-days);

  late FakeApplicationRepository repository;
  late FakeSettingsRepository settings;
  late FollowUpsController controller;

  void seed() {
    repository.store
      ..['due-old'] = buildApplication(
        id: 'due-old',
        companyName: 'Antiga',
        applicationDate: ago(20),
      )
      ..['due-new'] = buildApplication(
        id: 'due-new',
        companyName: 'Recente',
        applicationDate: ago(8),
      )
      ..['scheduled'] = buildApplication(
        id: 'scheduled',
        applicationDate: ago(2),
      )
      ..['closed'] = buildApplication(
        id: 'closed',
        applicationDate: ago(30),
        statusChanges: [(ApplicationStatus.withdrawn, ago(25))],
      )
      ..['limit'] = buildApplication(
        id: 'limit',
        applicationDate: ago(40),
        interactions: [
          contact(ago(30), InteractionType.followUpSent),
          contact(ago(20), InteractionType.followUpSent),
          contact(ago(10), InteractionType.followUpSent),
        ],
      );
  }

  setUp(() {
    repository = FakeApplicationRepository();
    settings = FakeSettingsRepository();
    controller = FollowUpsController(
      repository,
      settings,
      clock: () => now,
      newId: () => 'gen',
    );
    seed();
  });

  test('separa vencidas (mais antiga primeiro) e sugerido encerrar', () async {
    await controller.load();
    expect(controller.status.value, FollowUpsStatus.ready);
    expect(controller.due.map((e) => e.application.id), ['due-old', 'due-new']);
    expect(controller.suggestClose.map((e) => e.application.id), ['limit']);
    expect(controller.suggestClose.single.attempts, 3);
  });

  test('usa o prazo configurado', () async {
    settings.followUp = const FollowUpSettings(intervalDays: 1);
    await controller.load();
    expect(
      controller.due.map((e) => e.application.id),
      containsAll(['scheduled', 'due-old', 'due-new']),
    );
  });

  test('falha de leitura vira erro', () async {
    repository.failReads = true;
    await controller.load();
    expect(controller.status.value, FollowUpsStatus.error);
  });

  test('CA-FU-08: registrar contato tira o item da lista', () async {
    await controller.load();
    final entry = controller.due.firstWhere(
      (e) => e.application.id == 'due-new',
    );
    final ok = await controller.registerInteraction(
      entry.application,
      date: today,
      type: InteractionType.followUpSent,
      summary: '',
      receivedResponse: false,
    );
    expect(ok, isTrue);
    expect(controller.due.map((e) => e.application.id), ['due-old']);
    expect(repository.store['due-new']!.interactions, hasLength(1));
  });

  test('adiar grava a data manual e tira da lista', () async {
    await controller.load();
    final app = controller.due.first.application;
    expect(controller.validatePostpone(ago(1)), ValidationCode.pastDate);
    expect(controller.validatePostpone(today), isNull);

    expect(await controller.postpone(app, today.addDays(3)), isTrue);
    expect(repository.store[app.id]!.manualNextFollowUpAt, today.addDays(3));
    expect(
      controller.due.map((e) => e.application.id),
      isNot(contains(app.id)),
    );
  });

  test('encerrar sem resposta muda o status e tira da lista', () async {
    await controller.load();
    final app = controller.suggestClose.single.application;
    expect(await controller.closeWithoutResponse(app), isTrue);

    final saved = repository.store['limit']!;
    expect(saved.status, ApplicationStatus.closedWithoutResponse);
    expect(saved.statusHistory.last.changedAt, now);
    expect(controller.suggestClose, isEmpty);
  });

  test('falha ao gravar mantém as listas', () async {
    await controller.load();
    repository.failWrites = true;
    final app = controller.due.first.application;
    expect(await controller.postpone(app, today.addDays(3)), isFalse);
    expect(controller.due, hasLength(2));
    expect(controller.isBusy.value, isFalse);
  });

  test('CA-FU-13: mesma contagem na listagem e em Acompanhamentos', () async {
    await controller.load();
    final list = ApplicationsController(
      repository,
      settings,
      clock: () => now,
      initialFilter: const ApplicationFilter(onlyNeedingFollowUp: true),
    );
    await list.load();

    expect(
      list.visible.length,
      controller.due.length + controller.suggestClose.length,
    );
    expect(
      list.visible.where((a) => list.followUpOf(a) is FollowUpDue).length,
      controller.due.length,
    );
  });
}
