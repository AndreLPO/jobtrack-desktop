import '../time/local_date.dart';

/// Conversões entre valores do domínio e valores simples gravados no
/// Hive (D-03). Leituras inválidas lançam [FormatException], que o
/// repositório trata como registro ilegível (D-48).
abstract final class MapCodec {
  static String encodeDate(LocalDate date) => date.toString();

  static String encodeDateTime(DateTime dateTime) =>
      dateTime.toUtc().toIso8601String();

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static LocalDate decodeDate(Object? value, String field) {
    final match = _datePattern.firstMatch(_string(value, field));
    if (match == null) {
      throw FormatException('Data inválida em "$field"', value);
    }
    final date = LocalDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    if (date.toString() != value) {
      throw FormatException('Data inexistente em "$field"', value);
    }
    return date;
  }

  static LocalDate? decodeOptionalDate(Object? value, String field) =>
      value == null ? null : decodeDate(value, field);

  /// Devolve o instante no fuso local, como os valores criados pelo app.
  static DateTime decodeDateTime(Object? value, String field) {
    final parsed = DateTime.tryParse(_string(value, field));
    if (parsed == null) {
      throw FormatException('Data/hora inválida em "$field"', value);
    }
    return parsed.toLocal();
  }

  static T decodeEnum<T extends Enum>(
    List<T> values,
    Object? value,
    String field,
  ) {
    final name = _string(value, field);
    for (final candidate in values) {
      if (candidate.name == name) return candidate;
    }
    throw FormatException('Valor desconhecido em "$field"', value);
  }

  static T? decodeOptionalEnum<T extends Enum>(
    List<T> values,
    Object? value,
    String field,
  ) => value == null ? null : decodeEnum(values, value, field);

  static String requireString(Object? value, String field) =>
      _string(value, field);

  static String? optionalString(Object? value, String field) =>
      value == null ? null : _string(value, field);

  static bool requireBool(Object? value, String field) {
    if (value is bool) return value;
    throw FormatException('Booleano esperado em "$field"', value);
  }

  static int requireInt(Object? value, String field) {
    if (value is int) return value;
    throw FormatException('Inteiro esperado em "$field"', value);
  }

  static List<Map<dynamic, dynamic>> requireMapList(
    Object? value,
    String field,
  ) {
    if (value is List && value.every((item) => item is Map)) {
      return value.cast<Map<dynamic, dynamic>>();
    }
    throw FormatException('Lista de registros esperada em "$field"', value);
  }

  static String _string(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Texto esperado em "$field"', value);
  }
}
