import '../models/follow_up_settings.dart';

/// Acesso às configurações locais. As operações lançam
/// `PersistenceException` em caso de falha.
abstract interface class SettingsRepository {
  /// Devolve os padrões se não houver registro ou se ele for ilegível
  /// (RN-SET-04, D-48), sem gravar nada.
  Future<FollowUpSettings> loadFollowUp();

  Future<void> saveFollowUp(FollowUpSettings settings);
}
