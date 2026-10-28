import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/core/time/week_range.dart';

void main() {
  group('WeekRange', () {
    test('CA-DSH-01: domingo 01/11/2026 → semana 26/10 a 01/11', () {
      final week = WeekRange.containing(LocalDate(2026, 11, 1));
      expect(week.start, LocalDate(2026, 10, 26));
      expect(week.end, LocalDate(2026, 11, 1));

      final dates = [
        LocalDate(2026, 10, 26),
        LocalDate(2026, 11, 1),
        LocalDate(2026, 10, 25),
      ];
      expect(dates.where(week.contains).length, 2);
    });

    test('CA-DSH-02: semana que cruza o ano', () {
      final week = WeekRange.containing(LocalDate(2026, 12, 31));
      expect(week.start, LocalDate(2026, 12, 28));
      expect(week.end, LocalDate(2027, 1, 3));
      expect(week.contains(LocalDate(2027, 1, 3)), isTrue);
      expect(week.contains(LocalDate(2027, 1, 4)), isFalse);
    });

    test('CA-DSH-03: na segunda, o domingo anterior não conta', () {
      final week = WeekRange.containing(LocalDate(2026, 10, 26));
      expect(week.start, LocalDate(2026, 10, 26));
      expect(week.contains(LocalDate(2026, 10, 25)), isFalse);
      expect(week.contains(LocalDate(2026, 10, 26)), isTrue);
    });

    test('semana que cruza o mês', () {
      final week = WeekRange.containing(LocalDate(2026, 3, 2));
      expect(week.start, LocalDate(2026, 3, 2));
      final previous = WeekRange.containing(LocalDate(2026, 3, 1));
      expect(previous.start, LocalDate(2026, 2, 23));
      expect(previous.end, LocalDate(2026, 3, 1));
    });
  });
}
