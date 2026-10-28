import '../../../core/time/local_date.dart';
import 'application_status.dart';

/// Registro de uma mudança de status (RN-06). Na criação da candidatura,
/// [previousStatus] é nulo.
class StatusChange {
  const StatusChange({
    required this.id,
    required this.previousStatus,
    required this.newStatus,
    required this.changedAt,
    this.note,
  });

  final String id;
  final ApplicationStatus? previousStatus;
  final ApplicationStatus newStatus;
  final DateTime changedAt;
  final String? note;

  /// Data local da mudança.
  LocalDate get date => LocalDate.fromDateTime(changedAt);
}
