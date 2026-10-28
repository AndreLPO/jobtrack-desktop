import '../../../core/time/local_date.dart';
import '../../../core/time/week_range.dart';
import '../../settings/models/follow_up_settings.dart';
import 'application.dart';
import 'application_status.dart';
import 'follow_up_policy.dart';

/// Indicadores do dashboard (RF-05, §8), sempre calculados a partir dos
/// registros, sem contadores persistidos (RN-DSH-06).
class DashboardMetrics {
  const DashboardMetrics({
    required this.week,
    required this.thisWeek,
    required this.responded,
    required this.awaitingResponse,
    required this.dueFollowUps,
    required this.suggestClose,
    required this.byStatus,
    required this.total,
  });

  factory DashboardMetrics.compute(
    Iterable<Application> applications,
    FollowUpSettings settings,
    LocalDate today,
  ) {
    final week = WeekRange.containing(today);
    var thisWeek = 0;
    var responded = 0;
    var awaiting = 0;
    var due = 0;
    var close = 0;
    var total = 0;
    final byStatus = {for (final s in ApplicationStatus.values) s: 0};

    for (final application in applications) {
      total++;
      byStatus[application.status] = byStatus[application.status]! + 1;
      // RN-DSH-01: cada candidatura conta uma vez, pela data de envio.
      if (week.contains(application.details.applicationDate)) thisWeek++;
      // RN-DSH-02/03 (D-11, D-31): total geral.
      if (application.hasResponse) {
        responded++;
      } else if (application.status.isActive) {
        awaiting++;
      }
      // RN-DSH-04: mesma regra da página de Acompanhamentos.
      switch (FollowUpPolicy.evaluate(application, settings, today)) {
        case FollowUpDue():
          due++;
        case FollowUpSuggestClose():
          close++;
        case FollowUpScheduled() || FollowUpNotApplicable():
          break;
      }
    }

    return DashboardMetrics(
      week: week,
      thisWeek: thisWeek,
      responded: responded,
      awaitingResponse: awaiting,
      dueFollowUps: due,
      suggestClose: close,
      byStatus: Map.unmodifiable(byStatus),
      total: total,
    );
  }

  /// Semana atual (segunda a domingo).
  final WeekRange week;
  final int thisWeek;
  final int responded;

  /// Ativas e sem resposta.
  final int awaitingResponse;
  final int dueFollowUps;
  final int suggestClose;

  /// Todos os status, inclusive com zero (RN-DSH-05).
  final Map<ApplicationStatus, int> byStatus;
  final int total;
}
