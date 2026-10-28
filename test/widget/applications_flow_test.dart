import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/app/routes/app_routes.dart';
import 'package:jobtrack_desktop/core/formatting/date_format.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/application_form_controller.dart';
import 'package:jobtrack_desktop/features/applications/views/application_form_page.dart';
import 'package:jobtrack_desktop/features/applications/views/applications_page.dart';
import 'package:jobtrack_desktop/features/applications/views/status_badge.dart';

import '../support/application_samples.dart';
import '../support/fake_application_repository.dart';

void main() {
  late FakeApplicationRepository repository;

  Future<void> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put<ApplicationRepository>(repository);
    await tester.pumpWidget(
      const JobTrackApp(initialRoute: AppRoutes.applications),
    );
    await tester.pumpAndSettle();
  }

  /// Deixa o SnackBar sair para não sobrar timer ao fim do teste.
  Future<void> settleFeedback(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  setUp(() => repository = FakeApplicationRepository());
  tearDown(Get.reset);

  group('listagem', () {
    testWidgets('CA-E3-02: estado vazio com chamada para cadastrar', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.text('Nenhuma candidatura cadastrada.'), findsOneWidget);
      expect(find.text('Cadastrar primeira candidatura'), findsOneWidget);
    });

    testWidgets('mostra linhas com data dd/MM/yyyy e badge com texto', (
      tester,
    ) async {
      final application = fullApplication(id: 'a');
      repository.store['a'] = application;
      await pumpList(tester);

      expect(find.text('Acme'), findsOneWidget);
      expect(find.text('Dev Flutter Sênior'), findsOneWidget);
      expect(
        find.text(formatDate(application.details.applicationDate)),
        findsOneWidget,
      );
      expect(find.text('Feira de carreiras'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text('Entrevista'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('CA-E3-02: erro de leitura com "Tentar novamente"', (
      tester,
    ) async {
      repository.failReads = true;
      await pumpList(tester);
      expect(
        find.text('Não foi possível carregar as candidaturas.'),
        findsOneWidget,
      );

      repository.failReads = false;
      repository.store['a'] = minimalApplication(id: 'a');
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Globex'), findsOneWidget);
    });

    testWidgets('CA-E3-03: aviso de registros ilegíveis', (tester) async {
      repository.store['a'] = minimalApplication(id: 'a');
      repository.unreadableIds = ['x'];
      await pumpList(tester);
      expect(
        find.textContaining('1 registro não pôde ser lido'),
        findsOneWidget,
      );
      expect(find.text('Globex'), findsOneWidget);
    });
  });

  group('exclusão (CA-APP-16)', () {
    Future<void> openDeleteDialog(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Ações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
    }

    testWidgets('cancelar não remove nada', (tester) async {
      repository.store['a'] = minimalApplication(id: 'a');
      await pumpList(tester);
      await openDeleteDialog(tester);

      expect(find.text('Excluir candidatura?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.store, hasLength(1));
      expect(find.text('Globex'), findsOneWidget);
    });

    testWidgets('confirmar remove e informa', (tester) async {
      repository.store['a'] = minimalApplication(id: 'a');
      await pumpList(tester);
      await openDeleteDialog(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Excluir'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.store, isEmpty);
      expect(find.text('Candidatura excluída.'), findsOneWidget);
      expect(find.text('Nenhuma candidatura cadastrada.'), findsOneWidget);
      await settleFeedback(tester);
    });

    testWidgets('CA-APP-17: falha ao excluir mantém a linha e avisa', (
      tester,
    ) async {
      repository.store['a'] = minimalApplication(id: 'a');
      await pumpList(tester);
      repository.failWrites = true;
      await openDeleteDialog(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Excluir'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível excluir'), findsOneWidget);
      expect(find.text('Globex'), findsOneWidget);
      await settleFeedback(tester);
    });
  });

  group('formulário', () {
    testWidgets('CA-APP-01: salvar vazio mostra erro junto aos campos', (
      tester,
    ) async {
      await pumpList(tester);
      await tester.tap(find.text('Nova candidatura'));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationFormPage), findsOneWidget);
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Campo obrigatório.'), findsNWidgets(3));
      expect(repository.store, isEmpty);
      await settleFeedback(tester);
    });

    testWidgets('CA-APP-04: cadastrar volta para a lista com a nova linha', (
      tester,
    ) async {
      await pumpList(tester);
      await tester.tap(find.text('Nova candidatura'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Empresa *'), 'Initech');
      await tester.enterText(field('Título da vaga *'), 'Mobile Dev');
      await tester.tap(find.text('Canal *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LinkedIn').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(ApplicationsPage), findsOneWidget);
      expect(find.text('Initech'), findsOneWidget);
      expect(find.text('Candidatura salva.'), findsOneWidget);
      final saved = repository.store.values.single;
      expect(saved.status, ApplicationStatus.applied);
      await settleFeedback(tester);
    });

    testWidgets('CA-APP-11: aviso de duplicidade permite salvar mesmo assim', (
      tester,
    ) async {
      repository.store['a'] = minimalApplication(id: 'a');
      await pumpList(tester);
      await tester.tap(find.text('Nova candidatura'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Empresa *'), 'globex ');
      await tester.enterText(field('Título da vaga *'), 'QA');
      await tester.tap(find.text('Canal *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E-mail').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Possível duplicidade'), findsOneWidget);
      await tester.tap(find.text('Salvar mesmo assim'));
      await tester.pumpAndSettle();

      expect(repository.store, hasLength(2));
      expect(find.byType(ApplicationsPage), findsOneWidget);
      await settleFeedback(tester);
    });

    testWidgets('CA-E3-04: editar carrega valores e atualiza a linha', (
      tester,
    ) async {
      final original = fullApplication(id: 'a');
      repository.store['a'] = original;
      await pumpList(tester);

      await tester.tap(find.text('Acme'));
      await tester.pumpAndSettle();
      expect(find.text('Editar candidatura'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('Empresa *')).controller!.text,
        'Acme',
      );
      expect(find.text('Entrevista'), findsOneWidget, reason: 'status fixo');

      await tester.enterText(field('Empresa *'), 'Acme Brasil');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Acme Brasil'), findsOneWidget);
      final saved = repository.store['a']!;
      expect(saved.statusHistory, hasLength(original.statusHistory.length));
      expect(saved.interactions, hasLength(original.interactions.length));
      await settleFeedback(tester);
    });

    testWidgets('CA-E3-06: data digitada inválida mostra erro no campo', (
      tester,
    ) async {
      await pumpList(tester);
      await tester.tap(find.text('Nova candidatura'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Encerramento da vaga'), '31/02/2026');
      await tester.pump();
      expect(find.text('Data inválida. Use dd/mm/aaaa.'), findsOneWidget);
    });

    testWidgets('CA-E3-05: falha ao salvar avisa e mantém o formulário', (
      tester,
    ) async {
      await pumpList(tester);
      await tester.tap(find.text('Nova candidatura'));
      await tester.pumpAndSettle();
      repository.failWrites = true;

      await tester.enterText(field('Empresa *'), 'Initech');
      await tester.enterText(field('Título da vaga *'), 'Mobile Dev');
      await tester.tap(find.text('Canal *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gupy').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
      expect(find.byType(ApplicationFormPage), findsOneWidget);
      expect(find.text('Initech'), findsOneWidget);
      await settleFeedback(tester);
    });

    group('D-52: alterações não salvas', () {
      testWidgets('cancelar com alterações pergunta; continuar editando fica', (
        tester,
      ) async {
        await pumpList(tester);
        await tester.tap(find.text('Nova candidatura'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Empresa *'), 'Initech');

        await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Descartar alterações?'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Cancelar'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ApplicationFormPage), findsOneWidget);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        expect(find.byType(ApplicationsPage), findsOneWidget);
        expect(repository.store, isEmpty);
      });

      testWidgets('CA-E3-07: navegação lateral também pergunta e descarta o '
          'controller do formulário', (tester) async {
        await pumpList(tester);
        await tester.tap(find.text('Nova candidatura'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Empresa *'), 'Initech');

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Dashboard'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Descartar alterações?'), findsOneWidget);
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();

        expect(find.text('Em construção.'), findsOneWidget);
        expect(Get.isRegistered<ApplicationFormController>(), isFalse);
      });

      testWidgets('sem alterações, cancelar sai direto', (tester) async {
        await pumpList(tester);
        await tester.tap(find.text('Nova candidatura'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
        await tester.pumpAndSettle();
        expect(find.byType(ApplicationsPage), findsOneWidget);
      });
    });
  });
}
