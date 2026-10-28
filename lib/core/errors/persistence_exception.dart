enum PersistenceOperation { read, write }

/// Falha de leitura ou gravação dos dados locais (RN-08). Os controllers
/// só conhecem este tipo, nunca os erros do Hive.
class PersistenceException implements Exception {
  const PersistenceException(this.operation, this.cause, [this.stackTrace]);

  final PersistenceOperation operation;
  final Object cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'PersistenceException(${operation.name}): $cause';
}
