import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/dashboard_metrics.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';

import 'fixtures.dart';

DashboardMetrics compute(List<Application> apps, LocalDate today) =>
    DashboardMetrics.compute(apps, const FollowUpSettings(), today);

void main() {
  group('semana atual (RN-DSH-01)', () {
    test('CA-DSH-01: domingo 01/11/2026 conta 26/10 e 01/11, não 25/10', () {
      final metrics = compute([
        buildApplication(applicationDate: LocalDate(2026, 10, 26)),
        buildApplication(applicationDate: LocalDate(2026, 11, 1)),
        buildApplication(applicationDate: LocalDate(2026, 10, 25)),
      ], LocalDate(2026, 11, 1));
      expect(metrics.thisWeek, 2);
      expect(metrics.week.start, LocalDate(2026, 10, 26));
    });

    test('CA-DSH-02: semana que cruza o ano', () {
      final metrics = compute([
        buildApplication(applicationDate: LocalDate(2026, 12, 28)),
        buildApplication(applicationDate: LocalDate(2026, 12, 27)),
      ], LocalDate(2026, 12, 31));
      expect(metrics.thisWeek, 1);
      expect(metrics.week.end, LocalDate(2027, 1, 3));
    });

    test('CA-DSH-03: na segunda, o domingo anterior não conta', () {
      final metrics = compute([
        buildApplication(applicationDate: LocalDate(2026, 10, 26)),
        buildApplication(applicationDate: LocalDate(2026, 10, 25)),
      ], LocalDate(2026, 10, 26));
      expect(metrics.thisWeek, 1);
    });
  });

  group('respostas e totais', () {
    final today = LocalDate(2026, 10, 28);
    LocalDate ago(int d) => today.addDays(-d);

    final apps = [
      // Respondida por 3 contatos: conta 1 (CA-DSH-04).
      buildApplication(
        applicationDate: ago(20),
        interactions: [
          contact(ago(15), InteractionType.messageReceived, response: true),
          contact(ago(10), InteractionType.call, response: true),
          contact(ago(5), InteractionType.messageReceived, response: true),
        ],
      ),
      // Respondida por status.
      buildApplication(
        applicationDate: ago(20),
        statusChanges: [(ApplicationStatus.interview, ago(10))],
      ),
      // Aguardando e vencida.
      buildApplication(applicationDate: ago(9)),
      // Aguardando e agendada.
      buildApplication(applicationDate: ago(2)),
      // Encerrada sem resposta.
      buildApplication(
        applicationDate: ago(40),
        statusChanges: [(ApplicationStatus.withdrawn, ago(30))],
      ),
      // Sugerido encerrar.
      buildApplication(
        applicationDate: ago(40),
        interactions: [
          contact(ago(30), InteractionType.followUpSent),
          contact(ago(20), InteractionType.followUpSent),
          contact(ago(10), InteractionType.followUpSent),
        ],
      ),
    ];

    test('CA-DSH-04: respostas contam candidaturas, não mensagens', () {
      expect(compute(apps, today).responded, 2);
    });

    test('aguardando = ativas sem resposta', () {
      expect(compute(apps, today).awaitingResponse, 3);
    });

    test('CA-DSH-05: respondidas + aguardando + encerradas sem resposta = '
        'total', () {
      final m = compute(apps, today);
      final closedWithoutResponse = apps
          .where((a) => a.status.isClosed && !a.hasResponse)
          .length;
      expect(m.responded + m.awaitingResponse + closedWithoutResponse, m.total);
      expect(m.total, 6);
    });

    test('CA-DSH-06: pendentes e sugerido encerrar pela mesma regra', () {
      final m = compute(apps, today);
      // Vencidas: a de 9 dias e a Entrevista sem contato do tipo
      // Entrevista (mudança de status + 1 dia, D-22b).
      expect(m.dueFollowUps, 2);
      expect(m.suggestClose, 1);
    });

    test('RN-DSH-05: resumo por status com zeros e soma igual ao total', () {
      final m = compute(apps, today);
      expect(m.byStatus.keys, ApplicationStatus.values);
      expect(m.byStatus[ApplicationStatus.applied], 4);
      expect(m.byStatus[ApplicationStatus.rejected], 0);
      expect(m.byStatus.values.fold<int>(0, (a, b) => a + b), m.total);
    });

    test('CA-DSH-09: sem candidaturas tudo zero', () {
      final m = compute([], today);
      expect(m.total, 0);
      expect(m.thisWeek, 0);
      expect(m.byStatus.values.every((v) => v == 0), isTrue);
    });
  });
}
