import '../models/application.dart';

/// Resultado da leitura de todas as candidaturas. Registros que não
/// puderam ser lidos não impedem a leitura dos demais (D-48).
class ApplicationsSnapshot {
  const ApplicationsSnapshot({
    required this.applications,
    this.unreadableIds = const [],
  });

  final List<Application> applications;

  /// Chaves dos registros ilegíveis; eles continuam intactos na base.
  final List<String> unreadableIds;
}

/// Acesso às candidaturas (PROJECT.md §5.2). Só criar, ler, atualizar e
/// excluir; filtros ficam no domínio (D-49).
///
/// Todas as operações lançam `PersistenceException` em caso de falha.
abstract interface class ApplicationRepository {
  Future<ApplicationsSnapshot> getAll();

  /// `null` se não existir.
  Future<Application?> getById(String id);

  /// Cria ou atualiza a candidatura inteira, com histórico e contatos.
  Future<void> save(Application application);

  /// Remove a candidatura com histórico e contatos (D-17).
  Future<void> delete(String id);
}
