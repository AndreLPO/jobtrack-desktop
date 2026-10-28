# Plano — Quadro Kanban (Etapa 10)

- **Status:** Implementado (2026-10-28). As decisões K-01 a K-04 seguem
  as recomendações abaixo. Ver `tasks.md`.

## Recomendações para as decisões

| Decisão | Recomendação | Motivo |
|---------|--------------|--------|
| K-01 | Alternância "Lista \| Quadro" dentro de Candidaturas | Reaproveita busca, filtros e ordenação sem duplicar estado, e mantém um controller por página (§5.3). |
| K-02 | 5 colunas ativas + "Encerradas" agrupada | 8 colunas de 260px exigem cerca de 2.100px. Os encerrados são o "arquivo" do quadro, e a coluna agrupada mostra o badge do status específico em cada cartão. |
| K-03 | Mudar na hora + "Desfazer" no aviso | Arrastar precisa ser rápido. O desfazer registra a mudança inversa, o que mantém o histórico honesto (D-55). |
| K-04 | Lembrar o modo | É a preferência de quem usa o quadro no dia a dia. Exige gravar uma chave pequena em `settings`. |

## Abordagem

1. **Domínio puro** (`applications/models/kanban.dart`):
   - `KanbanColumn` (id, título, status que contém e status de
     destino ao soltar);
   - `kanbanColumns()`: a definição das colunas conforme K-02;
   - `groupForKanban(applications, columns)`, que usa a lista já
     filtrada e ordenada por `queryApplications`.
2. **Controller (`ApplicationsController`)**, que continua sendo um por
   página:
   - `viewMode` (lista ou quadro);
   - `moveTo(application, status)`: usa `Application.changeStatus` e
     `repository.save`, e só atualiza `applications` depois de gravar;
   - `undoMove(...)`: aplica a mudança inversa (K-03).

   A preferência do modo é lida e gravada pelo `SettingsRepository`
   (K-04), com uma chave nova `applicationsView` e mapper com
   `schemaVersion` 1. O padrão é "Lista".
3. **View:**
   - `SegmentedButton` "Lista | Quadro" na barra;
   - `KanbanBoard`: `Scrollbar` + `ListView` horizontal de colunas com
     260px de largura;
   - cada coluna é um `DragTarget<Application>`, com cabeçalho (título
     e contagem) e `ListView` vertical preguiçoso de cartões
     `Draggable` (no desktop o arrastar começa com o mouse; não é
     preciso pressionar e segurar);
   - destaque discreto da coluna alvo, com borda na cor de destaque,
     sem sombra;
   - o cartão usa os tokens existentes, `StatusBadge` (só na coluna
     agrupada) e `FollowUpIndicator`, e tem menu "⋮" com "Mover para…"
     e "Abrir detalhes";
   - "Encerradas" (K-02): ao soltar, um menu pequeno pergunta "Reprovada
     / Desisti / Encerrada sem resposta".
4. **Feedback:** "Movida para Entrevista." com a ação "Desfazer". Em
   falha: "Não foi possível mover. Tente novamente.", e o cartão
   continua na coluna de origem.

## Arquivos

```text
lib/features/applications/models/kanban.dart
lib/features/applications/viewmodels/applications_controller.dart   (+ viewMode, moveTo, undoMove)
lib/features/applications/views/kanban_board.dart
lib/features/applications/views/applications_page.dart              (alternância)
lib/features/applications/views/applications_toolbar.dart           (SegmentedButton)
lib/features/settings/repositories/*                                (preferência, se K-04)
test/unit/applications/kanban_test.dart
test/viewmodels/applications_controller_test.dart                   (+ mover, desfazer, falha)
test/widget/kanban_board_test.dart
```

## Testes

- **Unitários:** agrupamento (cada candidatura em uma coluna, ordem
  preservada, coluna "Encerradas"), definição das colunas.
- **Controller:**
  - mover grava o `StatusChange` e atualiza a lista;
  - mover para o mesmo status não grava;
  - falha mantém o status;
  - desfazer registra a mudança inversa;
  - modo lembrado.
- **Widget:**
  - arrastar e soltar entre colunas (`tester.drag`) — CA-KB-02;
  - soltar na mesma coluna — CA-KB-03;
  - falha — CA-KB-04;
  - "Mover para…" — CA-KB-05;
  - filtros e colunas — CA-KB-06;
  - coluna vazia aceita cartões — CA-KB-09;
  - rolagem em 960px — CA-KB-08.

## Riscos

- **Arrastar em teste de widget:** precisa de gestos com pontos
  intermediários. Já está previsto em `tester.timedDrag`.
- **Muitas candidaturas em uma coluna:** a lista vertical é preguiçosa,
  o que basta para uso individual.
- **Atalho de teclado para arrastar:** fora do escopo. O menu "Mover
  para…" cobre a acessibilidade.
