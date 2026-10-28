import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../core/widgets/under_construction.dart';
import '../viewmodels/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentRoute: AppRoutes.settings,
      title: 'Configurações',
      child: UnderConstruction(),
    );
  }
}
