import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';
import 'package:jobtrack_desktop/features/settings/viewmodels/settings_controller.dart';

import '../support/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;
  late SettingsController controller;

  setUp(() {
    repository = FakeSettingsRepository();
    controller = SettingsController(repository, dataDirectory: r'C:\dados');
  });

  test('CA-SET-01: carrega os padrões 7 e 3', () async {
    await controller.load();
    expect(controller.status.value, SettingsStatus.ready);
    expect(controller.intervalText.value, '7');
    expect(controller.attemptsText.value, '3');
    expect(controller.isDirty, isFalse);
  });

  test('CA-SET-02: salvar grava os novos valores', () async {
    await controller.load();
    controller.setInterval('10');
    controller.setAttempts('2');
    expect(controller.isDirty, isTrue);

    expect(await controller.save(), SettingsSaveResult.saved);
    expect(repository.followUp.intervalDays, 10);
    expect(repository.followUp.maxAttempts, 2);
    expect(controller.isDirty, isFalse);
  });

  test('CA-SET-03: valores fora da faixa ou vazios são recusados', () async {
    await controller.load();
    for (final (interval, attempts) in [
      ('0', '3'),
      ('91', '3'),
      ('', '3'),
      ('7', '0'),
      ('7', '11'),
    ]) {
      controller.setInterval(interval);
      controller.setAttempts(attempts);
      expect(
        await controller.save(),
        SettingsSaveResult.invalid,
        reason: '$interval/$attempts',
      );
    }
    expect(repository.followUp.intervalDays, 7);
    expect(
      controller.intervalInvalid.value || controller.attemptsInvalid.value,
      isTrue,
    );
  });

  test('editar limpa a marca de inválido do campo', () async {
    await controller.load();
    controller.setInterval('0');
    await controller.save();
    expect(controller.intervalInvalid.value, isTrue);
    controller.setInterval('5');
    expect(controller.intervalInvalid.value, isFalse);
  });

  test('CA-SET-06: falha ao salvar mantém os valores anteriores', () async {
    repository.followUp = const FollowUpSettings(intervalDays: 5);
    await controller.load();
    repository.failWrites = true;
    controller.setInterval('20');

    expect(await controller.save(), SettingsSaveResult.failed);
    expect(controller.saved.intervalDays, 5);
    expect(controller.isDirty, isTrue);
    expect(controller.isSaving.value, isFalse);
  });

  test('falha ao carregar vira erro', () async {
    repository.failReads = true;
    await controller.load();
    expect(controller.status.value, SettingsStatus.error);
  });
}
