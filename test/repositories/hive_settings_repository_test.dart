import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/database/hive_database.dart';
import 'package:jobtrack_desktop/core/errors/persistence_exception.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';
import 'package:jobtrack_desktop/features/settings/models/message_template.dart';
import 'package:jobtrack_desktop/features/settings/repositories/hive_settings_repository.dart';

void main() {
  late Directory directory;
  late HiveDatabase database;
  late HiveSettingsRepository repository;

  Future<void> openDatabase() async {
    database = HiveDatabase();
    await database.open(directory: directory.path);
    repository = HiveSettingsRepository(database.settings);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('jobtrack_test_');
    await openDatabase();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('CA-P-08: sem registro carrega padrões sem gravar nada', () async {
    final settings = await repository.loadFollowUp();
    expect(settings.intervalDays, FollowUpSettings.defaultIntervalDays);
    expect(settings.maxAttempts, FollowUpSettings.defaultMaxAttempts);
    expect(database.settings.isEmpty, isTrue);
  });

  test('CA-P-08: salvar 10/2 e reabrir carrega 10/2', () async {
    await repository.saveFollowUp(
      const FollowUpSettings(intervalDays: 10, maxAttempts: 2),
    );
    await database.close();
    await openDatabase();

    final settings = await repository.loadFollowUp();
    expect(settings.intervalDays, 10);
    expect(settings.maxAttempts, 2);
  });

  test('CA-P-09: registro ilegível usa padrões sem sobrescrever', () async {
    final stored = {'schemaVersion': 1, 'intervalDays': 500, 'maxAttempts': 3};
    await database.settings.put(HiveSettingsRepository.followUpKey, stored);

    final settings = await repository.loadFollowUp();
    expect(settings.intervalDays, FollowUpSettings.defaultIntervalDays);
    expect(database.settings.get(HiveSettingsRepository.followUpKey), stored);
  });

  test('falha de gravação vira PersistenceException(write)', () async {
    await database.close();
    await expectLater(
      repository.saveFollowUp(const FollowUpSettings()),
      throwsA(
        isA<PersistenceException>().having(
          (e) => e.operation,
          'operation',
          PersistenceOperation.write,
        ),
      ),
    );
  });

  group('modelo de mensagem', () {
    test('sem registro devolve o padrão sem gravar', () async {
      expect(
        await repository.loadMessageTemplate(),
        MessageTemplate.defaultText,
      );
      expect(database.settings.isEmpty, isTrue);
    });

    test('salvar e reabrir mantém o texto', () async {
      await repository.saveMessageTemplate('Olá, {contato}.');
      await database.close();
      await openDatabase();
      expect(await repository.loadMessageTemplate(), 'Olá, {contato}.');
    });

    test('registro ilegível usa o padrão sem sobrescrever', () async {
      final stored = {'schemaVersion': 9, 'text': 'x'};
      await database.settings.put(
        HiveSettingsRepository.messageTemplateKey,
        stored,
      );
      expect(
        await repository.loadMessageTemplate(),
        MessageTemplate.defaultText,
      );
      expect(
        database.settings.get(HiveSettingsRepository.messageTemplateKey),
        stored,
      );
    });
  });
}
