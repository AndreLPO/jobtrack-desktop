import '../../../core/time/local_date.dart';
import '../../settings/models/follow_up_settings.dart';
import 'application.dart';
import 'application_channel.dart';
import 'application_status.dart';
import 'follow_up_policy.dart';

enum ApplicationSort { applicationDate, updatedAt, nextFollowUp }

/// Filtros da listagem (RF-04). Todos combinados com "E" lógico; um
/// conjunto vazio significa "sem filtro" naquele critério.
class ApplicationFilter {
  const ApplicationFilter({
    this.text = '',
    this.statuses = const {},
    this.channels = const {},
    this.from,
    this.to,
    this.onlyNeedingFollowUp = false,
  });

  final String text;
  final Set<ApplicationStatus> statuses;
  final Set<ApplicationChannel> channels;

  /// Período da candidatura, inclusivo nas duas pontas.
  final LocalDate? from;
  final LocalDate? to;

  /// Vencidas ou "sugerido encerrar" (D-59).
  final bool onlyNeedingFollowUp;

  bool get isEmpty =>
      text.trim().isEmpty &&
      statuses.isEmpty &&
      channels.isEmpty &&
      from == null &&
      to == null &&
      !onlyNeedingFollowUp;

  ApplicationFilter copyWith({
    String? text,
    Set<ApplicationStatus>? statuses,
    Set<ApplicationChannel>? channels,
    LocalDate? Function()? from,
    LocalDate? Function()? to,
    bool? onlyNeedingFollowUp,
  }) {
    return ApplicationFilter(
      text: text ?? this.text,
      statuses: statuses ?? this.statuses,
      channels: channels ?? this.channels,
      from: from != null ? from() : this.from,
      to: to != null ? to() : this.to,
      onlyNeedingFollowUp: onlyNeedingFollowUp ?? this.onlyNeedingFollowUp,
    );
  }
}

/// Filtra e ordena (D-49: consultas no domínio, sobre a lista
/// carregada).
List<Application> queryApplications(
  Iterable<Application> applications, {
  required ApplicationFilter filter,
  required ApplicationSort sort,
  required FollowUpSettings settings,
  required LocalDate today,
}) {
  final text = normalizeForSearch(filter.text.trim());
  final states = <String, FollowUpState>{
    for (final a in applications)
      a.id: FollowUpPolicy.evaluate(a, settings, today),
  };

  bool matches(Application a) {
    final d = a.details;
    if (text.isNotEmpty &&
        !normalizeForSearch(d.companyName).contains(text) &&
        !normalizeForSearch(d.jobTitle).contains(text)) {
      return false;
    }
    if (filter.statuses.isNotEmpty && !filter.statuses.contains(a.status)) {
      return false;
    }
    if (filter.channels.isNotEmpty && !filter.channels.contains(d.channel)) {
      return false;
    }
    if (filter.from != null && d.applicationDate.isBefore(filter.from!)) {
      return false;
    }
    if (filter.to != null && d.applicationDate.isAfter(filter.to!)) {
      return false;
    }
    if (filter.onlyNeedingFollowUp && !needsFollowUp(states[a.id]!)) {
      return false;
    }
    return true;
  }

  int byNewestApplication(Application a, Application b) {
    final byDate = b.details.applicationDate.compareTo(
      a.details.applicationDate,
    );
    return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
  }

  int compare(Application a, Application b) => switch (sort) {
    ApplicationSort.applicationDate => byNewestApplication(a, b),
    ApplicationSort.updatedAt => b.updatedAt.compareTo(a.updatedAt),
    ApplicationSort.nextFollowUp => _compareDue(
      followUpDueDate(states[a.id]!),
      followUpDueDate(states[b.id]!),
      () => byNewestApplication(a, b),
    ),
  };

  return applications.where(matches).toList()..sort(compare);
}

/// Vencida ou "sugerido encerrar" (D-59).
bool needsFollowUp(FollowUpState state) =>
    state is FollowUpDue || state is FollowUpSuggestClose;

/// Data sugerida, se houver.
LocalDate? followUpDueDate(FollowUpState state) => switch (state) {
  FollowUpDue(:final dueDate) => dueDate,
  FollowUpScheduled(:final dueDate) => dueDate,
  _ => null,
};

/// Datas mais próximas primeiro; sem data no fim (D-59).
int _compareDue(LocalDate? a, LocalDate? b, int Function() tieBreak) {
  if (a == null && b == null) return tieBreak();
  if (a == null) return 1;
  if (b == null) return -1;
  final byDate = a.compareTo(b);
  return byDate != 0 ? byDate : tieBreak();
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// Minúsculas e sem acentos, para busca (D-56).
String normalizeForSearch(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}
