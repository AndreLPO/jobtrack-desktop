import 'local_date.dart';

/// Semana local de segunda a domingo (RN-02, RN-03).
class WeekRange {
  WeekRange.containing(LocalDate date)
    : start = date.addDays(1 - date.weekday),
      end = date.addDays(7 - date.weekday);

  /// Segunda-feira.
  final LocalDate start;

  /// Domingo (inclusivo).
  final LocalDate end;

  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);
}
