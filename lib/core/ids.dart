import 'package:uuid/uuid.dart';

/// Gera identificadores únicos e estáveis (RN-01). Injetável nos testes.
typedef IdGenerator = String Function();

String generateId() => const Uuid().v4();
