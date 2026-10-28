import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../settings/models/follow_up_settings.dart';
import '../../settings/repositories/settings_repository.dart';
import '../models/application.dart';
import '../models/application_query.dart';
import '../models/follow_up_policy.dart';
import '../repositories/application_repository.dart';

enum ListStatus { loading, ready, error }

/// ViewModel da página "Candidaturas".
class ApplicationsController extends GetxController {
  ApplicationsController(
    this._repository,
    this._settingsRepository, {
    ApplicationFilter initialFilter = const ApplicationFilter(),
    this._clock = DateTime.now,
  }) : filter = initialFilter.obs;

  final ApplicationRepository _repository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;

  final status = ListStatus.loading.obs;

  /// Todas as candidaturas legíveis, sem filtro.
  final applications = <Application>[].obs;

  /// Registros que não puderam ser lidos (D-48).
  final unreadableCount = 0.obs;

  final Rx<ApplicationFilter> filter;
  final sort = ApplicationSort.applicationDate.obs;
  final settings = const FollowUpSettings().obs;

  LocalDate get today => _clock.today();

  /// Candidaturas após busca, filtros e ordenação (RF-04).
  List<Application> get visible => queryApplications(
    applications,
    filter: filter.value,
    sort: sort.value,
    settings: settings.value,
    today: today,
  );

  FollowUpState followUpOf(Application application) =>
      FollowUpPolicy.evaluate(application, settings.value, today);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = ListStatus.loading;
    try {
      final snapshot = await _repository.getAll();
      settings.value = await _settingsRepository.loadFollowUp();
      applications.assignAll(snapshot.applications);
      unreadableCount.value = snapshot.unreadableIds.length;
      status.value = ListStatus.ready;
    } on PersistenceException {
      status.value = ListStatus.error;
    }
  }

  void setFilter(ApplicationFilter value) => filter.value = value;

  void clearFilters() => filter.value = const ApplicationFilter();

  void setSort(ApplicationSort value) => sort.value = value;

  /// Remove da lista só depois de a exclusão ser gravada (RN-APP-13).
  /// Devolve `false` se a gravação falhar.
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
    } on PersistenceException {
      return false;
    }
    applications.removeWhere((a) => a.id == id);
    return true;
  }
}
