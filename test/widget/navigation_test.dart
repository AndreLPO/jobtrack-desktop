import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/applications_controller.dart';
import 'package:jobtrack_desktop/features/applications/views/applications_page.dart';
import 'package:jobtrack_desktop/features/dashboard/viewmodels/dashboard_controller.dart';
import 'package:jobtrack_desktop/features/dashboard/views/dashboard_page.dart';
import 'package:jobtrack_desktop/features/follow_ups/viewmodels/follow_ups_controller.dart';
import 'package:jobtrack_desktop/features/follow_ups/views/follow_ups_page.dart';
import 'package:jobtrack_desktop/features/settings/viewmodels/settings_controller.dart';
import 'package:jobtrack_desktop/features/settings/views/settings_page.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';

int _selectedRailIndex(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;

void main() {
  setUp(() {
    Get.put<ApplicationRepository>(FakeApplicationRepository());
    Get.put<SettingsRepository>(FakeSettingsRepository());
  });
  tearDown(Get.reset);

  testWidgets('abre no Dashboard com o próprio controller', (tester) async {
    await tester.pumpWidget(const JobTrackApp());
    await tester.pumpAndSettle();

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(_selectedRailIndex(tester), 0);
    expect(Get.isRegistered<DashboardController>(), isTrue);
  });

  testWidgets('navega entre as páginas e troca o controller da página', (
    tester,
  ) async {
    await tester.pumpWidget(const JobTrackApp());
    await tester.pumpAndSettle();

    final cases = [
      (
        'Candidaturas',
        ApplicationsPage,
        1,
        Get.isRegistered<ApplicationsController>,
      ),
      (
        'Acompanhamentos',
        FollowUpsPage,
        2,
        Get.isRegistered<FollowUpsController>,
      ),
      ('Configurações', SettingsPage, 3, Get.isRegistered<SettingsController>),
      ('Dashboard', DashboardPage, 0, Get.isRegistered<DashboardController>),
    ];

    for (final (label, pageType, index, isRegistered) in cases) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(pageType), findsOneWidget, reason: label);
      expect(_selectedRailIndex(tester), index, reason: label);
      expect(isRegistered(), isTrue, reason: label);
    }

    // Ao voltar ao Dashboard, o controller da página anterior foi
    // descartado.
    expect(Get.isRegistered<SettingsController>(), isFalse);
  });
}
