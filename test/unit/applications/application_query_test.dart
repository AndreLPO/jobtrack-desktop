import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/models/application_channel.dart';
import 'package:jobtrack_desktop/features/applications/models/application_details.dart';
import 'package:jobtrack_desktop/features/applications/models/application_query.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';

import 'fixtures.dart';

final today = LocalDate(2026, 10, 28);

Application app(
  String id, {
  String company = 'Acme',
  String job = 'Dev',
  LocalDate? applied,
  ApplicationChannel channel = ApplicationChannel.linkedIn,
  ApplicationStatus status = ApplicationStatus.applied,
  DateTime? updatedAt,
  LocalDate? manual,
  List<(InteractionType, LocalDate)> followUps = const [],
}) {
  final base = buildApplication(
    id: id,
    applicationDate: applied ?? today.addDays(-3),
    initialStatus: status,
    manualNextFollowUpAt: manual,
    interactions: [for (final (t, d) in followUps) contact(d, t)],
  );
  return Application(
    id: base.id,
    details: ApplicationDetails(
      companyName: company,
      jobTitle: job,
      applicationDate: base.details.applicationDate,
      channel: channel,
    ),
    status: base.status,
    manualNextFollowUpAt: base.manualNextFollowUpAt,
    createdAt: base.createdAt,
    updatedAt: updatedAt ?? base.updatedAt,
    statusHistory: base.statusHistory,
    interactions: base.interactions,
  );
}

List<String> run(
  List<Application> apps, {
  ApplicationFilter filter = const ApplicationFilter(),
  ApplicationSort sort = ApplicationSort.applicationDate,
}) => queryApplications(
  apps,
  filter: filter,
  sort: sort,
  settings: const FollowUpSettings(),
  today: today,
).map((a) => a.id).toList();

void main() {
  group('normalizeForSearch (D-56)', () {
    test('remove acentos e caixa', () {
      expect(normalizeForSearch('São Paulo'), 'sao paulo');
      expect(normalizeForSearch('AÇÃO Êxito'), 'acao exito');
    });
  });

  group('busca', () {
    final apps = [
      app('a', company: 'São Paulo Tech', job: 'Dev Flutter'),
      app('b', company: 'Acme', job: 'Engenheira de Software'),
      app('c', company: 'Globex', job: 'QA'),
    ];

    test('CA-APP-13: por empresa ou vaga, sem caixa e sem acento', () {
      expect(run(apps, filter: const ApplicationFilter(text: 'sao')), ['a']);
      expect(run(apps, filter: const ApplicationFilter(text: 'ENGENHEIRA')), [
        'b',
      ]);
      expect(run(apps, filter: const ApplicationFilter(text: 'flutter')), [
        'a',
      ]);
      expect(
        run(apps, filter: const ApplicationFilter(text: '  ')),
        hasLength(3),
      );
      expect(run(apps, filter: const ApplicationFilter(text: 'xyz')), isEmpty);
    });
  });

  group('filtros', () {
    final apps = [
      app(
        'a',
        status: ApplicationStatus.interview,
        applied: today.addDays(-10),
      ),
      app('b', channel: ApplicationChannel.gupy, applied: today.addDays(-5)),
      app(
        'c',
        status: ApplicationStatus.interview,
        channel: ApplicationChannel.gupy,
        applied: today.addDays(-1),
      ),
    ];

    test('por status (vários)', () {
      expect(
        run(
          apps,
          filter: const ApplicationFilter(
            statuses: {ApplicationStatus.interview},
          ),
        ),
        ['c', 'a'],
      );
    });

    test('CA-APP-14: status e canal combinados com E', () {
      expect(
        run(
          apps,
          filter: const ApplicationFilter(
            statuses: {ApplicationStatus.interview},
            channels: {ApplicationChannel.gupy},
          ),
        ),
        ['c'],
      );
    });

    test('CA-APP-15: período inclusivo nas duas pontas', () {
      expect(
        run(
          apps,
          filter: ApplicationFilter(
            from: today.addDays(-10),
            to: today.addDays(-5),
          ),
        ),
        ['b', 'a'],
      );
      expect(run(apps, filter: ApplicationFilter(from: today.addDays(-4))), [
        'c',
      ]);
      expect(run(apps, filter: ApplicationFilter(to: today.addDays(-6))), [
        'a',
      ]);
    });

    test('só acompanhamento: vencidas e sugerido encerrar (D-59)', () {
      final followUps = [
        app('due', applied: today.addDays(-8)),
        app('scheduled', applied: today.addDays(-2)),
        app(
          'close',
          applied: today.addDays(-40),
          followUps: [
            (InteractionType.followUpSent, today.addDays(-30)),
            (InteractionType.followUpSent, today.addDays(-20)),
            (InteractionType.followUpSent, today.addDays(-10)),
          ],
        ),
        app(
          'closed',
          applied: today.addDays(-30),
          status: ApplicationStatus.withdrawn,
        ),
      ];
      expect(
        run(
          followUps,
          filter: const ApplicationFilter(onlyNeedingFollowUp: true),
        ).toSet(),
        {'due', 'close'},
      );
    });

    test('isEmpty e copyWith', () {
      expect(const ApplicationFilter().isEmpty, isTrue);
      final f = const ApplicationFilter().copyWith(from: () => today);
      expect(f.isEmpty, isFalse);
      expect(f.copyWith(from: () => null).isEmpty, isTrue);
    });
  });

  group('ordenação', () {
    test('data da candidatura: mais recente primeiro', () {
      final apps = [
        app('old', applied: today.addDays(-9)),
        app('new', applied: today.addDays(-1)),
      ];
      expect(run(apps), ['new', 'old']);
    });

    test('última atualização: mais recente primeiro', () {
      final apps = [
        app('a', updatedAt: DateTime(2026, 10, 1)),
        app('b', updatedAt: DateTime(2026, 10, 20)),
      ];
      expect(run(apps, sort: ApplicationSort.updatedAt), ['b', 'a']);
    });

    test('próximo acompanhamento: mais próxima primeiro, sem data no fim', () {
      final apps = [
        app('later', applied: today.addDays(-1)), // vence em +6
        app(
          'closed',
          applied: today.addDays(-30),
          status: ApplicationStatus.rejected,
        ),
        app('overdue', applied: today.addDays(-20)), // venceu em -13
        app('manual', manual: today.addDays(2)),
      ];
      expect(run(apps, sort: ApplicationSort.nextFollowUp), [
        'overdue',
        'manual',
        'later',
        'closed',
      ]);
    });
  });
}
