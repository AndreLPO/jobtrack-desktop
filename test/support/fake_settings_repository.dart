import 'package:jobtrack_desktop/core/errors/persistence_exception.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';

/// Configurações em memória com falhas programáveis.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.followUp = const FollowUpSettings()]);

  FollowUpSettings followUp;
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
}
