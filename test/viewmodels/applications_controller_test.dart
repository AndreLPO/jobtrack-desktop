import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/applications_controller.dart';

import '../support/application_samples.dart';
import '../support/fake_application_repository.dart';
import '../unit/applications/fixtures.dart';

void main() {
  late FakeApplicationRepository repository;
  late ApplicationsController controller;

  setUp(() {
    repository = FakeApplicationRepository();
    controller = ApplicationsController(repository);
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
      expect(controller.applications.map((a) => a.id), ['new', 'mid', 'old']);
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
}
