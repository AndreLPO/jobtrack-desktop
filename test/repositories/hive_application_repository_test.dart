import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/database/hive_database.dart';
import 'package:jobtrack_desktop/core/errors/persistence_exception.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_mapper.dart';
import 'package:jobtrack_desktop/features/applications/repositories/hive_application_repository.dart';

import '../support/application_samples.dart';

void main() {
  late Directory directory;
  late HiveDatabase database;
  late HiveApplicationRepository repository;

  Future<void> openDatabase() async {
    database = HiveDatabase();
    await database.open(directory: directory.path);
    repository = HiveApplicationRepository(database.applications);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('jobtrack_test_');
    await openDatabase();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('base vazia devolve lista vazia', () async {
    final snapshot = await repository.getAll();
    expect(snapshot.applications, isEmpty);
    expect(snapshot.unreadableIds, isEmpty);
    expect(await repository.getById('nao-existe'), isNull);
  });

  test('CA-P-03: dados continuam iguais após fechar e reabrir', () async {
    final full = fullApplication();
    final minimal = minimalApplication();
    await repository.save(full);
    await repository.save(minimal);

    await database.close();
    await openDatabase();

    final snapshot = await repository.getAll();
    expect(snapshot.applications, hasLength(2));
    expectSameApplication((await repository.getById(full.id))!, full);
    expectSameApplication((await repository.getById(minimal.id))!, minimal);
  });

  test('CA-P-04: salvar candidatura existente atualiza sem duplicar', () async {
    final original = minimalApplication();
    await repository.save(original);

    final updated = original.changeStatus(
      ApplicationStatus.interview,
      changeId: 'sc-2',
      now: DateTime(2026, 10, 20, 10),
    );
    await repository.save(updated);

    final snapshot = await repository.getAll();
    expect(snapshot.applications, hasLength(1));
    expectSameApplication(snapshot.applications.single, updated);
  });

  test(
    'CA-P-05: excluir remove histórico e contatos, também após reabrir',
    () async {
      final full = fullApplication();
      final other = minimalApplication();
      await repository.save(full);
      await repository.save(other);

      await repository.delete(full.id);
      await database.close();
      await openDatabase();

      expect(await repository.getById(full.id), isNull);
      final snapshot = await repository.getAll();
      expect(snapshot.applications.map((a) => a.id), [other.id]);
    },
  );

  test(
    'CA-P-06: registro ilegível não bloqueia os demais nem é alterado',
    () async {
      final good = minimalApplication();
      await repository.save(good);

      final broken = ApplicationMapper.toMap(minimalApplication(id: 'broken'))
        ..['status'] = 'hired';
      final newer = ApplicationMapper.toMap(minimalApplication(id: 'newer'))
        ..['schemaVersion'] = ApplicationMapper.schemaVersion + 1;
      await database.applications.put('broken', broken);
      await database.applications.put('newer', newer);

      final snapshot = await repository.getAll();
      expect(snapshot.applications.map((a) => a.id), [good.id]);
      expect(snapshot.unreadableIds.toSet(), {'broken', 'newer'});

      expect(database.applications.get('broken'), broken);
      expect(database.applications.get('newer')!['schemaVersion'], 2);

      await expectLater(
        repository.getById('broken'),
        throwsA(
          isA<PersistenceException>().having(
            (e) => e.operation,
            'operation',
            PersistenceOperation.read,
          ),
        ),
      );
    },
  );

  test('CA-P-07: falha de gravação vira PersistenceException(write)', () async {
    await database.close();

    await expectLater(
      repository.save(minimalApplication()),
      throwsA(
        isA<PersistenceException>().having(
          (e) => e.operation,
          'operation',
          PersistenceOperation.write,
        ),
      ),
    );
    await expectLater(
      repository.delete('x'),
      throwsA(isA<PersistenceException>()),
    );
  });
}
