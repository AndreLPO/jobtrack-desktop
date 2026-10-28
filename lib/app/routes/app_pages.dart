import 'package:get/get.dart';

import '../../features/applications/viewmodels/application_form_controller.dart';
import '../../features/applications/viewmodels/applications_controller.dart';
import '../../features/applications/views/application_form_page.dart';
import '../../features/applications/views/applications_page.dart';
import '../../features/dashboard/viewmodels/dashboard_controller.dart';
import '../../features/dashboard/views/dashboard_page.dart';
import '../../features/follow_ups/viewmodels/follow_ups_controller.dart';
import '../../features/follow_ups/views/follow_ups_page.dart';
import '../../features/settings/viewmodels/settings_controller.dart';
import '../../features/settings/views/settings_page.dart';
import 'app_routes.dart';

/// Cada página registra o próprio controller na rota (um controller
/// por página, PROJECT.md §5.3). Ao sair da rota, o controller é
/// descartado.
abstract final class AppPages {
  static const initial = AppRoutes.dashboard;

  static final pages = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: BindingsBuilder.put(() => DashboardController()),
    ),
    GetPage(
      name: AppRoutes.applications,
      page: () => const ApplicationsPage(),
      binding: BindingsBuilder.put(() => ApplicationsController(Get.find())),
    ),
    GetPage(
      name: AppRoutes.newApplication,
      page: () => const ApplicationFormPage(),
      binding: BindingsBuilder.put(() => ApplicationFormController(Get.find())),
    ),
    GetPage(
      name: AppRoutes.editApplication,
      page: () => const ApplicationFormPage(),
      binding: BindingsBuilder.put(
        () => ApplicationFormController(
          Get.find(),
          applicationId: Get.parameters['id'],
        ),
      ),
    ),
    GetPage(
      name: AppRoutes.followUps,
      page: () => const FollowUpsPage(),
      binding: BindingsBuilder.put(() => FollowUpsController()),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: BindingsBuilder.put(() => SettingsController()),
    ),
  ];
}
