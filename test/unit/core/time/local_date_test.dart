import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';

void main() {
  group('LocalDate', () {
    test('normaliza componentes fora da faixa', () {
      expect(LocalDate(2026, 12, 32), LocalDate(2027, 1, 1));
    });

    test('addDays cruza mês e ano', () {
      expect(LocalDate(2026, 10, 30).addDays(3), LocalDate(2026, 11, 2));
      expect(LocalDate(2026, 12, 28).addDays(7), LocalDate(2027, 1, 4));
      expect(LocalDate(2027, 1, 2).addDays(-5), LocalDate(2026, 12, 28));
    });

    test('respeita 29/02 em ano bissexto e não bissexto', () {
      expect(LocalDate(2028, 2, 25).addDays(4), LocalDate(2028, 2, 29));
      expect(LocalDate(2027, 2, 25).addDays(4), LocalDate(2027, 3, 1));
    });

    test('daysUntil é positivo, zero ou negativo', () {
      final a = LocalDate(2026, 12, 28);
      expect(a.daysUntil(LocalDate(2027, 1, 4)), 7);
      expect(a.daysUntil(a), 0);
      expect(a.daysUntil(LocalDate(2026, 12, 25)), -3);
    });

    test('weekday: 1 = segunda, 7 = domingo', () {
      expect(LocalDate(2026, 10, 26).weekday, DateTime.monday);
      expect(LocalDate(2026, 11, 1).weekday, DateTime.sunday);
    });

    test('fromDateTime ignora a hora', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 28, 23, 59)),
        LocalDate(2026, 10, 28),
      );
    });

    test('igualdade, ordem e toString', () {
      expect(LocalDate(2026, 1, 5), LocalDate(2026, 1, 5));
      expect(LocalDate(2026, 1, 5).isBefore(LocalDate(2026, 1, 6)), isTrue);
      expect(LocalDate(2026, 1, 5).toString(), '2026-01-05');
    });

    test('latestOf aceita nulos', () {
      final a = LocalDate(2026, 1, 1);
      final b = LocalDate(2026, 2, 1);
      expect(latestOf(a, b), b);
      expect(latestOf(null, a), a);
      expect(latestOf(a, null), a);
      expect(latestOf(null, null), isNull);
    });
  });
}
