import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_channel.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/application_validation.dart';
import 'package:jobtrack_desktop/features/applications/viewmodels/application_form_controller.dart';

import '../support/application_samples.dart';
import '../support/fake_application_repository.dart';

void main() {
  final now = DateTime(2026, 10, 28, 14);
  final today = LocalDate(2026, 10, 28);
  late FakeApplicationRepository repository;
  var ids = 0;

  ApplicationFormController build({String? applicationId}) =>
      ApplicationFormController(
        repository,
        applicationId: applicationId,
        clock: () => now,
        newId: () => 'gen-${ids++}',
      );

  void fillRequired(ApplicationFormController c) {
    c.edit(
      (d) => d.copyWith(
        companyName: 'Acme',
        jobTitle: 'Dev Flutter',
        channel: () => ApplicationChannel.linkedIn,
      ),
    );
  }

  setUp(() {
    repository = FakeApplicationRepository();
    ids = 0;
  });

  group('cadastro', () {
    test('começa com data de hoje e status Aplicada, sem alterações', () async {
      final c = build();
      await c.load();
      expect(c.loadStatus.value, FormLoadStatus.ready);
      expect(c.draft.value.applicationDate, today);
      expect(c.draft.value.status, ApplicationStatus.applied);
      expect(c.isDirty.value, isFalse);
      expect(c.isEditing, isFalse);
    });

    test('CA-APP-01: obrigatórios vazios impedem salvar', () async {
      final c = build();
      await c.load();
      c.edit((d) => d.copyWith(applicationDate: () => null));

      expect(await c.save(), SaveResult.invalid);
      expect(c.errorFor(ApplicationField.companyName), ValidationCode.required);
      expect(c.errorFor(ApplicationField.jobTitle), ValidationCode.required);
      expect(c.errorFor(ApplicationField.channel), ValidationCode.required);
      expect(
        c.errorFor(ApplicationField.applicationDate),
        ValidationCode.required,
      );
      expect(repository.store, isEmpty);
    });

    test(
      'erros são atualizados ao editar depois da primeira tentativa',
      () async {
        final c = build();
        await c.load();
        await c.save();
        expect(c.errorFor(ApplicationField.companyName), isNotNull);

        c.edit((d) => d.copyWith(companyName: 'Acme'));
        expect(c.errorFor(ApplicationField.companyName), isNull);
      },
    );

    test('CA-E3-06: data digitada inválida impede salvar', () async {
      final c = build();
      await c.load();
      fillRequired(c);
      c.setDate(FormDateField.jobClosingDate, null, invalid: true);
      expect(await c.save(), SaveResult.invalid);

      c.setDate(FormDateField.jobClosingDate, LocalDate(2026, 11, 5));
      expect(await c.save(), SaveResult.saved);
    });

    test('CA-APP-04: salva com histórico inicial e ids gerados', () async {
      final c = build();
      await c.load();
      fillRequired(c);

      expect(await c.save(), SaveResult.saved);
      final saved = repository.store.values.single;
      expect(saved.id, 'gen-0');
      expect(saved.details.companyName, 'Acme');
      expect(saved.statusHistory.single.newStatus, ApplicationStatus.applied);
      expect(saved.createdAt, now);
      expect(c.isDirty.value, isFalse);
    });

    test('CA-APP-11: aviso de duplicidade e confirmação', () async {
      // Existente: "Globex" — "QA".
      repository.store['a'] = minimalApplication(id: 'a');
      final c = build();
      await c.load();
      c.edit(
        (d) => d.copyWith(
          companyName: ' GLOBEX',
          jobTitle: 'qa',
          channel: () => ApplicationChannel.email,
        ),
      );

      expect(await c.save(), SaveResult.duplicateWarning);
      expect(c.duplicateOf.value?.id, 'a');
      expect(repository.store, hasLength(1));

      expect(await c.save(confirmDuplicate: true), SaveResult.saved);
      expect(repository.store, hasLength(2));
    });

    test('CA-E3-05: salvando fica true até a gravação terminar', () async {
      final c = build();
      await c.load();
      fillRequired(c);
      repository.saveGate = Completer<void>();

      final pending = c.save();
      expect(c.isSaving.value, isTrue);
      expect(await c.save(), SaveResult.invalid, reason: 'ignora clique duplo');

      repository.saveGate!.complete();
      expect(await pending, SaveResult.saved);
      expect(c.isSaving.value, isFalse);
    });

    test('CA-E3-05: falha de gravação mantém o formulário', () async {
      final c = build();
      await c.load();
      fillRequired(c);
      repository.failWrites = true;

      expect(await c.save(), SaveResult.failed);
      expect(c.draft.value.companyName, 'Acme');
      expect(c.isDirty.value, isTrue);
      expect(c.isSaving.value, isFalse);
    });

    test('falha ao carregar vira erro', () async {
      repository.failReads = true;
      final c = build();
      await c.load();
      expect(c.loadStatus.value, FormLoadStatus.error);
    });
  });

  group('edição', () {
    test(
      'CA-E3-04: carrega os valores e preserva histórico ao salvar',
      () async {
        final original = fullApplication(id: 'x');
        repository.store['x'] = original;
        final c = build(applicationId: 'x');
        await c.load();

        expect(c.isEditing, isTrue);
        expect(c.draft.value.companyName, 'Acme');
        expect(c.originalStatus, original.status);

        c.edit((d) => d.copyWith(companyName: 'Acme Brasil'));
        expect(await c.save(), SaveResult.saved);

        final saved = repository.store['x']!;
        expect(saved.details.companyName, 'Acme Brasil');
        expect(saved.statusHistory, hasLength(original.statusHistory.length));
        expect(saved.interactions, hasLength(original.interactions.length));
        expect(saved.status, original.status);
        expect(saved.updatedAt, now);
      },
    );

    test('a própria candidatura não gera aviso de duplicidade', () async {
      repository.store['x'] = fullApplication(id: 'x');
      final c = build(applicationId: 'x');
      await c.load();
      c.edit((d) => d.copyWith(notes: 'nova nota'));
      expect(await c.save(), SaveResult.saved);
    });

    test('id inexistente vira "não encontrada"', () async {
      final c = build(applicationId: 'nao-existe');
      await c.load();
      expect(c.loadStatus.value, FormLoadStatus.notFound);
    });
  });
}
