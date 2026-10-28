import 'package:jobtrack_desktop/core/errors/persistence_exception.dart';
import 'package:jobtrack_desktop/features/settings/models/applications_view_mode.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';
import 'package:jobtrack_desktop/features/settings/models/message_template.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';

/// Configurações em memória com falhas programáveis.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.followUp = const FollowUpSettings()]);

  FollowUpSettings followUp;
  String messageTemplate = MessageTemplate.defaultText;
  ApplicationsViewMode viewMode = ApplicationsViewMode.list;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<FollowUpSettings> loadFollowUp() async {
    if (failReads) {
      throw const PersistenceException(PersistenceOperation.read, 'simulada');
    }
    return followUp;
  }

  @override
  Future<void> saveFollowUp(FollowUpSettings settings) async {
    if (failWrites) {
      throw const PersistenceException(PersistenceOperation.write, 'simulada');
    }
    followUp = settings;
  }

  @override
  Future<String> loadMessageTemplate() async {
    if (failReads) {
      throw const PersistenceException(PersistenceOperation.read, 'simulada');
    }
    return messageTemplate;
  }

  @override
  Future<void> saveMessageTemplate(String text) async {
    if (failWrites) {
      throw const PersistenceException(PersistenceOperation.write, 'simulada');
    }
    messageTemplate = text;
  }

  @override
  Future<ApplicationsViewMode> loadApplicationsViewMode() async {
    if (failReads) {
      throw const PersistenceException(PersistenceOperation.read, 'simulada');
    }
    return viewMode;
  }

  @override
  Future<void> saveApplicationsViewMode(ApplicationsViewMode mode) async {
    if (failWrites) {
      throw const PersistenceException(PersistenceOperation.write, 'simulada');
    }
    viewMode = mode;
  }
}
