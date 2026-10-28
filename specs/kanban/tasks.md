# Tasks — kanban / Etapa 10

- [x] T1 — Domínio `kanban.dart`:
  - `KanbanColumn`;
  - `kanbanColumns` (5 ativas + Encerradas, K-02);
  - `visibleKanbanColumns` (RN-KB-04);
  - `groupForKanban` (RN-KB-01/05).
- [x] T2 — Preferência `ApplicationsViewMode`: mapper (`schemaVersion`
  1), chave `applicationsView` na box `settings` e métodos novos no
  `SettingsRepository` (K-04).
- [x] T3 — `ApplicationsController`:
  - `viewMode` e `setViewMode` (gravar a preferência é melhor esforço);
  - `moveTo` → `moved | unchanged | failed`, que atualiza a lista só
    depois de gravar (RN-KB-02/03).
- [x] T4 — `KanbanBoard`:
  - rolagem horizontal com colunas de 260px;
  - `DragTarget` com destaque por borda, sem sombra;
  - cartões `Draggable` com empresa, vaga, data, badge (só em
    Encerradas) e indicador de acompanhamento;
  - menu "Mover para…" e "Abrir detalhes";
  - diálogo "Encerrar como" ao soltar em Encerradas.
- [x] T5 — Página: `SegmentedButton` "Lista | Quadro" na barra, e o
  aviso "movida para…" com "Desfazer", que registra a mudança inversa
  (K-03). `showFeedback` passou a aceitar uma ação.
- [x] T6 — Testes:
  - domínio;
  - persistência com Hive real;
  - controller (mover, mesmo status, falha, desfazer, preferência);
  - widgets: alternância e preferência, colunas e contagem, arrastar e
    desfazer, soltar na mesma coluna, falha, Encerradas, "Mover para…",
    filtro de status, abrir detalhes e rolagem em 960px.
- [x] T7 — Verificação em 2026-10-28:
  - `dart format .`: sem pendências.
  - `flutter analyze`: "No issues found!".
  - `flutter test`: 273 testes, "All tests passed!".
  - Auditoria por grep: sem gradiente nem sombra, cores só nos tokens,
    Hive só na camada de dados.
