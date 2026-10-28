import '../../../core/time/local_date.dart';
import 'application_channel.dart';
import 'application_details.dart';
import 'application_status.dart';
import 'work_mode.dart';

/// Entrada bruta do formulário de candidatura, antes da validação.
class ApplicationDraft {
  const ApplicationDraft({
    this.companyName = '',
    this.jobTitle = '',
    this.applicationDate,
    this.channel,
    this.channelOther = '',
    this.status,
    this.jobUrl = '',
    this.atsName = '',
    this.resumeVersion = '',
    this.jobDescription = '',
    this.jobClosingDate,
    this.workMode,
    this.city = '',
    this.contactName = '',
    this.salaryRange = '',
    this.notes = '',
    this.manualNextFollowUpAt,
  });

  final String companyName;
  final String jobTitle;
  final LocalDate? applicationDate;
  final ApplicationChannel? channel;
  final String channelOther;
  final ApplicationStatus? status;
  final String jobUrl;
  final String atsName;
  final String resumeVersion;
  final String jobDescription;
  final LocalDate? jobClosingDate;
  final WorkMode? workMode;
  final String city;
  final String contactName;
  final String salaryRange;
  final String notes;
  final LocalDate? manualNextFollowUpAt;

  /// Converte para dados normalizados. Só deve ser chamado depois de
  /// `validateApplicationDraft` não retornar erros.
  ApplicationDetails toDetails() {
    return ApplicationDetails(
      companyName: companyName.trim(),
      jobTitle: jobTitle.trim(),
      applicationDate: applicationDate!,
      channel: channel!,
      channelOther: channel == ApplicationChannel.other
          ? normalizeOptional(channelOther)
          : null,
      jobUrl: normalizeOptional(jobUrl),
      atsName: normalizeOptional(atsName),
      resumeVersion: normalizeOptional(resumeVersion),
      jobDescription: normalizeOptional(jobDescription),
      jobClosingDate: jobClosingDate,
      workMode: workMode,
      city: normalizeOptional(city),
      contactName: normalizeOptional(contactName),
      salaryRange: normalizeOptional(salaryRange),
      notes: normalizeOptional(notes),
    );
  }
}

/// Texto opcional: sem espaços nas pontas; vazio vira `null`.
String? normalizeOptional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
