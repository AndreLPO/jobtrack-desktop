import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/formatting/date_format.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';

void main() {
  test('formata como dd/MM/yyyy', () {
    expect(formatDate(LocalDate(2026, 3, 5)), '05/03/2026');
    expect(formatDate(LocalDate(2026, 12, 31)), '31/12/2026');
  });

  test('lê dd/MM/yyyy, aceitando dia e mês com 1 dígito', () {
    expect(parseDate('05/03/2026'), LocalDate(2026, 3, 5));
    expect(parseDate('5/3/2026'), LocalDate(2026, 3, 5));
    expect(parseDate(' 29/02/2028 '), LocalDate(2028, 2, 29));
  });

  test('CA-E3-06: recusa datas inexistentes e formatos errados', () {
    for (final text in [
      '31/02/2026',
      '29/02/2027',
      '32/01/2026',
      '01/13/2026',
      '2026-03-05',
      '05/03/26',
      '',
      'ontem',
    ]) {
      expect(parseDate(text), isNull, reason: text);
    }
  });
}
