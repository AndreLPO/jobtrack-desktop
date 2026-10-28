import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/errors/persistence_exception.dart';
import '../models/application.dart';
import 'application_mapper.dart';
import 'application_repository.dart';

class HiveApplicationRepository implements ApplicationRepository {
  HiveApplicationRepository(this._box);

  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<ApplicationsSnapshot> getAll() async {
    try {
      final applications = <Application>[];
      final unreadableIds = <String>[];
      for (final key in _box.keys) {
        final application = _decode(key, _box.get(key));
        if (application == null) {
          unreadableIds.add(key.toString());
        } else {
          applications.add(application);
        }
      }
      return ApplicationsSnapshot(
        applications: applications,
        unreadableIds: unreadableIds,
      );
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.read, error, stackTrace);
    }
  }

  @override
  Future<Application?> getById(String id) async {
    final Map<dynamic, dynamic>? map;
    try {
      map = _box.get(id);
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.read, error, stackTrace);
    }
    if (map == null) return null;
    final application = _decode(id, map);
    if (application == null) {
      throw PersistenceException(
        PersistenceOperation.read,
        FormatException('Registro ilegível', id),
      );
    }
    return application;
  }

  @override
  Future<void> save(Application application) async {
    try {
      await _box.put(application.id, ApplicationMapper.toMap(application));
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.write, error, stackTrace);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.write, error, stackTrace);
    }
  }

  /// `null` se o registro for ilegível; ele não é alterado (D-48).
  Application? _decode(Object? key, Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    try {
      return ApplicationMapper.fromMap(map);
    } on FormatException catch (error) {
      debugPrint('Candidatura ilegível ($key): $error');
      return null;
    }
  }
}
