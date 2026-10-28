import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../../../core/time/clock.dart';
import '../../applications/models/dashboard_metrics.dart';
import '../../applications/repositories/application_repository.dart';
import '../../settings/models/follow_up_settings.dart';
import '../../settings/repositories/settings_repository.dart';

enum DashboardStatus { loading, ready, error }

/// ViewModel da página "Dashboard". Recalcula ao abrir a página, então
/// reflete alterações feitas nas outras páginas (F2).
class DashboardController extends GetxController {
  DashboardController(
    this._repository,
    this._settingsRepository, {
    this._clock = DateTime.now,
  });

  final ApplicationRepository _repository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;

  final status = DashboardStatus.loading.obs;
  final metrics = Rxn<DashboardMetrics>();
  final settings = const FollowUpSettings().obs;
  final unreadableCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = DashboardStatus.loading;
    try {
      final snapshot = await _repository.getAll();
      settings.value = await _settingsRepository.loadFollowUp();
      metrics.value = DashboardMetrics.compute(
        snapshot.applications,
        settings.value,
        _clock.today(),
      );
      unreadableCount.value = snapshot.unreadableIds.length;
      status.value = DashboardStatus.ready;
    } on PersistenceException {
      status.value = DashboardStatus.error;
    }
  }
}
