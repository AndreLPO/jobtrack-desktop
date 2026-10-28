import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';

import 'fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 28, 9, 30);

  Application created({ApplicationStatus status = ApplicationStatus.applied}) =>
      Application.create(
        id: 'app-1',
        statusChangeId: 'sc-1',
        details: buildDetails(),
        status: status,
        now: now,
      );

  group('Application.create', () {
    test('CA-APP-05: histórico inicial com 1 item sem status anterior', () {
      final app = created();
      expect(app.statusHistory, hasLength(1));
      expect(app.statusHistory.single.previousStatus, isNull);
      expect(app.statusHistory.single.newStatus, ApplicationStatus.applied);
      expect(app.statusHistory.single.changedAt, now);
      expect(app.createdAt, now);
      expect(app.updatedAt, now);
      expect(app.interactions, isEmpty);
    });

    test('aceita qualquer status inicial (D-10)', () {
      final app = created(status: ApplicationStatus.interview);
      expect(app.status, ApplicationStatus.interview);
      expect(app.statusHistory.single.newStatus, ApplicationStatus.interview);
    });
  });

  group('changeStatus', () {
    test('CA-APP-06: adiciona A→B e preserva os anteriores', () {
      final later = now.add(const Duration(days: 2));
      final app = created().changeStatus(
        ApplicationStatus.interview,
        changeId: 'sc-2',
        now: later,
        note: 'chamado para entrevista',
      );

      expect(app.status, ApplicationStatus.interview);
      expect(app.statusHistory, hasLength(2));
      final change = app.statusHistory.last;
      expect(change.previousStatus, ApplicationStatus.applied);
      expect(change.newStatus, ApplicationStatus.interview);
      expect(change.changedAt, later);
      expect(change.note, 'chamado para entrevista');
      expect(app.statusHistory.first.id, 'sc-1');
      expect(app.updatedAt, later);
    });

    test('CA-APP-06: mesmo status não gera registro', () {
      final app = created();
      final same = app.changeStatus(
        ApplicationStatus.applied,
        changeId: 'sc-2',
        now: now,
      );
      expect(identical(same, app), isTrue);
    });

    test('CA-APP-07: reabre candidatura encerrada', () {
      final app = created()
          .changeStatus(ApplicationStatus.rejected, changeId: 'sc-2', now: now)
          .changeStatus(
            ApplicationStatus.interview,
            changeId: 'sc-3',
            now: now,
          );
      expect(app.status, ApplicationStatus.interview);
      expect(app.statusHistory.map((c) => c.newStatus), [
        ApplicationStatus.applied,
        ApplicationStatus.rejected,
        ApplicationStatus.interview,
      ]);
    });
  });

  group('updateDetails', () {
    test('CA-APP-08: preserva histórico e contatos', () {
      final app = created()
          .changeStatus(
            ApplicationStatus.responseReceived,
            changeId: 'sc-2',
            now: now,
          )
          .registerInteraction(
            contact(LocalDate(2026, 10, 27), InteractionType.call),
            now: now,
          );

      final edited = app.updateDetails(
        buildDetails(companyName: 'Acme Brasil'),
        manualNextFollowUpAt: null,
        now: now.add(const Duration(hours: 1)),
      );

      expect(edited.details.companyName, 'Acme Brasil');
      expect(edited.statusHistory, app.statusHistory);
      expect(edited.interactions, app.interactions);
      expect(edited.id, app.id);
      expect(edited.createdAt, app.createdAt);
    });

    test('define e limpa a data manual', () {
      final withDate = created().updateDetails(
        buildDetails(),
        manualNextFollowUpAt: LocalDate(2026, 11, 5),
        now: now,
      );
      expect(withDate.manualNextFollowUpAt, LocalDate(2026, 11, 5));

      final cleared = withDate.updateDetails(
        buildDetails(),
        manualNextFollowUpAt: null,
        now: now,
      );
      expect(cleared.manualNextFollowUpAt, isNull);
    });
  });

  group('hasResponse (D-11)', () {
    test('CA-APP-09: N contatos de resposta contam uma vez e não mudam o '
        'status', () {
      final app = buildApplication(
        interactions: [
          contact(
            LocalDate(2026, 10, 5),
            InteractionType.messageReceived,
            response: true,
          ),
          contact(
            LocalDate(2026, 10, 6),
            InteractionType.messageReceived,
            response: true,
          ),
          contact(LocalDate(2026, 10, 7), InteractionType.call, response: true),
        ],
      );
      expect(app.hasResponse, isTrue);
      expect(app.status, ApplicationStatus.applied);
      expect([app].where((a) => a.hasResponse).length, 1);
    });

    test('status que indica resposta basta', () {
      final app = buildApplication(initialStatus: ApplicationStatus.rejected);
      expect(app.hasResponse, isTrue);
    });

    test('sem resposta em status e contatos', () {
      final app = buildApplication(
        interactions: [
          contact(LocalDate(2026, 10, 8), InteractionType.followUpSent),
        ],
      );
      expect(app.hasResponse, isFalse);
    });
  });

  group('lastContactAt (D-14)', () {
    test('CA-APP-10: é a maior data, não a última registrada', () {
      final app = buildApplication(
        interactions: [
          contact(LocalDate(2026, 10, 9), InteractionType.call),
          contact(LocalDate(2026, 10, 5), InteractionType.followUpSent),
        ],
      );
      expect(app.lastContactAt, LocalDate(2026, 10, 9));
      expect(app.latestInteraction!.type, InteractionType.call);
    });

    test('no empate de datas, vale o último registrado', () {
      final app = buildApplication(
        interactions: [
          contact(LocalDate(2026, 10, 9), InteractionType.interview),
          contact(LocalDate(2026, 10, 9), InteractionType.thankYouSent),
        ],
      );
      expect(app.latestInteraction!.type, InteractionType.thankYouSent);
    });

    test('nulo sem contatos', () {
      expect(buildApplication().lastContactAt, isNull);
    });
  });

  group('data manual (D-21a)', () {
    test('registrar contato substitui a data manual, ou limpa', () {
      final withNext = created().registerInteraction(
        contact(
          LocalDate(2026, 10, 27),
          InteractionType.followUpSent,
          nextFollowUpAt: LocalDate(2026, 11, 10),
        ),
        now: now,
      );
      expect(withNext.manualNextFollowUpAt, LocalDate(2026, 11, 10));

      final withoutNext = withNext.registerInteraction(
        contact(LocalDate(2026, 10, 28), InteractionType.call),
        now: now,
      );
      expect(withoutNext.manualNextFollowUpAt, isNull);
      expect(withoutNext.interactions, hasLength(2));
    });

    test('postpone define a data manual', () {
      final app = created().postpone(LocalDate(2026, 11, 2), now: now);
      expect(app.manualNextFollowUpAt, LocalDate(2026, 11, 2));
    });
  });

  test('listas expostas são imutáveis', () {
    final app = created();
    expect(
      () => app.interactions.add(
        contact(LocalDate(2026, 10, 1), InteractionType.other),
      ),
      throwsUnsupportedError,
    );
  });
}
