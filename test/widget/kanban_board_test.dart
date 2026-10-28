import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/app/routes/app_routes.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/applications/views/application_details_page.dart';
import 'package:jobtrack_desktop/features/applications/views/kanban_board.dart';
import 'package:jobtrack_desktop/features/settings/models/applications_view_mode.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';

import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  late FakeApplicationRepository repository;
  late FakeSettingsRepository settings;

  Future<void> pumpBoard(WidgetTester tester, {double width = 2200}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Get.put<ApplicationRepository>(repository);
    Get.put<SettingsRepository>(settings);
    await tester.pumpWidget(
      const JobTrackApp(initialRoute: AppRoutes.applications),
    );
    await tester.pumpAndSettle();
  }

  Finder inBoard(Finder finder) =>
      find.descendant(of: find.byType(KanbanBoard), matching: finder);

  /// Arrasta com passos intermediários, como um mouse real.
  Future<void> dragTo(WidgetTester tester, Finder from, Finder to) async {
    final gesture = await tester.startGesture(tester.getCenter(from));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(12, 12));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> settleFeedback(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakeApplicationRepository();
    settings = FakeSettingsRepository()..viewMode = ApplicationsViewMode.board;
    repository.store
      ..['a'] = buildApplication(id: 'a', companyName: 'Acme')
      ..['g'] = buildApplication(
        id: 'g',
        companyName: 'Globex',
        initialStatus: ApplicationStatus.interview,
      );
  });
  tearDown(Get.reset);

  testWidgets('K-01/K-04: alterna Lista | Quadro e lembra a escolha', (
    tester,
  ) async {
    settings.viewMode = ApplicationsViewMode.list;
    await pumpBoard(tester);
    expect(find.byType(KanbanBoard), findsNothing);

    await tester.tap(find.text('Quadro'));
    await tester.pumpAndSettle();
    expect(find.byType(KanbanBoard), findsOneWidget);
    expect(settings.viewMode, ApplicationsViewMode.board);
  });

  testWidgets('CA-KB-01/09: colunas com contagem e coluna vazia', (
    tester,
  ) async {
    await pumpBoard(tester);
    for (final title in [
      'Aplicada',
      'Resposta recebida',
      'Entrevista',
      'Teste técnico',
      'Proposta recebida',
      'Encerradas',
    ]) {
      expect(inBoard(find.text(title)), findsOneWidget, reason: title);
    }
    expect(inBoard(find.text('Acme')), findsOneWidget);
    expect(inBoard(find.text('Globex')), findsOneWidget);
    expect(inBoard(find.text('Nenhuma candidatura')), findsNWidgets(4));
  });

  testWidgets('CA-KB-02 + K-03: arrastar muda o status e "Desfazer" volta', (
    tester,
  ) async {
    await pumpBoard(tester);
    await dragTo(
      tester,
      inBoard(find.text('Acme')),
      inBoard(find.text('Teste técnico')),
    );

    expect(repository.store['a']!.status, ApplicationStatus.technicalTest);
    expect(find.text('Acme movida para Teste técnico.'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    final history = repository.store['a']!.statusHistory;
    expect(repository.store['a']!.status, ApplicationStatus.applied);
    expect(history, hasLength(3), reason: 'desfazer registra a inversa');
    await settleFeedback(tester);
  });

  testWidgets('CA-KB-03: soltar na própria coluna não grava', (tester) async {
    await pumpBoard(tester);
    await dragTo(
      tester,
      inBoard(find.text('Acme')),
      inBoard(find.text('Aplicada')),
    );
    expect(repository.store['a']!.statusHistory, hasLength(1));
    expect(find.textContaining('movida para'), findsNothing);
  });

  testWidgets('CA-KB-04: falha mantém o cartão e avisa', (tester) async {
    await pumpBoard(tester);
    repository.failWrites = true;
    await dragTo(
      tester,
      inBoard(find.text('Acme')),
      inBoard(find.text('Entrevista')),
    );

    expect(repository.store['a']!.status, ApplicationStatus.applied);
    expect(find.textContaining('Não foi possível mover'), findsOneWidget);
    await settleFeedback(tester);
  });

  testWidgets('K-02: soltar em Encerradas pede qual status', (tester) async {
    await pumpBoard(tester);
    await dragTo(
      tester,
      inBoard(find.text('Acme')),
      inBoard(find.text('Encerradas')),
    );

    expect(find.text('Encerrar como'), findsOneWidget);
    await tester.tap(find.text('Desisti'));
    await tester.pumpAndSettle();
    expect(repository.store['a']!.status, ApplicationStatus.withdrawn);
    expect(inBoard(find.text('Desisti')), findsOneWidget, reason: 'badge');
    await settleFeedback(tester);
  });

  testWidgets('CA-KB-05: "Mover para…" no menu do cartão', (tester) async {
    await pumpBoard(tester);
    await tester.tap(find.byTooltip('Ações do cartão').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover para Proposta recebida'));
    await tester.pumpAndSettle();

    final moved = repository.store.values.firstWhere(
      (a) => a.status == ApplicationStatus.offerReceived,
    );
    expect(moved.statusHistory, hasLength(2));
    await settleFeedback(tester);
  });

  testWidgets('CA-KB-06: filtro de status limita colunas e cartões', (
    tester,
  ) async {
    await pumpBoard(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxMenuButton, 'Entrevista'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(inBoard(find.text('Aplicada')), findsNothing);
    expect(inBoard(find.text('Entrevista')), findsOneWidget);
    expect(inBoard(find.text('Globex')), findsOneWidget);
    expect(inBoard(find.text('Acme')), findsNothing);
  });

  testWidgets('F4: clicar no cartão abre os detalhes', (tester) async {
    await pumpBoard(tester);
    await tester.tap(inBoard(find.text('Globex')));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationDetailsPage), findsOneWidget);
  });

  testWidgets('CA-KB-08: em 960px o quadro rola na horizontal', (tester) async {
    await pumpBoard(tester, width: 960);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(KanbanBoard),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
