import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../core/widgets/under_construction.dart';
import '../viewmodels/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      child: UnderConstruction(),
    );
  }
}
