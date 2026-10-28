import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';
import 'theme/app_theme.dart';

class JobTrackApp extends StatelessWidget {
  const JobTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'JobTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      defaultTransition: Transition.noTransition,
    );
  }
}
