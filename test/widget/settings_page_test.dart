import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/app/routes/app_routes.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';
import 'package:jobtrack_desktop/features/settings/views/settings_page.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository settings;

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put<ApplicationRepository>(FakeApplicationRepository());
    Get.put<SettingsRepository>(settings);
    await tester.pumpWidget(
      const JobTrackApp(initialRoute: AppRoutes.settings),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> settleFeedback(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  setUp(() => settings = FakeSettingsRepository());
  tearDown(Get.reset);

  testWidgets('CA-SET-01: mostra 7 dias e 3 tentativas com explicação', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      tester.widget<TextField>(field('Prazo (dias corridos)')).controller!.text,
      '7',
    );
    expect(
      tester.widget<TextField>(field('Limite de tentativas')).controller!.text,
      '3',
    );
    expect(find.textContaining('7 dias corridos'), findsOneWidget);
  });

  testWidgets('CA-SET-02: salvar grava e informa', (tester) async {
    await pumpSettings(tester);
    await tester.enterText(field('Prazo (dias corridos)'), '10');
    await tester.enterText(field('Limite de tentativas'), '2');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(settings.followUp.intervalDays, 10);
    expect(settings.followUp.maxAttempts, 2);
    expect(find.text('Configurações salvas.'), findsOneWidget);
    expect(find.textContaining('10 dias corridos'), findsOneWidget);
    await settleFeedback(tester);
  });

  testWidgets('CA-SET-03: valor inválido mostra erro no campo', (tester) async {
    await pumpSettings(tester);
    await tester.enterText(field('Prazo (dias corridos)'), '91');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um número de 1 a 90.'), findsOneWidget);
    expect(settings.followUp.intervalDays, 7);
    await settleFeedback(tester);
  });

  testWidgets('aceita só dígitos', (tester) async {
    await pumpSettings(tester);
    await tester.enterText(field('Prazo (dias corridos)'), '1a2');
    await tester.pump();
    expect(
      tester.widget<TextField>(field('Prazo (dias corridos)')).controller!.text,
      '12',
    );
  });

  testWidgets('D-59: sair com alterações não salvas pergunta', (tester) async {
    await pumpSettings(tester);
    await tester.enterText(field('Prazo (dias corridos)'), '15');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Dashboard'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
