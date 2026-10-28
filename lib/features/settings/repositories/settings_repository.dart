import '../models/applications_view_mode.dart';
import '../models/follow_up_settings.dart';

/// Acesso às configurações locais. As operações lançam
/// `PersistenceException` em caso de falha.
abstract interface class SettingsRepository {
  /// Devolve os padrões se não houver registro ou se ele for ilegível
  /// (RN-SET-04, D-48), sem gravar nada.
  Future<FollowUpSettings> loadFollowUp();

  Future<void> saveFollowUp(FollowUpSettings settings);

  /// Devolve o modelo padrão se não houver registro ou se ele for
  /// ilegível (D-48, D-50), sem gravar nada.
  Future<String> loadMessageTemplate();

  Future<void> saveMessageTemplate(String text);

  /// Último modo usado em Candidaturas (K-04); lista se não houver
  /// registro ou se ele for ilegível.
  Future<ApplicationsViewMode> loadApplicationsViewMode();

  Future<void> saveApplicationsViewMode(ApplicationsViewMode mode);
}
