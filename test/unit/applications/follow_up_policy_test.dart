import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/follow_up_policy.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';

import 'fixtures.dart';

/// Quarta-feira.
final today = LocalDate(2026, 10, 28);
LocalDate daysAgo(int n) => today.addDays(-n);

const defaults = FollowUpSettings();

FollowUpState evaluate(
  Application app, {
  FollowUpSettings settings = defaults,
  LocalDate? on,
}) => FollowUpPolicy.evaluate(app, settings, on ?? today);

Matcher isDue(LocalDate date, FollowUpBaseKind kind, LocalDate baseDate) =>
    isA<FollowUpDue>()
        .having((s) => s.dueDate, 'dueDate', date)
        .having((s) => s.base, 'base', FollowUpBase(kind, baseDate));

Matcher isScheduled(
  LocalDate date,
  FollowUpBaseKind kind,
  LocalDate baseDate,
) => isA<FollowUpScheduled>()
    .having((s) => s.dueDate, 'dueDate', date)
    .having((s) => s.base, 'base', FollowUpBase(kind, baseDate));

Matcher isSuggestClose(int attempts) =>
    isA<FollowUpSuggestClose>().having((s) => s.attempts, 'attempts', attempts);

void main() {
  group('sem resposta', () {
    test('CA-FU-01: aplicada há 6 dias → agendada', () {
      final app = buildApplication(applicationDate: daysAgo(6));
      expect(
        evaluate(app),
        isScheduled(
          today.addDays(1),
          FollowUpBaseKind.applicationDate,
          daysAgo(6),
        ),
      );
    });

    test('CA-FU-02: aplicada há exatamente 7 dias → vencida', () {
      final app = buildApplication(applicationDate: daysAgo(7));
      expect(
        evaluate(app),
        isDue(today, FollowUpBaseKind.applicationDate, daysAgo(7)),
      );
    });

    test('CA-FU-05: 2 tentativas, a última há 7 dias → vencida', () {
      final app = buildApplication(
        applicationDate: daysAgo(30),
        interactions: [
          contact(daysAgo(20), InteractionType.followUpSent),
          contact(daysAgo(7), InteractionType.followUpSent),
        ],
      );
      expect(
        evaluate(app),
        isDue(today, FollowUpBaseKind.lastContact, daysAgo(7)),
      );
    });

    test('CA-FU-04: 3 tentativas → sugerido encerrar, status inalterado', () {
      final app = buildApplication(
        applicationDate: daysAgo(40),
        interactions: [
          contact(daysAgo(30), InteractionType.followUpSent),
          contact(daysAgo(20), InteractionType.followUpSent),
          contact(daysAgo(10), InteractionType.followUpSent),
        ],
      );
      expect(evaluate(app), isSuggestClose(3));
      expect(app.status, ApplicationStatus.applied);
    });

    test('agradecimento e outros contatos não contam como tentativa', () {
      final app = buildApplication(
        applicationDate: daysAgo(40),
        interactions: [
          contact(daysAgo(30), InteractionType.followUpSent),
          contact(daysAgo(20), InteractionType.thankYouSent),
          contact(daysAgo(10), InteractionType.call),
        ],
      );
      expect(FollowUpPolicy.attemptsSinceLastResponse(app), 1);
    });

    group('CA-FU-06: data de encerramento da vaga (D-26, I-4)', () {
      test('encerramento há 2 dias, sem contatos → vencida hoje', () {
        final app = buildApplication(
          applicationDate: daysAgo(1),
          jobClosingDate: daysAgo(2),
        );
        expect(
          evaluate(app),
          isDue(today, FollowUpBaseKind.jobClosing, daysAgo(2)),
        );
      });

      test('encerramento ontem → agendada para amanhã', () {
        final app = buildApplication(
          applicationDate: daysAgo(1),
          jobClosingDate: daysAgo(1),
        );
        expect(
          evaluate(app),
          isScheduled(
            today.addDays(1),
            FollowUpBaseKind.jobClosing,
            daysAgo(1),
          ),
        );
      });

      test('encerramento futuro prevalece sobre candidatura + prazo', () {
        final app = buildApplication(
          applicationDate: daysAgo(10),
          jobClosingDate: today.addDays(5),
        );
        expect(
          evaluate(app),
          isScheduled(
            today.addDays(7),
            FollowUpBaseKind.jobClosing,
            today.addDays(5),
          ),
        );
      });

      test('depois do primeiro contato vale o último contato', () {
        final app = buildApplication(
          applicationDate: daysAgo(10),
          jobClosingDate: today.addDays(5),
          interactions: [contact(daysAgo(3), InteractionType.followUpSent)],
        );
        expect(
          evaluate(app),
          isScheduled(
            today.addDays(4),
            FollowUpBaseKind.lastContact,
            daysAgo(3),
          ),
        );
      });
    });
  });

  group('status encerrado', () {
    for (final status in [
      ApplicationStatus.rejected,
      ApplicationStatus.withdrawn,
      ApplicationStatus.closedWithoutResponse,
    ]) {
      test('CA-FU-03: ${status.name} → não se aplica', () {
        final app = buildApplication(
          applicationDate: daysAgo(30),
          statusChanges: [(status, daysAgo(20))],
          manualNextFollowUpAt: daysAgo(1),
        );
        expect(evaluate(app), isA<FollowUpNotApplicable>());
      });
    }
  });

  group('entrevista (D-22, D-22b)', () {
    test('CA-FU-07: contato Entrevista ontem → vencida hoje', () {
      final app = buildApplication(
        applicationDate: daysAgo(20),
        statusChanges: [(ApplicationStatus.interview, daysAgo(5))],
        interactions: [contact(daysAgo(1), InteractionType.interview)],
      );
      expect(
        evaluate(app),
        isDue(today, FollowUpBaseKind.interview, daysAgo(1)),
      );
    });

    test('CA-FU-08: agradecimento depois da entrevista → prazo padrão', () {
      final app = buildApplication(
        applicationDate: daysAgo(20),
        statusChanges: [(ApplicationStatus.interview, daysAgo(5))],
        interactions: [
          contact(daysAgo(3), InteractionType.interview),
          contact(daysAgo(2), InteractionType.thankYouSent),
        ],
      );
      expect(
        evaluate(app),
        isScheduled(today.addDays(5), FollowUpBaseKind.lastContact, daysAgo(2)),
      );
    });

    test('D-22b: sem contato Entrevista, outros contatos não mudam a base', () {
      // Status mudou em 10/11; "Mensagem recebida" em 11/11.
      final changedOn = LocalDate(2026, 11, 10);
      final app = buildApplication(
        applicationDate: LocalDate(2026, 11, 1),
        statusChanges: [(ApplicationStatus.interview, changedOn)],
        interactions: [
          contact(LocalDate(2026, 11, 11), InteractionType.messageReceived),
        ],
      );
      expect(
        evaluate(app, on: LocalDate(2026, 11, 11)),
        isDue(
          LocalDate(2026, 11, 11),
          FollowUpBaseKind.statusChange,
          changedOn,
        ),
      );
    });

    test('contato Entrevista anterior à mudança de status é ignorado', () {
      // 1ª rodada: entrevista em 05/10. Voltou para Entrevista em 20/10.
      final app = buildApplication(
        applicationDate: LocalDate(2026, 9, 25),
        statusChanges: [
          (ApplicationStatus.interview, LocalDate(2026, 10, 1)),
          (ApplicationStatus.technicalTest, LocalDate(2026, 10, 10)),
          (ApplicationStatus.interview, LocalDate(2026, 10, 20)),
        ],
        interactions: [
          contact(LocalDate(2026, 10, 5), InteractionType.interview),
        ],
      );
      expect(
        evaluate(app),
        isDue(
          LocalDate(2026, 10, 21),
          FollowUpBaseKind.statusChange,
          LocalDate(2026, 10, 20),
        ),
      );
    });

    test(
      'entrevista e agradecimento no mesmo dia: vale o último registrado',
      () {
        final app = buildApplication(
          applicationDate: daysAgo(20),
          statusChanges: [(ApplicationStatus.interview, daysAgo(5))],
          interactions: [
            contact(daysAgo(1), InteractionType.interview),
            contact(daysAgo(1), InteractionType.thankYouSent),
          ],
        );
        expect(
          evaluate(app),
          isScheduled(
            today.addDays(6),
            FollowUpBaseKind.lastContact,
            daysAgo(1),
          ),
        );
      },
    );
  });

  group('outros status com resposta (RN-FU-06/07, I-3)', () {
    test('CA-FU-09: Teste técnico há 7 dias, sem contatos → vencida', () {
      final app = buildApplication(
        applicationDate: daysAgo(30),
        statusChanges: [(ApplicationStatus.technicalTest, daysAgo(7))],
      );
      expect(
        evaluate(app),
        isDue(today, FollowUpBaseKind.statusChange, daysAgo(7)),
      );
    });

    test('contato posterior à mudança de status vira a base', () {
      final app = buildApplication(
        applicationDate: daysAgo(30),
        statusChanges: [(ApplicationStatus.offerReceived, daysAgo(10))],
        interactions: [contact(daysAgo(2), InteractionType.call)],
      );
      expect(
        evaluate(app),
        isScheduled(today.addDays(5), FollowUpBaseKind.lastContact, daysAgo(2)),
      );
    });

    test('contato anterior à mudança de status não é base', () {
      final app = buildApplication(
        applicationDate: daysAgo(30),
        interactions: [contact(daysAgo(20), InteractionType.call)],
        statusChanges: [(ApplicationStatus.responseReceived, daysAgo(3))],
      );
      expect(
        evaluate(app),
        isScheduled(
          today.addDays(4),
          FollowUpBaseKind.statusChange,
          daysAgo(3),
        ),
      );
    });

    test('RN-FU-07: Aplicada com contato de resposta segue a mesma regra', () {
      final app = buildApplication(
        applicationDate: daysAgo(30),
        interactions: [
          contact(daysAgo(7), InteractionType.messageReceived, response: true),
        ],
      );
      expect(app.status, ApplicationStatus.applied);
      expect(
        evaluate(app),
        isDue(today, FollowUpBaseKind.lastContact, daysAgo(7)),
      );
    });
  });

  group('limite de tentativas após resposta (D-25, D-25b, D-28)', () {
    test(
      'CA-FU-10b: 3 acompanhamentos após a resposta → sugerido encerrar',
      () {
        final app = buildApplication(
          applicationDate: daysAgo(60),
          statusChanges: [(ApplicationStatus.responseReceived, daysAgo(40))],
          interactions: [
            contact(daysAgo(30), InteractionType.followUpSent),
            contact(daysAgo(20), InteractionType.followUpSent),
            contact(daysAgo(10), InteractionType.followUpSent),
          ],
        );
        expect(evaluate(app), isSuggestClose(3));
      },
    );

    test('CA-FU-10b: nova resposta zera a contagem', () {
      final app = buildApplication(
        applicationDate: daysAgo(60),
        statusChanges: [(ApplicationStatus.responseReceived, daysAgo(40))],
        interactions: [
          contact(daysAgo(30), InteractionType.followUpSent),
          contact(daysAgo(20), InteractionType.followUpSent),
          contact(daysAgo(10), InteractionType.followUpSent),
          contact(daysAgo(5), InteractionType.messageReceived, response: true),
        ],
      );
      expect(FollowUpPolicy.attemptsSinceLastResponse(app), 0);
      expect(
        evaluate(app),
        isScheduled(today.addDays(2), FollowUpBaseKind.lastContact, daysAgo(5)),
      );
    });

    test('mudança para status de resposta também zera a contagem', () {
      final app = buildApplication(
        applicationDate: daysAgo(60),
        interactions: [
          contact(daysAgo(30), InteractionType.followUpSent),
          contact(daysAgo(20), InteractionType.followUpSent),
          contact(daysAgo(10), InteractionType.followUpSent),
        ],
        statusChanges: [(ApplicationStatus.technicalTest, daysAgo(5))],
      );
      expect(FollowUpPolicy.attemptsSinceLastResponse(app), 0);
    });

    test('D-25b: acompanhamento no mesmo dia da resposta não conta', () {
      final sameDay = buildApplication(
        applicationDate: daysAgo(30),
        interactions: [
          contact(daysAgo(10), InteractionType.messageReceived, response: true),
          contact(daysAgo(10), InteractionType.followUpSent),
        ],
      );
      expect(FollowUpPolicy.attemptsSinceLastResponse(sameDay), 0);

      final nextDay = buildApplication(
        applicationDate: daysAgo(30),
        interactions: [
          contact(daysAgo(10), InteractionType.messageReceived, response: true),
          contact(daysAgo(9), InteractionType.followUpSent),
        ],
      );
      expect(FollowUpPolicy.attemptsSinceLastResponse(nextDay), 1);
    });
  });

  group('data manual (D-21a)', () {
    test('CA-FU-10: data manual futura prevalece sobre o limite', () {
      final app = buildApplication(
        applicationDate: daysAgo(40),
        interactions: [
          contact(daysAgo(30), InteractionType.followUpSent),
          contact(daysAgo(20), InteractionType.followUpSent),
          contact(daysAgo(10), InteractionType.followUpSent),
        ],
        manualNextFollowUpAt: today.addDays(5),
      );
      expect(
        evaluate(app),
        isScheduled(
          today.addDays(5),
          FollowUpBaseKind.manual,
          today.addDays(5),
        ),
      );
    });

    test('data manual vencida → vencida', () {
      final app = buildApplication(
        applicationDate: daysAgo(3),
        manualNextFollowUpAt: daysAgo(1),
      );
      expect(
        evaluate(app),
        isDue(daysAgo(1), FollowUpBaseKind.manual, daysAgo(1)),
      );
    });

    test('CA-FU-10c: adiar e encerrar sem resposta', () {
      final now = DateTime(2026, 10, 28, 10);
      final app = buildApplication(applicationDate: daysAgo(10));
      expect(evaluate(app), isA<FollowUpDue>());

      final postponed = app.postpone(today.addDays(5), now: now);
      expect(evaluate(postponed), isA<FollowUpScheduled>());

      final closed = app.changeStatus(
        ApplicationStatus.closedWithoutResponse,
        changeId: 'sc-close',
        now: now,
      );
      expect(evaluate(closed), isA<FollowUpNotApplicable>());
      expect(
        closed.statusHistory.last.newStatus,
        ApplicationStatus.closedWithoutResponse,
      );
    });
  });

  group('configurações', () {
    test(
      'CA-FU-11 / CA-SET-04: prazo de 3 dias vence candidatura de 4 dias',
      () {
        final app = buildApplication(applicationDate: daysAgo(4));
        expect(evaluate(app), isA<FollowUpScheduled>());
        expect(
          evaluate(app, settings: const FollowUpSettings(intervalDays: 3)),
          isDue(daysAgo(1), FollowUpBaseKind.applicationDate, daysAgo(4)),
        );
      },
    );

    test('CA-SET-05: limite 2 com 2 tentativas → sugerido encerrar', () {
      final app = buildApplication(
        applicationDate: daysAgo(30),
        interactions: [
          contact(daysAgo(20), InteractionType.followUpSent),
          contact(daysAgo(10), InteractionType.followUpSent),
        ],
      );
      expect(evaluate(app), isNot(isA<FollowUpSuggestClose>()));
      expect(
        evaluate(app, settings: const FollowUpSettings(maxAttempts: 2)),
        isSuggestClose(2),
      );
    });
  });

  group('CA-FU-12: limites de calendário', () {
    test('virada de ano: 28/12 + 7 = 04/01', () {
      final app = buildApplication(applicationDate: LocalDate(2026, 12, 28));
      expect(
        evaluate(app, on: LocalDate(2027, 1, 3)),
        isA<FollowUpScheduled>(),
      );
      expect(
        evaluate(app, on: LocalDate(2027, 1, 4)),
        isDue(
          LocalDate(2027, 1, 4),
          FollowUpBaseKind.applicationDate,
          LocalDate(2026, 12, 28),
        ),
      );
    });

    test('virada de mês: 28/10 + 7 = 04/11', () {
      final app = buildApplication(applicationDate: LocalDate(2026, 10, 28));
      expect(
        evaluate(app, on: LocalDate(2026, 11, 4)),
        isA<FollowUpDue>().having(
          (s) => s.dueDate,
          'dueDate',
          LocalDate(2026, 11, 4),
        ),
      );
    });

    test('29/02 em ano bissexto; 01/03 em ano comum', () {
      final leap = buildApplication(applicationDate: LocalDate(2028, 2, 22));
      expect(
        evaluate(leap, on: LocalDate(2028, 2, 29)),
        isA<FollowUpDue>().having(
          (s) => s.dueDate,
          'dueDate',
          LocalDate(2028, 2, 29),
        ),
      );

      final common = buildApplication(applicationDate: LocalDate(2027, 2, 22));
      expect(
        evaluate(common, on: LocalDate(2027, 2, 28)),
        isScheduled(
          LocalDate(2027, 3, 1),
          FollowUpBaseKind.applicationDate,
          LocalDate(2027, 2, 22),
        ),
      );
    });
  });

  // CA-FU-13 (mesma contagem em Acompanhamentos, dashboard e listagem) é
  // garantido por todas as telas usarem FollowUpPolicy.evaluate; será
  // verificado nos testes de controller das Etapas 7 e 8.
}
