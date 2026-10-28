import 'package:get/get.dart';

import '../../core/database/hive_database.dart';
import '../../features/applications/repositories/application_repository.dart';
import '../../features/applications/repositories/hive_application_repository.dart';
import '../../features/settings/repositories/hive_settings_repository.dart';
import '../../features/settings/repositories/settings_repository.dart';

/// Serviços compartilhados entre páginas (PROJECT.md §5.3). Não é um
/// controller global: só registra o banco e os repositórios.
class InitialBinding extends Bindings {
  InitialBinding(this._database);

  final HiveDatabase _database;

  @override
  void dependencies() {
    Get.put<HiveDatabase>(_database, permanent: true);
    Get.put<ApplicationRepository>(
      HiveApplicationRepository(_database.applications),
      permanent: true,
    );
    Get.put<SettingsRepository>(
      HiveSettingsRepository(_database.settings),
      permanent: true,
    );
  }
}
