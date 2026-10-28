import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/kanban.dart';

import 'fixtures.dart';

void main() {
  test('K-02: 5 colunas ativas na ordem do processo + Encerradas', () {
    expect(kanbanColumns, hasLength(6));
    expect(kanbanColumns.take(5).map((c) => c.dropStatus), [
      ApplicationStatus.applied,
      ApplicationStatus.responseReceived,
      ApplicationStatus.interview,
      ApplicationStatus.technicalTest,
      ApplicationStatus.offerReceived,
    ]);
    final closed = kanbanColumns.last;
    expect(closed.isGrouped, isTrue);
    expect(closed.dropStatus, isNull);
    expect(closed.statuses.toSet(), {
      ApplicationStatus.rejected,
      ApplicationStatus.withdrawn,
      ApplicationStatus.closedWithoutResponse,
    });
  });

  test('RN-KB-01/05: cada candidatura em uma coluna, ordem preservada', () {
    final apps = [
      buildApplication(id: 'a2', initialStatus: ApplicationStatus.applied),
      buildApplication(id: 'i1', initialStatus: ApplicationStatus.interview),
      buildApplication(id: 'a1', initialStatus: ApplicationStatus.applied),
      buildApplication(id: 'r1', initialStatus: ApplicationStatus.rejected),
      buildApplication(id: 'w1', initialStatus: ApplicationStatus.withdrawn),
    ];
    final groups = groupForKanban(apps, kanbanColumns);

    expect(groups[0].map((a) => a.id), ['a2', 'a1']);
    expect(groups[2].map((a) => a.id), ['i1']);
    expect(groups[5].map((a) => a.id), ['r1', 'w1']);
    expect(groups.expand((g) => g).length, apps.length);
  });

  test('RN-KB-04: filtro de status limita as colunas', () {
    expect(visibleKanbanColumns({}), kanbanColumns);
    expect(
      visibleKanbanColumns({ApplicationStatus.interview})
          .map((c) => c.dropStatus),
      [ApplicationStatus.interview],
    );
    final withClosed = visibleKanbanColumns({
      ApplicationStatus.applied,
      ApplicationStatus.withdrawn,
    });
    expect(withClosed, hasLength(2));
    expect(withClosed.last.isGrouped, isTrue);
  });
}
