import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../../../core/ids.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../settings/models/applications_view_mode.dart';
import '../../settings/models/follow_up_settings.dart';
import '../../settings/repositories/settings_repository.dart';
import '../models/application.dart';
import '../models/application_query.dart';
import '../models/application_status.dart';
import '../models/follow_up_policy.dart';
import '../repositories/application_repository.dart';

enum ListStatus { loading, ready, error }

/// Resultado de mover uma candidatura no quadro (RN-KB-02/03).
enum MoveResult { moved, unchanged, failed }

/// ViewModel da página "Candidaturas".
class ApplicationsController extends GetxController {
  ApplicationsController(
    this._repository,
    this._settingsRepository, {
    ApplicationFilter initialFilter = const ApplicationFilter(),
    this._clock = DateTime.now,
    this._newId = generateId,
  }) : filter = initialFilter.obs;

  final ApplicationRepository _repository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;
  final IdGenerator _newId;

  final status = ListStatus.loading.obs;

  /// Todas as candidaturas legíveis, sem filtro.
  final applications = <Application>[].obs;

  /// Registros que não puderam ser lidos (D-48).
  final unreadableCount = 0.obs;

  final Rx<ApplicationFilter> filter;
  final sort = ApplicationSort.applicationDate.obs;
  final settings = const FollowUpSettings().obs;

  /// Lista ou quadro (K-01), lembrado entre sessões (K-04).
  final viewMode = ApplicationsViewMode.list.obs;

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
      viewMode.value = await _settingsRepository.loadApplicationsViewMode();
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

  /// Troca o modo na hora; gravar a preferência é melhor esforço, porque
  /// uma falha aqui não afeta os registros.
  Future<void> setViewMode(ApplicationsViewMode mode) async {
    viewMode.value = mode;
    try {
      await _settingsRepository.saveApplicationsViewMode(mode);
    } on PersistenceException {
      // A preferência volta ao padrão na próxima sessão; nada a perder.
    }
  }

  /// Muda o status pelo quadro, equivalente a "Alterar status" (RN-KB-02).
  /// A lista só é atualizada depois de gravar (RN-KB-03). "Desfazer" usa
  /// este mesmo método com o status anterior (K-03).
  Future<MoveResult> moveTo(String id, ApplicationStatus status) async {
    final current = applications.firstWhereOrNull((a) => a.id == id);
    if (current == null) return MoveResult.failed;
    if (current.status == status) return MoveResult.unchanged;
    final updated = current.changeStatus(
      status,
      changeId: _newId(),
      now: _clock(),
    );
    try {
      await _repository.save(updated);
    } on PersistenceException {
      return MoveResult.failed;
    }
    final index = applications.indexWhere((a) => a.id == id);
    if (index >= 0) applications[index] = updated;
    return MoveResult.moved;
  }

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
