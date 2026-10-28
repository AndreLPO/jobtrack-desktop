import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/errors/persistence_exception.dart';
import '../models/applications_view_mode.dart';
import '../models/follow_up_settings.dart';
import '../models/message_template.dart';
import 'applications_view_mode_mapper.dart';
import 'follow_up_settings_mapper.dart';
import 'message_template_mapper.dart';
import 'settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  static const followUpKey = 'followUp';
  static const messageTemplateKey = 'messageTemplate';
  static const applicationsViewKey = 'applicationsView';

  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<FollowUpSettings> loadFollowUp() async {
    final map = _get(followUpKey);
    if (map == null) return const FollowUpSettings();
    try {
      return FollowUpSettingsMapper.fromMap(map);
    } on FormatException catch (error) {
      debugPrint('Configurações ilegíveis; usando padrões: $error');
      return const FollowUpSettings();
    }
  }

  @override
  Future<void> saveFollowUp(FollowUpSettings settings) =>
      _put(followUpKey, FollowUpSettingsMapper.toMap(settings));

  @override
  Future<String> loadMessageTemplate() async {
    final map = _get(messageTemplateKey);
    if (map == null) return MessageTemplate.defaultText;
    try {
      return MessageTemplateMapper.fromMap(map);
    } on FormatException catch (error) {
      debugPrint('Modelo de mensagem ilegível; usando padrão: $error');
      return MessageTemplate.defaultText;
    }
  }

  @override
  Future<void> saveMessageTemplate(String text) =>
      _put(messageTemplateKey, MessageTemplateMapper.toMap(text));

  @override
  Future<ApplicationsViewMode> loadApplicationsViewMode() async {
    final map = _get(applicationsViewKey);
    if (map == null) return ApplicationsViewMode.list;
    try {
      return ApplicationsViewModeMapper.fromMap(map);
    } on FormatException catch (error) {
      debugPrint('Preferência de visualização ilegível; usando lista: $error');
      return ApplicationsViewMode.list;
    }
  }

  @override
  Future<void> saveApplicationsViewMode(ApplicationsViewMode mode) =>
      _put(applicationsViewKey, ApplicationsViewModeMapper.toMap(mode));

  Map<dynamic, dynamic>? _get(String key) {
    try {
      return _box.get(key);
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.read, error, stackTrace);
    }
  }

  Future<void> _put(String key, Map<String, Object?> value) async {
    try {
      await _box.put(key, value);
    } catch (error, stackTrace) {
      throw PersistenceException(PersistenceOperation.write, error, stackTrace);
    }
  }
}
