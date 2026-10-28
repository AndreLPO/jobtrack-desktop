import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/errors/persistence_exception.dart';
import '../models/follow_up_settings.dart';
import 'follow_up_settings_mapper.dart';
import 'settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  static const followUpKey = 'followUp';

  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<FollowUpSettings> loadFollowUp() async {
    final Map<dynamic, dynamic>? map;
    try {
      map = _box.get(followUpKey);
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.read, error, stackTrace);
    }
    if (map == null) return const FollowUpSettings();
    try {
      return FollowUpSettingsMapper.fromMap(map);
    } on FormatException catch (error) {
      debugPrint('Configurações ilegíveis; usando padrões: $error');
      return const FollowUpSettings();
    }
  }

  @override
  Future<void> saveFollowUp(FollowUpSettings settings) async {
    try {
      await _box.put(followUpKey, FollowUpSettingsMapper.toMap(settings));
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.write, error, stackTrace);
    }
  }
}
