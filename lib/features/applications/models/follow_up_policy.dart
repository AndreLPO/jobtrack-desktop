import '../../../core/time/local_date.dart';
import '../../settings/models/follow_up_settings.dart';
import 'application.dart';
import 'application_status.dart';
import 'interaction.dart';
import 'interaction_type.dart';

/// De onde veio a data usada no cálculo (RN-FU-09).
enum FollowUpBaseKind {
  manual,
  applicationDate,
  lastContact,
  jobClosing,
  interview,
  statusChange,
}

class FollowUpBase {
  const FollowUpBase(this.kind, this.date);

  final FollowUpBaseKind kind;
  final LocalDate date;

  @override
  bool operator ==(Object other) =>
      other is FollowUpBase && other.kind == kind && other.date == date;

  @override
  int get hashCode => Object.hash(kind, date);

  @override
  String toString() => 'FollowUpBase(${kind.name}, $date)';
}

/// Situação de acompanhamento de uma candidatura (follow-ups §5).
sealed class FollowUpState {
  const FollowUpState();
}

/// Status encerrado: nunca aparece na lista.
final class FollowUpNotApplicable extends FollowUpState {
  const FollowUpNotApplicable();
}

/// Data sugerida ainda no futuro.
final class FollowUpScheduled extends FollowUpState {
  const FollowUpScheduled(this.dueDate, this.base);

  final LocalDate dueDate;
  final FollowUpBase base;
}

/// Data sugerida hoje ou no passado: aparece em "Vencidos".
final class FollowUpDue extends FollowUpState {
  const FollowUpDue(this.dueDate, this.base);

  final LocalDate dueDate;
  final FollowUpBase base;
}

/// Limite de tentativas atingido: aparece em "Sugerido encerrar".
final class FollowUpSuggestClose extends FollowUpState {
  const FollowUpSuggestClose(this.attempts);

  final int attempts;
}

/// Regra única de acompanhamento (RN-FU-05: nenhuma tela ou controller
/// a reimplementa).
abstract final class FollowUpPolicy {
  /// Prazo fixo para o agradecimento após a entrevista (D-22).
  static const interviewThankYouDays = 1;

  /// Dias após o encerramento da vaga para o 1º acompanhamento (D-26).
  static const jobClosingOffsetDays = 2;

  static FollowUpState evaluate(
    Application application,
    FollowUpSettings settings,
    LocalDate today,
  ) {
    // RN-FU-01
    if (application.status.isClosed) return const FollowUpNotApplicable();

    // RN-FU-02
    final manual = application.manualNextFollowUpAt;
    if (manual != null) {
      return _classify(
        manual,
        FollowUpBase(FollowUpBaseKind.manual, manual),
        today,
      );
    }

    // RN-FU-03
    final attempts = attemptsSinceLastResponse(application);
    if (attempts >= settings.maxAttempts) return FollowUpSuggestClose(attempts);

    final (base, offsetDays) = _baseFor(application, settings);
    return _classify(base.date.addDays(offsetDays), base, today);
  }

  /// "Acompanhamento enviado" com data estritamente posterior ao último
  /// evento de resposta (D-25, D-25b).
  static int attemptsSinceLastResponse(Application application) {
    final lastResponse = _lastResponseDate(application);
    return application.interactions
        .where(
          (i) =>
              i.type == InteractionType.followUpSent &&
              (lastResponse == null || i.date.isAfter(lastResponse)),
        )
        .length;
  }

  static LocalDate? _lastResponseDate(Application application) {
    LocalDate? latest;
    for (final interaction in application.interactions) {
      if (interaction.receivedResponse) {
        latest = latestOf(latest, interaction.date);
      }
    }
    for (final change in application.statusHistory) {
      if (change.newStatus.indicatesResponse) {
        latest = latestOf(latest, change.date);
      }
    }
    return latest;
  }

  static (FollowUpBase, int) _baseFor(
    Application application,
    FollowUpSettings settings,
  ) {
    final interval = settings.intervalDays;

    // RN-FU-04
    if (!application.hasResponse) {
      final closing = application.details.jobClosingDate;
      if (application.interactions.isEmpty && closing != null) {
        return (
          FollowUpBase(FollowUpBaseKind.jobClosing, closing),
          jobClosingOffsetDays,
        );
      }
      final lastContact = application.lastContactAt;
      if (lastContact != null) {
        return (
          FollowUpBase(FollowUpBaseKind.lastContact, lastContact),
          interval,
        );
      }
      return (
        FollowUpBase(
          FollowUpBaseKind.applicationDate,
          application.details.applicationDate,
        ),
        interval,
      );
    }

    final statusChangeDate = application.lastStatusChange.date;

    // RN-FU-05 (D-22, D-22b)
    if (application.status == ApplicationStatus.interview) {
      final interview = _latestInterviewSince(application, statusChangeDate);
      if (interview == null) {
        return (
          FollowUpBase(FollowUpBaseKind.statusChange, statusChangeDate),
          interviewThankYouDays,
        );
      }
      final latest = application.latestInteraction!;
      if (identical(latest, interview)) {
        return (
          FollowUpBase(FollowUpBaseKind.interview, interview.date),
          interviewThankYouDays,
        );
      }
      return (
        FollowUpBase(FollowUpBaseKind.lastContact, latest.date),
        interval,
      );
    }

    // RN-FU-06 e RN-FU-07 (I-3)
    final lastContact = application.lastContactAt;
    if (lastContact != null && !lastContact.isBefore(statusChangeDate)) {
      return (
        FollowUpBase(FollowUpBaseKind.lastContact, lastContact),
        interval,
      );
    }
    return (
      FollowUpBase(FollowUpBaseKind.statusChange, statusChangeDate),
      interval,
    );
  }

  /// Contato do tipo Entrevista mais recente com data igual ou posterior à
  /// mudança para Entrevista; no empate, o último registrado.
  static Interaction? _latestInterviewSince(
    Application application,
    LocalDate since,
  ) {
    Interaction? latest;
    for (final interaction in application.interactions) {
      if (interaction.type != InteractionType.interview ||
          interaction.date.isBefore(since)) {
        continue;
      }
      if (latest == null || !interaction.date.isBefore(latest.date)) {
        latest = interaction;
      }
    }
    return latest;
  }

  static FollowUpState _classify(
    LocalDate dueDate,
    FollowUpBase base,
    LocalDate today,
  ) {
    // RN-FU-08: limite inclusivo.
    return today.isBefore(dueDate)
        ? FollowUpScheduled(dueDate, base)
        : FollowUpDue(dueDate, base);
  }
}
