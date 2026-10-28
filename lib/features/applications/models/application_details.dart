import '../../../core/time/local_date.dart';
import 'application_channel.dart';
import 'work_mode.dart';

/// Dados descritivos da candidatura, já validados e normalizados
/// (textos sem espaços nas pontas; opcionais vazios viram `null`).
class ApplicationDetails {
  const ApplicationDetails({
    required this.companyName,
    required this.jobTitle,
    required this.applicationDate,
    required this.channel,
    this.channelOther,
    this.jobUrl,
    this.atsName,
    this.resumeVersion,
    this.jobDescription,
    this.jobClosingDate,
    this.workMode,
    this.city,
    this.contactName,
    this.salaryRange,
    this.notes,
  });

  final String companyName;
  final String jobTitle;
  final LocalDate applicationDate;
  final ApplicationChannel channel;

  /// Preenchido somente quando [channel] é `other`.
  final String? channelOther;
  final String? jobUrl;
  final String? atsName;
  final String? resumeVersion;
  final String? jobDescription;

  /// Encerramento da vaga (D-26); pode ser futuro.
  final LocalDate? jobClosingDate;
  final WorkMode? workMode;
  final String? city;

  /// Recrutador ou pessoa que fez a indicação.
  final String? contactName;
  final String? salaryRange;
  final String? notes;
}
