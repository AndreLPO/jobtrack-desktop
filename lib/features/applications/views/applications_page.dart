import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../core/widgets/under_construction.dart';
import '../viewmodels/applications_controller.dart';

class ApplicationsPage extends GetView<ApplicationsController> {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentRoute: AppRoutes.applications,
      title: 'Candidaturas',
      child: UnderConstruction(),
    );
  }
}
