import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/applications/models/application_query.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/applications_controller.dart';
import 'package:jobtrack_desktop/features/settings/models/applications_view_mode.dart';

import '../support/application_samples.dart';
import '../support/fake_application_repository.dart';
import '../support/fake_settings_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  late FakeApplicationRepository repository;
  late FakeSettingsRepository settings;
  late ApplicationsController controller;

  setUp(() {
    repository = FakeApplicationRepository();
    settings = FakeSettingsRepository();
    controller = ApplicationsController(
      repository,
      settings,
      clock: () => DateTime(2026, 10, 28, 12),
    );
  });

  test('começa carregando', () {
    expect(controller.status.value, ListStatus.loading);
  });

  test(
    'CA-E3-01: carrega ordenado pela data da candidatura (decrescente)',
    () async {
      final older = buildApplication(id: 'old', applicationDate: dateOf(10, 1));
      final newer = buildApplication(
        id: 'new',
        applicationDate: dateOf(10, 20),
      );
      final middle = buildApplication(
        id: 'mid',
        applicationDate: dateOf(10, 5),
      );
      repository.store.addAll({'old': older, 'new': newer, 'mid': middle});

      await controller.load();

      expect(controller.status.value, ListStatus.ready);
      expect(controller.visible.map((a) => a.id), ['new', 'mid', 'old']);
    },
  );

  test('CA-E3-02: base vazia fica pronta e sem itens', () async {
    await controller.load();
    expect(controller.status.value, ListStatus.ready);
    expect(controller.applications, isEmpty);
  });

  test(
    'CA-E3-02: falha de leitura vira erro; tentar de novo recupera',
    () async {
      repository.failReads = true;
      await controller.load();
      expect(controller.status.value, ListStatus.error);

      repository.failReads = false;
      repository.store['a'] = minimalApplication(id: 'a');
      await controller.load();
      expect(controller.status.value, ListStatus.ready);
      expect(controller.applications, hasLength(1));
    },
  );

  test(
    'CA-E3-03: informa registros ilegíveis sem esconder os demais',
    () async {
      repository.store['a'] = minimalApplication(id: 'a');
      repository.unreadableIds = ['x', 'y'];
      await controller.load();
      expect(controller.applications, hasLength(1));
      expect(controller.unreadableCount.value, 2);
    },
  );

  test('falha ao ler configurações também vira erro', () async {
    settings.failReads = true;
    await controller.load();
    expect(controller.status.value, ListStatus.error);
  });

  test('filtro e ordenação mudam só a lista visível', () async {
    repository.store['a'] = buildApplication(
      id: 'a',
      companyName: 'São Paulo Tech',
      applicationDate: dateOf(10, 1),
    );
    repository.store['b'] = buildApplication(
      id: 'b',
      companyName: 'Acme',
      applicationDate: dateOf(10, 20),
    );
    await controller.load();

    controller.setFilter(const ApplicationFilter(text: 'sao'));
    expect(controller.visible.map((a) => a.id), ['a']);
    expect(controller.applications, hasLength(2));

    controller.clearFilters();
    expect(controller.filter.value.isEmpty, isTrue);
    expect(controller.visible, hasLength(2));
  });

  test('filtro inicial vindo do Dashboard (D-57)', () async {
    repository.store['a'] = buildApplication(
      id: 'a',
      applicationDate: dateOf(10, 1),
    );
    repository.store['b'] = buildApplication(
      id: 'b',
      applicationDate: dateOf(10, 27),
    );
    final filtered = ApplicationsController(
      repository,
      settings,
      initialFilter: ApplicationFilter(from: dateOf(10, 26), to: dateOf(11, 1)),
    );
    await filtered.load();
    expect(filtered.visible.map((a) => a.id), ['b']);
  });

  test('excluir remove da lista após gravar', () async {
    repository.store['a'] = minimalApplication(id: 'a');
    repository.store['b'] = minimalApplication(id: 'b');
    await controller.load();

    expect(await controller.delete('a'), isTrue);
    expect(controller.applications.map((a) => a.id), ['b']);
    expect(repository.store.containsKey('a'), isFalse);
  });

  test('CA-APP-17: falha ao excluir mantém o item na lista', () async {
    repository.store['a'] = minimalApplication(id: 'a');
    await controller.load();
    repository.failWrites = true;

    expect(await controller.delete('a'), isFalse);
    expect(controller.applications, hasLength(1));
  });

  group('quadro (Etapa 10)', () {
    setUp(() {
      repository.store['a'] = buildApplication(id: 'a');
    });

    test('K-04: carrega e grava o modo de visualização', () async {
      settings.viewMode = ApplicationsViewMode.board;
      await controller.load();
      expect(controller.viewMode.value, ApplicationsViewMode.board);

      await controller.setViewMode(ApplicationsViewMode.list);
      expect(settings.viewMode, ApplicationsViewMode.list);
    });

    test('falha ao gravar o modo não impede a troca', () async {
      await controller.load();
      settings.failWrites = true;
      await controller.setViewMode(ApplicationsViewMode.board);
      expect(controller.viewMode.value, ApplicationsViewMode.board);
    });

    test('CA-KB-02: mover grava o StatusChange e atualiza a lista', () async {
      await controller.load();
      expect(
        await controller.moveTo('a', ApplicationStatus.interview),
        MoveResult.moved,
      );
      final saved = repository.store['a']!;
      expect(saved.status, ApplicationStatus.interview);
      expect(
        saved.statusHistory.last.previousStatus,
        ApplicationStatus.applied,
      );
      expect(
        controller.applications.single.status,
        ApplicationStatus.interview,
      );
    });

    test('CA-KB-03: mesmo status não grava', () async {
      await controller.load();
      expect(
        await controller.moveTo('a', ApplicationStatus.applied),
        MoveResult.unchanged,
      );
      expect(repository.store['a']!.statusHistory, hasLength(1));
    });

    test('CA-KB-04: falha mantém o status', () async {
      await controller.load();
      repository.failWrites = true;
      expect(
        await controller.moveTo('a', ApplicationStatus.interview),
        MoveResult.failed,
      );
      expect(controller.applications.single.status, ApplicationStatus.applied);
    });

    test('K-03: desfazer registra a mudança inversa', () async {
      await controller.load();
      await controller.moveTo('a', ApplicationStatus.rejected);
      expect(
        await controller.moveTo('a', ApplicationStatus.applied),
        MoveResult.moved,
      );
      final history = repository.store['a']!.statusHistory;
      expect(history.map((c) => c.newStatus), [
        ApplicationStatus.applied,
        ApplicationStatus.rejected,
        ApplicationStatus.applied,
      ]);
    });
  });
}
