import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';
import 'theme/app_theme.dart';

class JobTrackApp extends StatelessWidget {
  const JobTrackApp({
    super.key,
    this.initialBinding,
    this.initialRoute = AppPages.initial,
  });

  static const locale = Locale('pt', 'BR');

  /// Registra os serviços compartilhados (banco e repositórios).
  final Bindings? initialBinding;

  /// Rota inicial; os testes podem abrir direto em outra página.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'JobTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialBinding: initialBinding,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      defaultTransition: Transition.noTransition,
    );
  }
}
