import '../time/local_date.dart';

/// Formato de exibição e digitação de datas: dd/MM/yyyy (D-06).
String formatDate(LocalDate date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year.toString().padLeft(4, '0')}';

final _pattern = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');

/// `null` se o texto não for uma data existente em dd/MM/yyyy
/// (ex.: 31/02/2026).
LocalDate? parseDate(String text) {
  final match = _pattern.firstMatch(text.trim());
  if (match == null) return null;
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final year = int.parse(match[3]!);
  final date = LocalDate(year, month, day);
  if (date.day != day || date.month != month || date.year != year) {
    return null;
  }
  return date;
}

/// Data e hora local: dd/MM/yyyy HH:mm.
String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${formatDate(LocalDate.fromDateTime(local))} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
