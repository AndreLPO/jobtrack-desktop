import '../../../core/time/local_date.dart';
import 'application.dart';
import 'application_channel.dart';
import 'application_details.dart';
import 'application_status.dart';
import 'work_mode.dart';

/// Entrada bruta do formulário de candidatura, antes da validação.
class ApplicationDraft {
  /// Rascunho preenchido com os dados atuais, para edição.
  factory ApplicationDraft.fromApplication(Application application) {
    final d = application.details;
    return ApplicationDraft(
      companyName: d.companyName,
      jobTitle: d.jobTitle,
      applicationDate: d.applicationDate,
      channel: d.channel,
      channelOther: d.channelOther ?? '',
      status: application.status,
      jobUrl: d.jobUrl ?? '',
      atsName: d.atsName ?? '',
      resumeVersion: d.resumeVersion ?? '',
      jobDescription: d.jobDescription ?? '',
      jobClosingDate: d.jobClosingDate,
      workMode: d.workMode,
      city: d.city ?? '',
      contactName: d.contactName ?? '',
      salaryRange: d.salaryRange ?? '',
      notes: d.notes ?? '',
      manualNextFollowUpAt: application.manualNextFollowUpAt,
    );
  }

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

  /// Campos anuláveis recebem uma função para permitir limpar o valor
  /// (`jobClosingDate: () => null`).
  ApplicationDraft copyWith({
    String? companyName,
    String? jobTitle,
    LocalDate? Function()? applicationDate,
    ApplicationChannel? Function()? channel,
    String? channelOther,
    ApplicationStatus? Function()? status,
    String? jobUrl,
    String? atsName,
    String? resumeVersion,
    String? jobDescription,
    LocalDate? Function()? jobClosingDate,
    WorkMode? Function()? workMode,
    String? city,
    String? contactName,
    String? salaryRange,
    String? notes,
    LocalDate? Function()? manualNextFollowUpAt,
  }) {
    return ApplicationDraft(
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      applicationDate: applicationDate != null
          ? applicationDate()
          : this.applicationDate,
      channel: channel != null ? channel() : this.channel,
      channelOther: channelOther ?? this.channelOther,
      status: status != null ? status() : this.status,
      jobUrl: jobUrl ?? this.jobUrl,
      atsName: atsName ?? this.atsName,
      resumeVersion: resumeVersion ?? this.resumeVersion,
      jobDescription: jobDescription ?? this.jobDescription,
      jobClosingDate: jobClosingDate != null
          ? jobClosingDate()
          : this.jobClosingDate,
      workMode: workMode != null ? workMode() : this.workMode,
      city: city ?? this.city,
      contactName: contactName ?? this.contactName,
      salaryRange: salaryRange ?? this.salaryRange,
      notes: notes ?? this.notes,
      manualNextFollowUpAt: manualNextFollowUpAt != null
          ? manualNextFollowUpAt()
          : this.manualNextFollowUpAt,
    );
  }

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
