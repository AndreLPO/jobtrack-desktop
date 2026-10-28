/// Data de calendário sem hora nem fuso (D-18).
///
/// A aritmética usa `DateTime.utc` para não sofrer com horário de verão.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(int year, int month, int day)
    : this._fromUtc(DateTime.utc(year, month, day));

  LocalDate._fromUtc(DateTime utc)
    : year = utc.year,
      month = utc.month,
      day = utc.day;

  /// Data local (calendário do dispositivo) do instante informado.
  factory LocalDate.fromDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return LocalDate(local.year, local.month, local.day);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = segunda-feira ... 7 = domingo.
  int get weekday => _utc.weekday;

  LocalDate addDays(int days) => LocalDate(year, month, day + days);

  /// Dias corridos de `this` até [other] (negativo se [other] for anterior).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;

  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Meia-noite local deste dia.
  DateTime toDateTime() => DateTime(year, month, day);

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Formato ISO (yyyy-MM-dd), útil em logs e testes.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// A mais recente entre duas datas, aceitando nulos.
LocalDate? latestOf(LocalDate? a, LocalDate? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}
