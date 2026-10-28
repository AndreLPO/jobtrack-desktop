import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/app/routes/app_routes.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/applications/views/application_details_page.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  late FakeApplicationRepository repository;
  final today = LocalDate.fromDateTime(DateTime.now());
  LocalDate ago(int days) => today.addDays(-days);

  Future<void> pumpFollowUps(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put<ApplicationRepository>(repository);
    Get.put<SettingsRepository>(FakeSettingsRepository());
    await tester.pumpWidget(
      const JobTrackApp(initialRoute: AppRoutes.followUps),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleFeedback(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  setUp(() => repository = FakeApplicationRepository());
  tearDown(Get.reset);

  testWidgets('estado vazio', (tester) async {
    await pumpFollowUps(tester);
    expect(find.text('Nenhum acompanhamento pendente.'), findsOneWidget);
    expect(find.textContaining('Prazo: 7 dias corridos'), findsOneWidget);
  });

  testWidgets('RF-06: mostra os dados de cada item vencido', (tester) async {
    repository.store['a'] = buildApplication(
      id: 'a',
      companyName: 'Acme',
      jobTitle: 'Dev Flutter',
      applicationDate: ago(9),
    );
    await pumpFollowUps(tester);

    expect(find.text('Vencidos (1)'), findsOneWidget);
    expect(find.text('Acme — Dev Flutter'), findsOneWidget);
    expect(find.textContaining('9 dias desde a candidatura'), findsOneWidget);
    expect(find.textContaining('Tentativas: 0/3'), findsOneWidget);
    expect(find.text('Aplicada'), findsOneWidget);
  });

  testWidgets('registrar contato tira o item da lista', (tester) async {
    repository.store['a'] = buildApplication(id: 'a', applicationDate: ago(9));
    await pumpFollowUps(tester);

    await tester.tap(find.text('Registrar contato'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Tipo *')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acompanhamento enviado').last);
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Registrar')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum acompanhamento pendente.'), findsOneWidget);
    expect(
      repository.store['a']!.interactions.single.type,
      InteractionType.followUpSent,
    );
    await settleFeedback(tester);
  });

  testWidgets('sugerido encerrar → encerrar sem resposta com confirmação', (
    tester,
  ) async {
    repository.store['a'] = buildApplication(
      id: 'a',
      applicationDate: ago(40),
      interactions: [
        contact(ago(30), InteractionType.followUpSent),
        contact(ago(20), InteractionType.followUpSent),
        contact(ago(10), InteractionType.followUpSent),
      ],
    );
    await pumpFollowUps(tester);
    expect(find.text('Sugerido encerrar (1)'), findsOneWidget);

    await tester.tap(find.text('Encerrar sem resposta'));
    await tester.pumpAndSettle();
    expect(find.text('Encerrar sem resposta?'), findsOneWidget);
    await tester.tap(inDialog(find.text('Encerrar')));
    await tester.pumpAndSettle();

    expect(
      repository.store['a']!.status,
      ApplicationStatus.closedWithoutResponse,
    );
    expect(find.text('Nenhum acompanhamento pendente.'), findsOneWidget);
    await settleFeedback(tester);
  });

  testWidgets('adiar pede data e recusa data passada', (tester) async {
    repository.store['a'] = buildApplication(id: 'a', applicationDate: ago(9));
    await pumpFollowUps(tester);

    await tester.tap(find.byTooltip('Mais ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adiar'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Adiar')));
    await tester.pumpAndSettle();
    expect(find.text('Campo obrigatório.'), findsOneWidget);

    await tester.enterText(
      inDialog(find.byType(TextField)),
      '${ago(1).day.toString().padLeft(2, '0')}/'
      '${ago(1).month.toString().padLeft(2, '0')}/${ago(1).year}',
    );
    await tester.tap(inDialog(find.text('Adiar')));
    await tester.pumpAndSettle();
    expect(find.text('Escolha hoje ou uma data futura.'), findsOneWidget);
  });

  testWidgets('clicar no item abre os detalhes', (tester) async {
    repository.store['a'] = buildApplication(
      id: 'a',
      companyName: 'Acme',
      applicationDate: ago(9),
    );
    await pumpFollowUps(tester);
    await tester.tap(find.textContaining('Acme —'));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationDetailsPage), findsOneWidget);
  });
}
