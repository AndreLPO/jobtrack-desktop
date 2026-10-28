# Tasks — applications / Etapa 3

- [x] T1 — `flutter_localizations` (SDK) com `locale` pt_BR (D-06).
- [x] T2 — `Clock`, `formatDate`/`parseDate` (dd/MM/yyyy),
  `ApplicationDraft.copyWith`/`fromApplication`.
- [x] T3 — `ApplicationsController`: carregar ordenado, vazio, erro,
  ilegíveis e excluir só depois de gravar.
- [x] T4 — `ApplicationFormController`: cadastro e edição, validação ao
  vivo depois da 1ª tentativa, datas inválidas, aviso de duplicidade,
  "salvando", falha de gravação e "não encontrada".
- [x] T5 — Rótulos pt-BR, `StatusBadge`, `DateField`, `MessageView`,
  `WarningBanner`, `showFeedback`/`confirm` e tokens de status e aviso.
- [x] T6 — Listagem (tabela preguiçosa, coluna Canal oculta abaixo de
  800px, menu "⋮") e formulário (seções, 1 ou 2 colunas, status só
  para leitura na edição).
- [x] T7 — Rotas `/applications/new` e `/applications/:id/edit`; a
  navegação lateral usa `offAllNamed` e pergunta antes de descartar
  alterações (D-52).
- [x] T8 — Testes: formato de data, draft, controllers, fluxo de
  widgets (lista, exclusão, formulário, duplicidade, edição, data
  inválida, falha, descartar) e `InitialBinding` com Hive real.
- [x] T9 — Verificação em 2026-10-28:
  - `dart format .`: sem pendências.
  - `flutter analyze`: "No issues found!".
  - `flutter test`: 154 testes, "All tests passed!".
  - `flutter build windows --debug`: build concluído.
  - O app abriu com a janela "JobTrack".
  - A interface foi verificada pelos testes de widget, não por
    inspeção visual.

## Ajustes durante a implementação

- `Get.toNamed<bool>` falha com as rotas do GetX (`GetPageRoute<dynamic>`).
  Agora se usa `Get.toNamed` sem tipo e se compara o resultado com
  `true`.
- O botão "Cancelar" consulta `isDirty` diretamente, em vez de depender
  do `PopScope`, que só é atualizado no frame seguinte.
- Valores iniciais do cadastro: data de hoje e status "Aplicada". São
  conveniências de interface, ambas editáveis.
