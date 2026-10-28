import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/dashboard/viewmodels/dashboard_controller.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 28, 9);
  final today = LocalDate(2026, 10, 28);
  late FakeApplicationRepository repository;
  late FakeSettingsRepository settings;
  late DashboardController controller;

  setUp(() {
    repository = FakeApplicationRepository();
    settings = FakeSettingsRepository();
    controller = DashboardController(repository, settings, clock: () => now);
  });

  test('calcula os indicadores com o prazo configurado', () async {
    repository.store['a'] = buildApplication(
      id: 'a',
      applicationDate: today.addDays(-4),
    );
    await controller.load();
    expect(controller.status.value, DashboardStatus.ready);
    expect(controller.metrics.value!.dueFollowUps, 0);

    settings.followUp = const FollowUpSettings(intervalDays: 3);
    await controller.load();
    expect(controller.metrics.value!.dueFollowUps, 1);
  });

  test('CA-DSH-07: recarregar reflete exclusões', () async {
    repository.store['a'] = buildApplication(id: 'a', applicationDate: today);
    await controller.load();
    expect(controller.metrics.value!.thisWeek, 1);

    repository.store.remove('a');
    await controller.load();
    expect(controller.metrics.value!.total, 0);
    expect(controller.metrics.value!.thisWeek, 0);
  });

  test('falha de leitura vira erro', () async {
    repository.failReads = true;
    await controller.load();
    expect(controller.status.value, DashboardStatus.error);
  });

  test('informa registros ilegíveis', () async {
    repository.unreadableIds = ['x'];
    await controller.load();
    expect(controller.unreadableCount.value, 1);
  });
}
