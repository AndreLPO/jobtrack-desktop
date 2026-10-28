import '../../../core/time/local_date.dart';
import 'application_channel.dart';
import 'application_draft.dart';
import 'interaction_type.dart';

enum ApplicationField {
  companyName,
  jobTitle,
  applicationDate,
  channel,
  channelOther,
  status,
  jobUrl,
}

enum InteractionField { date, type, nextFollowUpAt }

/// Códigos de erro; as mensagens ficam na interface (D-47).
enum ValidationCode { required, futureDate, invalidUrl, pastDate }

class FieldError<F extends Enum> {
  const FieldError(this.field, this.code);

  final F field;
  final ValidationCode code;

  @override
  bool operator ==(Object other) =>
      other is FieldError<F> && other.field == field && other.code == code;

  @override
  int get hashCode => Object.hash(field, code);

  @override
  String toString() => 'FieldError(${field.name}, ${code.name})';
}

/// RN-APP-02, RN-APP-03 e validação mínima de URL.
List<FieldError<ApplicationField>> validateApplicationDraft(
  ApplicationDraft draft, {
  required LocalDate today,
}) {
  final errors = <FieldError<ApplicationField>>[];
  void add(ApplicationField field, ValidationCode code) =>
      errors.add(FieldError(field, code));

  if (draft.companyName.trim().isEmpty) {
    add(ApplicationField.companyName, ValidationCode.required);
  }
  if (draft.jobTitle.trim().isEmpty) {
    add(ApplicationField.jobTitle, ValidationCode.required);
  }

  final applicationDate = draft.applicationDate;
  if (applicationDate == null) {
    add(ApplicationField.applicationDate, ValidationCode.required);
  } else if (applicationDate.isAfter(today)) {
    add(ApplicationField.applicationDate, ValidationCode.futureDate);
  }

  if (draft.channel == null) {
    add(ApplicationField.channel, ValidationCode.required);
  } else if (draft.channel == ApplicationChannel.other &&
      draft.channelOther.trim().isEmpty) {
    add(ApplicationField.channelOther, ValidationCode.required);
  }

  if (draft.status == null) {
    add(ApplicationField.status, ValidationCode.required);
  }

  final url = draft.jobUrl.trim();
  if (url.isNotEmpty && !isValidHttpUrl(url)) {
    add(ApplicationField.jobUrl, ValidationCode.invalidUrl);
  }

  return errors;
}

/// Contato: data obrigatória e não futura (D-18), tipo obrigatório,
/// resumo opcional (D-53) e próxima data hoje ou futura (D-54).
List<FieldError<InteractionField>> validateInteraction({
  required LocalDate? date,
  required InteractionType? type,
  required LocalDate? nextFollowUpAt,
  required LocalDate today,
}) {
  final errors = <FieldError<InteractionField>>[];
  if (date == null) {
    errors.add(
      const FieldError(InteractionField.date, ValidationCode.required),
    );
  } else if (date.isAfter(today)) {
    errors.add(
      const FieldError(InteractionField.date, ValidationCode.futureDate),
    );
  }
  if (type == null) {
    errors.add(
      const FieldError(InteractionField.type, ValidationCode.required),
    );
  }
  if (nextFollowUpAt != null && nextFollowUpAt.isBefore(today)) {
    errors.add(
      const FieldError(
        InteractionField.nextFollowUpAt,
        ValidationCode.pastDate,
      ),
    );
  }
  return errors;
}

/// Ação "Adiar": a nova data deve ser hoje ou futura (follow-ups F4).
ValidationCode? validatePostponeDate(
  LocalDate date, {
  required LocalDate today,
}) => date.isBefore(today) ? ValidationCode.pastDate : null;

bool isValidHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}
