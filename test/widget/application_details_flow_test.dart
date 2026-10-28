import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/app/routes/app_routes.dart';
import 'package:jobtrack_desktop/core/formatting/date_format.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';
import 'package:jobtrack_desktop/features/applications/views/application_details_page.dart';
import 'package:jobtrack_desktop/features/applications/views/applications_page.dart';
import 'package:jobtrack_desktop/features/applications/views/status_badge.dart';

import '../support/application_samples.dart';
import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';

void main() {
  late FakeApplicationRepository repository;

  Future<void> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put<ApplicationRepository>(repository);
    Get.put<SettingsRepository>(FakeSettingsRepository());
    await tester.pumpWidget(
      const JobTrackApp(initialRoute: AppRoutes.applications),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(WidgetTester tester, String company) async {
    await tester.tap(find.text(company));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationDetailsPage), findsOneWidget);
  }

  Future<void> settleFeedback(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  Finder badgeText(String text) =>
      find.descendant(of: find.byType(StatusBadge), matching: find.text(text));

  setUp(() => repository = FakeApplicationRepository());
  tearDown(Get.reset);

  testWidgets('CA-E4-01/02: abre os detalhes com seções e volta à lista', (
    tester,
  ) async {
    repository.store['a'] = fullApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Acme');

    expect(find.text('Dev Flutter Sênior'), findsOneWidget);
    expect(badgeText('Entrevista'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Greenhouse'), findsOneWidget);
    expect(find.text('Feira de carreiras'), findsOneWidget);
    expect(find.text('Contatos'), findsOneWidget);
    expect(find.text('Histórico de status'), findsOneWidget);
    expect(find.text('Resposta recebida → Entrevista'), findsOneWidget);
    expect(find.text('Cadastrada como Aplicada'), findsOneWidget);
    expect(find.text('Mostrar descrição da vaga'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationsPage), findsOneWidget);
  });

  testWidgets('CA-E4-02: campos vazios não aparecem', (tester) async {
    repository.store['a'] = minimalApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Globex');

    expect(find.text('Vaga'), findsNothing, reason: 'sem dados opcionais');
    expect(find.text('Nenhum contato registrado.'), findsOneWidget);
    expect(find.text('Ainda não'), findsOneWidget);
  });

  testWidgets('CA-E4-03: alterar status atualiza badge e histórico', (
    tester,
  ) async {
    repository.store['a'] = minimalApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Globex');

    await tester.tap(find.text('Alterar status'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Aplicada')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teste técnico').last);
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Alterar')));
    await tester.pumpAndSettle();

    expect(badgeText('Teste técnico'), findsOneWidget);
    expect(find.text('Aplicada → Teste técnico'), findsOneWidget);
    expect(repository.store['a']!.status, ApplicationStatus.technicalTest);
    await settleFeedback(tester);

    // Voltar recarrega a listagem com o novo status.
    Get.back();
    await tester.pumpAndSettle();
    expect(badgeText('Teste técnico'), findsOneWidget);
  });

  testWidgets('CA-E4-04: registrar contato atualiza resumo e lista', (
    tester,
  ) async {
    repository.store['a'] = minimalApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Globex');

    await tester.tap(find.text('Registrar contato'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Tipo *')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensagem recebida').last);
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Houve resposta da empresa')));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Registrar')));
    await tester.pumpAndSettle();

    final today = formatDate(LocalDate.fromDateTime(DateTime.now()));
    expect(find.text('$today · Mensagem recebida'), findsOneWidget);
    expect(find.text('Houve resposta'), findsOneWidget);
    expect(find.text('Sim'), findsOneWidget);
    expect(repository.store['a']!.interactions, hasLength(1));
    await settleFeedback(tester);
  });

  testWidgets('CA-E4-04: tipo obrigatório e data futura recusada', (
    tester,
  ) async {
    repository.store['a'] = minimalApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Globex');

    await tester.tap(find.text('Registrar contato'));
    await tester.pumpAndSettle();
    final tomorrow = LocalDate.fromDateTime(DateTime.now()).addDays(1);
    await tester.enterText(
      inDialog(find.widgetWithText(TextField, 'Data do contato *')),
      formatDate(tomorrow),
    );
    await tester.tap(inDialog(find.text('Registrar')));
    await tester.pumpAndSettle();

    expect(find.text('A data não pode ser futura.'), findsOneWidget);
    expect(find.text('Campo obrigatório.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repository.store['a']!.interactions, isEmpty);
  });

  testWidgets('D-55: excluir contato com confirmação', (tester) async {
    repository.store['a'] = fullApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Acme');

    await tester.tap(find.byTooltip('Excluir contato').first);
    await tester.pumpAndSettle();
    expect(find.text('Excluir contato?'), findsOneWidget);
    await tester.tap(inDialog(find.text('Excluir')));
    await tester.pumpAndSettle();

    expect(repository.store['a']!.interactions, hasLength(1));
    expect(find.byTooltip('Excluir contato'), findsOneWidget);
    await settleFeedback(tester);
  });

  testWidgets('CA-E4-05: excluir pelos detalhes volta à lista', (tester) async {
    repository.store['a'] = minimalApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Globex');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(inDialog(find.text('Excluir')));
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationsPage), findsOneWidget);
    expect(find.text('Candidatura excluída.'), findsOneWidget);
    expect(find.text('Nenhuma candidatura cadastrada.'), findsOneWidget);
    await settleFeedback(tester);
  });

  testWidgets('CA-E4-07: editar pelos detalhes volta aos detalhes '
      'atualizados', (tester) async {
    repository.store['a'] = minimalApplication(id: 'a');
    await pumpList(tester);
    await openDetails(tester, 'Globex');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Empresa *'),
      'Globex Corp',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationDetailsPage), findsOneWidget);
    expect(find.text('Globex Corp'), findsOneWidget);
    await settleFeedback(tester);
  });
}
