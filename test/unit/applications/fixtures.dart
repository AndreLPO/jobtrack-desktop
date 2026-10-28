import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/models/application_channel.dart';
import 'package:jobtrack_desktop/features/applications/models/application_details.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/applications/models/status_change.dart';

var _sequence = 0;

String nextId() => 'id-${_sequence++}';

/// Data em 2026, para testes curtos.
LocalDate dateOf(int month, int day) => LocalDate(2026, month, day);

/// Meio-dia local do dia, para não depender de limites de fuso.
DateTime atNoon(LocalDate date) =>
    DateTime(date.year, date.month, date.day, 12);

ApplicationDetails buildDetails({
  String companyName = 'Acme',
  String jobTitle = 'Dev Flutter',
  LocalDate? applicationDate,
  LocalDate? jobClosingDate,
}) {
  return ApplicationDetails(
    companyName: companyName,
    jobTitle: jobTitle,
    applicationDate: applicationDate ?? LocalDate(2026, 10, 1),
    channel: ApplicationChannel.linkedIn,
    jobClosingDate: jobClosingDate,
  );
}

/// Monta uma candidatura com histórico controlado.
///
/// O status inicial é registrado na [applicationDate]; cada item de
/// [statusChanges] é uma mudança posterior. O status final é o da última
/// mudança.
Application buildApplication({
  String? id,
  String companyName = 'Acme',
  String jobTitle = 'Dev Flutter',
  LocalDate? applicationDate,
  ApplicationStatus initialStatus = ApplicationStatus.applied,
  List<(ApplicationStatus, LocalDate)> statusChanges = const [],
  List<Interaction> interactions = const [],
  LocalDate? manualNextFollowUpAt,
  LocalDate? jobClosingDate,
}) {
  final appliedOn = applicationDate ?? LocalDate(2026, 10, 1);
  final history = <StatusChange>[
    StatusChange(
      id: nextId(),
      previousStatus: null,
      newStatus: initialStatus,
      changedAt: atNoon(appliedOn),
    ),
  ];
  for (final (status, date) in statusChanges) {
    history.add(
      StatusChange(
        id: nextId(),
        previousStatus: history.last.newStatus,
        newStatus: status,
        changedAt: atNoon(date),
      ),
    );
  }
  return Application(
    id: id ?? nextId(),
    details: buildDetails(
      companyName: companyName,
      jobTitle: jobTitle,
      applicationDate: appliedOn,
      jobClosingDate: jobClosingDate,
    ),
    status: history.last.newStatus,
    manualNextFollowUpAt: manualNextFollowUpAt,
    createdAt: atNoon(appliedOn),
    updatedAt: atNoon(appliedOn),
    statusHistory: history,
    interactions: interactions,
  );
}

Interaction contact(
  LocalDate date,
  InteractionType type, {
  bool response = false,
  LocalDate? nextFollowUpAt,
}) {
  return Interaction(
    id: nextId(),
    date: date,
    type: type,
    summary: 'resumo',
    receivedResponse: response,
    nextFollowUpAt: nextFollowUpAt,
  );
}
