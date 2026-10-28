import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../core/widgets/under_construction.dart';
import '../viewmodels/follow_ups_controller.dart';

class FollowUpsPage extends GetView<FollowUpsController> {
  const FollowUpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      currentRoute: AppRoutes.followUps,
      title: 'Acompanhamentos',
      child: UnderConstruction(),
    );
  }
}
