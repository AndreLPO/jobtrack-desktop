import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/application_validation.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/application_details_controller.dart';

import '../support/application_samples.dart';
import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';

void main() {
  final now = DateTime(2026, 10, 28, 15, 30);
  final today = LocalDate(2026, 10, 28);
  late FakeApplicationRepository repository;
  late FakeSettingsRepository settings;
  var ids = 0;

  ApplicationDetailsController build(String id) => ApplicationDetailsController(
    repository,
    settings,
    applicationId: id,
    clock: () => now,
    newId: () => 'gen-${ids++}',
  );

  Future<ApplicationDetailsController> loaded() async {
    repository.store['a'] = minimalApplication(id: 'a');
    final c = build('a');
    await c.load();
    return c;
  }

  setUp(() {
    repository = FakeApplicationRepository();
    settings = FakeSettingsRepository();
    ids = 0;
  });

  group('carregar', () {
    test('pronta com a candidatura', () async {
      final c = await loaded();
      expect(c.status.value, DetailsStatus.ready);
      expect(c.application.value!.id, 'a');
    });

    test('CA-E4-06: id inexistente → não encontrada', () async {
      final c = build('x');
      await c.load();
      expect(c.status.value, DetailsStatus.notFound);
    });

    test('falha de leitura → erro', () async {
      repository.failReads = true;
      final c = build('a');
      await c.load();
      expect(c.status.value, DetailsStatus.error);
    });
  });

  group('alterar status (F3)', () {
    test('CA-E4-03: grava A → B com nota e atualiza o estado', () async {
      final c = await loaded();
      expect(
        await c.changeStatus(ApplicationStatus.interview, note: '  remota '),
        isTrue,
      );

      final app = c.application.value!;
      expect(app.status, ApplicationStatus.interview);
      expect(app.statusHistory.last.previousStatus, ApplicationStatus.applied);
      expect(app.statusHistory.last.note, 'remota');
      expect(app.statusHistory.last.changedAt, now);
      expect(repository.store['a']!.status, ApplicationStatus.interview);
    });

    test('mesmo status não grava nada', () async {
      final c = await loaded();
      repository.failWrites = true;
      expect(await c.changeStatus(ApplicationStatus.applied), isTrue);
      expect(c.application.value!.statusHistory, hasLength(1));
    });

    test('CA-E4-03: falha mantém o status anterior', () async {
      final c = await loaded();
      repository.failWrites = true;
      expect(await c.changeStatus(ApplicationStatus.rejected), isFalse);
      expect(c.application.value!.status, ApplicationStatus.applied);
      expect(c.isBusy.value, isFalse);
    });
  });

  group('registrar contato (F4)', () {
    test('CA-E4-04: grava e atualiza último contato e resposta', () async {
      final c = await loaded();
      final ok = await c.registerInteraction(
        date: today,
        type: InteractionType.messageReceived,
        summary: '  ',
        receivedResponse: true,
        nextFollowUpAt: today.addDays(5),
      );

      expect(ok, isTrue);
      final app = c.application.value!;
      expect(app.lastContactAt, today);
      expect(app.hasResponse, isTrue);
      expect(app.interactions.single.summary, isNull, reason: 'D-53');
      expect(app.manualNextFollowUpAt, today.addDays(5), reason: 'D-21a');
      expect(app.status, ApplicationStatus.applied, reason: 'D-11');
    });

    test('validação usa a data de hoje do relógio', () {
      final c = build('a');
      expect(
        c
            .validateContact(
              date: today.addDays(1),
              type: InteractionType.call,
              nextFollowUpAt: today.addDays(-1),
            )
            .map((e) => e.code),
        [ValidationCode.futureDate, ValidationCode.pastDate],
      );
    });

    test('falha não altera o estado', () async {
      final c = await loaded();
      repository.failWrites = true;
      final ok = await c.registerInteraction(
        date: today,
        type: InteractionType.call,
        summary: '',
        receivedResponse: false,
      );
      expect(ok, isFalse);
      expect(c.application.value!.interactions, isEmpty);
    });

    test('D-55: excluir contato', () async {
      final c = await loaded();
      await c.registerInteraction(
        date: today,
        type: InteractionType.call,
        summary: '',
        receivedResponse: false,
      );
      final id = c.application.value!.interactions.single.id;

      expect(await c.removeInteraction(id), isTrue);
      expect(c.application.value!.interactions, isEmpty);
      expect(repository.store['a']!.interactions, isEmpty);
    });
  });

  group('mensagem de acompanhamento (D-27)', () {
    test('usa o modelo salvo com as variáveis da candidatura', () async {
      final c = await loaded();
      settings.messageTemplate = '{empresa}/{vaga}/{data}/{contato}';
      expect(
        await c.followUpMessage(),
        'Globex/QA/02/10/2026/equipe de recrutamento',
      );
    });

    test('falha ao ler o modelo devolve null', () async {
      final c = await loaded();
      settings.failReads = true;
      expect(await c.followUpMessage(), isNull);
    });
  });

  group('excluir', () {
    test('CA-E4-05: remove do repositório', () async {
      final c = await loaded();
      expect(await c.delete(), isTrue);
      expect(repository.store, isEmpty);
    });

    test('falha devolve false', () async {
      final c = await loaded();
      repository.failWrites = true;
      expect(await c.delete(), isFalse);
      expect(repository.store, hasLength(1));
    });
  });
}
