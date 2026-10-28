import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../models/application.dart';
import '../repositories/application_repository.dart';

enum ListStatus { loading, ready, error }

/// ViewModel da página "Candidaturas".
class ApplicationsController extends GetxController {
  ApplicationsController(this._repository);

  final ApplicationRepository _repository;

  final status = ListStatus.loading.obs;

  /// Ordenadas por data da candidatura, da mais recente para a mais
  /// antiga (busca e ordenação configurável: Etapa 5).
  final applications = <Application>[].obs;

  /// Registros que não puderam ser lidos (D-48).
  final unreadableCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = ListStatus.loading;
    try {
      final snapshot = await _repository.getAll();
      final sorted = [...snapshot.applications]..sort(_byNewest);
      applications.assignAll(sorted);
      unreadableCount.value = snapshot.unreadableIds.length;
      status.value = ListStatus.ready;
    } on PersistenceException {
      status.value = ListStatus.error;
    }
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

  static int _byNewest(Application a, Application b) {
    final byDate = b.details.applicationDate.compareTo(
      a.details.applicationDate,
    );
    return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
  }
}
