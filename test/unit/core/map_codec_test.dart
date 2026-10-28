import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/database/map_codec.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';

void main() {
  group('datas', () {
    test('LocalDate ida e volta', () {
      final date = LocalDate(2028, 2, 29);
      expect(MapCodec.encodeDate(date), '2028-02-29');
      expect(MapCodec.decodeDate('2028-02-29', 'f'), date);
    });

    test('recusa data inexistente, formato errado e tipo errado', () {
      for (final value in [
        '2027-02-29',
        '2026-13-01',
        '28/10/2026',
        20261028,
      ]) {
        expect(
          () => MapCodec.decodeDate(value, 'f'),
          throwsFormatException,
          reason: '$value',
        );
      }
    });

    test('DateTime local ida e volta (gravado em UTC)', () {
      final now = DateTime(2026, 10, 28, 9, 30, 15, 123, 456);
      final encoded = MapCodec.encodeDateTime(now);
      expect(encoded, endsWith('Z'));
      expect(MapCodec.decodeDateTime(encoded, 'f'), now);
    });

    test('recusa data/hora inválida', () {
      expect(
        () => MapCodec.decodeDateTime('ontem', 'f'),
        throwsFormatException,
      );
    });
  });

  group('enums', () {
    test('gravados e lidos pelo nome', () {
      expect(
        MapCodec.decodeEnum(ApplicationStatus.values, 'interview', 'f'),
        ApplicationStatus.interview,
      );
    });

    test('nome desconhecido é FormatException', () {
      expect(
        () => MapCodec.decodeEnum(ApplicationStatus.values, 'hired', 'f'),
        throwsFormatException,
      );
    });

    test('opcional aceita nulo', () {
      expect(
        MapCodec.decodeOptionalEnum(ApplicationStatus.values, null, 'f'),
        isNull,
      );
    });
  });

  group('tipos básicos', () {
    test('texto, inteiro, booleano e lista exigem o tipo certo', () {
      expect(() => MapCodec.requireString(1, 'f'), throwsFormatException);
      expect(() => MapCodec.requireString(null, 'f'), throwsFormatException);
      expect(() => MapCodec.requireInt('1', 'f'), throwsFormatException);
      expect(() => MapCodec.requireBool(0, 'f'), throwsFormatException);
      expect(() => MapCodec.requireMapList([1], 'f'), throwsFormatException);
      expect(MapCodec.optionalString(null, 'f'), isNull);
      expect(MapCodec.requireMapList([], 'f'), isEmpty);
    });
  });
}
