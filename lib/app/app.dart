import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';
import 'theme/app_theme.dart';

class JobTrackApp extends StatelessWidget {
  const JobTrackApp({super.key, this.initialBinding});

  /// Registra os serviços compartilhados (banco e repositórios).
  final Bindings? initialBinding;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'JobTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialBinding: initialBinding,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      defaultTransition: Transition.noTransition,
    );
  }
}
