import 'local_date.dart';

/// Fonte do instante atual, injetável nos testes.
typedef Clock = DateTime Function();

extension ClockToday on Clock {
  /// Data local de hoje.
  LocalDate today() => LocalDate.fromDateTime(this());
}
