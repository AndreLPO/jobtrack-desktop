import 'dart:async';

import 'package:jobtrack_desktop/core/errors/persistence_exception.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';

/// Repositório em memória com falhas programáveis.
class FakeApplicationRepository implements ApplicationRepository {
  FakeApplicationRepository([Iterable<Application> initial = const []]) {
    for (final application in initial) {
      store[application.id] = application;
    }
  }

  final store = <String, Application>{};
  List<String> unreadableIds = [];
  bool failReads = false;
  bool failWrites = false;

  /// Se definido, `save` espera este completer (para observar "salvando").
  Completer<void>? saveGate;

  @override
  Future<ApplicationsSnapshot> getAll() async {
    if (failReads) {
      throw const PersistenceException(PersistenceOperation.read, 'simulada');
    }
    return ApplicationsSnapshot(
      applications: store.values.toList(),
      unreadableIds: unreadableIds,
    );
  }

  @override
  Future<Application?> getById(String id) async {
    if (failReads) {
      throw const PersistenceException(PersistenceOperation.read, 'simulada');
    }
    return store[id];
  }

  @override
  Future<void> save(Application application) async {
    if (saveGate != null) await saveGate!.future;
    if (failWrites) {
      throw const PersistenceException(PersistenceOperation.write, 'simulada');
    }
    store[application.id] = application;
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) {
      throw const PersistenceException(PersistenceOperation.write, 'simulada');
    }
    store.remove(id);
  }
}
