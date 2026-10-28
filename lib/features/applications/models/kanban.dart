import 'application.dart';
import 'application_status.dart';

/// Coluna do quadro Kanban (K-02). Uma coluna com um único status recebe
/// esse status ao soltar; a coluna agrupada exige escolher qual.
class KanbanColumn {
  const KanbanColumn(this.statuses);

  final List<ApplicationStatus> statuses;

  bool get isGrouped => statuses.length > 1;

  /// Status aplicado ao soltar, ou `null` se for preciso escolher.
  ApplicationStatus? get dropStatus => isGrouped ? null : statuses.single;

  bool contains(ApplicationStatus status) => statuses.contains(status);
}

/// As 5 colunas ativas, na ordem do processo, mais "Encerradas" (K-02).
final List<KanbanColumn> kanbanColumns = List.unmodifiable([
  for (final status in ApplicationStatus.values.where((s) => s.isActive))
    KanbanColumn([status]),
  KanbanColumn(ApplicationStatus.values.where((s) => s.isClosed).toList()),
]);

/// Colunas exibidas conforme o filtro de status da barra (RN-KB-04).
List<KanbanColumn> visibleKanbanColumns(Set<ApplicationStatus> statusFilter) {
  if (statusFilter.isEmpty) return kanbanColumns;
  return [
    for (final column in kanbanColumns)
      if (column.statuses.any(statusFilter.contains)) column,
  ];
}

/// Distribui as candidaturas (já filtradas e ordenadas) pelas colunas,
/// preservando a ordem. Cada uma aparece em exatamente uma coluna
/// (RN-KB-01).
List<List<Application>> groupForKanban(
  Iterable<Application> applications,
  List<KanbanColumn> columns,
) {
  final groups = [for (final _ in columns) <Application>[]];
  for (final application in applications) {
    final index = columns.indexWhere((c) => c.contains(application.status));
    if (index >= 0) groups[index].add(application);
  }
  return groups;
}
