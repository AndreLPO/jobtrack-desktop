import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/core/formatting/date_format.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/core/time/week_range.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/applications/views/applications_page.dart';
import 'package:jobtrack_desktop/features/follow_ups/views/follow_ups_page.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  late FakeApplicationRepository repository;
  final today = LocalDate.fromDateTime(DateTime.now());

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put<ApplicationRepository>(repository);
    Get.put<SettingsRepository>(FakeSettingsRepository());
    await tester.pumpWidget(const JobTrackApp());
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakeApplicationRepository();
  });
  tearDown(Get.reset);

  testWidgets('CA-DSH-09: estado vazio com chamada para cadastrar', (
    tester,
  ) async {
    await pumpDashboard(tester);
    expect(find.text('Nenhuma candidatura cadastrada.'), findsOneWidget);
    expect(find.text('Cadastrar candidatura'), findsOneWidget);
  });

  group('com dados', () {
    setUp(() {
      repository.store
        ..['week'] = buildApplication(id: 'week', applicationDate: today)
        ..['due'] = buildApplication(
          id: 'due',
          applicationDate: today.addDays(-30),
        )
        ..['interview'] = buildApplication(
          id: 'interview',
          applicationDate: today.addDays(-30),
          statusChanges: [(ApplicationStatus.rejected, today.addDays(-20))],
        );
    });

    testWidgets('CA-DSH-08/10: indicadores com rótulo e escopo', (
      tester,
    ) async {
      await pumpDashboard(tester);
      final week = WeekRange.containing(today);

      expect(find.text('Candidaturas na semana'), findsOneWidget);
      expect(
        find.text('${formatDate(week.start)} a ${formatDate(week.end)}'),
        findsOneWidget,
      );
      expect(find.text('Total de candidaturas'), findsOneWidget);
      expect(find.text('Total, candidaturas ativas'), findsOneWidget);
      expect(find.text('Acompanhamentos pendentes'), findsOneWidget);
      expect(find.text('Sugerido encerrar'), findsOneWidget);
      expect(find.text('Resumo por status (total: 3)'), findsOneWidget);
    });

    testWidgets('D-57: semana abre a listagem filtrada pelo período', (
      tester,
    ) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('Candidaturas na semana'));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationsPage), findsOneWidget);
      expect(find.textContaining('Período:'), findsOneWidget);
      expect(find.text('1 de 3 candidaturas'), findsOneWidget);
    });

    testWidgets('D-57: linha de status abre a listagem filtrada', (
      tester,
    ) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('Reprovada'));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationsPage), findsOneWidget);
      expect(find.text('Status (1)'), findsOneWidget);
      expect(find.text('1 de 3 candidaturas'), findsOneWidget);
    });

    testWidgets('D-57: pendentes abre Acompanhamentos', (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.text('Acompanhamentos pendentes'));
      await tester.pumpAndSettle();
      expect(find.byType(FollowUpsPage), findsOneWidget);
    });
  });
}
