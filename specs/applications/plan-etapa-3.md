# Plano — Etapa 3: Candidaturas (listagem + formulário)

- **Status:** Implementado (2026-10-28). Decisões D-06, D-51 e D-52; ver `tasks-etapa-3.md`.
- **Referências:** `specs/applications/spec.md` (F1, F2, F5, F6, §7–§9,
  CA-APP-01 a 04, 11, 16, 17); PROJECT.md §7, §9; decisões D-06, D-13,
  D-47, D-48; `specs/domain/tasks.md` (pontos para revisar).

## Objetivo

Primeiro fluxo de ponta a ponta: cadastrar, listar, editar e excluir
candidaturas, gravando no Hive e tratando os estados de carregando,
vazio, erro e sucesso.

## Fora desta etapa

- **Página de detalhes** (histórico, alterar status, registrar
  contato): Etapa 4. Até lá, clicar na linha abre a edição.
- **Busca, filtros e ordenação** (Etapa 5). A lista fica fixa por data
  da candidatura, da mais recente para a mais antiga.
- **Indicador e filtro de acompanhamento** na listagem: Etapa 7.
- **Mudança de status no formulário de edição** (F2/F3): o status só é
  escolhido no cadastro. Na edição ele aparece só para leitura, e a
  mudança fica para a Etapa 4.

## Abordagem

1. **Idioma e datas (D-06).**
   - Interface em pt-BR e datas `dd/MM/yyyy`.
   - Adicionar `flutter_localizations`, que vem com o próprio Flutter
     SDK (não é pacote do pub.dev), com `locale: pt_BR`. Isso traduz o
     seletor de data e os textos padrão do Material (OK, Cancelar).
   - Formatação e leitura de `dd/MM/yyyy` com uma função própria, sem
     usar o `intl` diretamente.
2. **Rótulos e mensagens.** Os textos em pt-BR dos enums e dos erros de
   validação ficam em `features/applications/views/labels.dart`. O
   domínio continua só com códigos (D-47).
3. **Clock.** `typedef Clock = DateTime Function()`, com `DateTime.now`
   como padrão. Os controllers recebem o `Clock` pelo construtor, e os
   testes injetam uma data fixa.
4. **Rotas.**
   - `/applications/new`: cadastro.
   - `/applications/:id/edit`: edição.

   As duas usam o `ApplicationFormController`, com binding próprio. A
   navegação lateral passa a usar `Get.offAllNamed`, para não acumular
   páginas na pilha. Ao voltar do formulário, a listagem recarrega e
   mostra "Candidatura salva".
5. **`ApplicationsController`.**
   - Estado: `loading | ready | error`, a lista de candidaturas e a
     quantidade de registros ilegíveis (D-48).
   - Ações:
     - `load()`, também chamado pelo "Tentar novamente";
     - `delete(id)`, que remove da lista só depois de a exclusão ser
       gravada (RN-APP-13).
6. **`ApplicationFormController`.**
   - Mantém o `ApplicationDraft` e os erros por campo.
   - `save({confirmDuplicate})` devolve `saved`, `invalid`,
     `duplicateWarning` ou `failed`.
   - Fluxo: valida → verifica duplicidade (aviso com "Salvar mesmo
     assim") → grava → sucesso. O botão fica desabilitado durante a
     gravação, e nenhuma mensagem de sucesso aparece antes de a escrita
     terminar.
   - A edição carrega a candidatura pelo id. Se ela não existir, mostra
     o estado "não encontrada".
   - Entram no domínio `ApplicationDraft.copyWith` e
     `ApplicationDraft.fromApplication`.
7. **Listagem (View).**
   - Tabela própria: cabeçalho fixo e linhas com `ListView.builder`. O
     `DataTable` não é usado porque não é preguiçoso para listas
     longas.
   - Colunas: Empresa, Vaga, Data, Canal e Status. O status aparece
     como badge discreto com texto. Abaixo de ~800px de largura, a
     coluna Canal é ocultada.
   - Cada linha tem um menu "⋮" com Editar e Excluir.
   - Estados:
     - carregando;
     - vazio, com "Cadastrar primeira candidatura";
     - erro, com "Tentar novamente";
     - aviso de "N registros não puderam ser lidos".
8. **Formulário (View).** Seções:
   - **Vaga:** empresa, título, URL, ATS, descrição da vaga e data de
     encerramento.
   - **Candidatura:** data, canal e "Outro", status, versão do
     currículo.
   - **Local e remuneração:** modalidade, cidade, faixa salarial.
   - **Contato e notas:** contato e observações.
   - **Acompanhamento:** data manual opcional.

   A validação aparece junto a cada campo (RF-01). As datas usam um
   campo `dd/MM/yyyy` com botão de calendário. Duas colunas em janelas
   largas, uma coluna em janelas estreitas.
9. **Exclusão (F6).** Diálogo "Excluir candidatura?" com empresa e
   vaga e os botões Cancelar e Excluir. O botão Excluir usa a cor de
   erro, com texto.
10. **Feedback.** `SnackBar` flat, sem elevação, mostrado pela View. O
    controller só informa o resultado da operação.

## Arquivos

```text
lib/core/time/clock.dart
lib/core/formatting/date_format.dart              # dd/MM/yyyy
lib/core/widgets/date_field.dart                  # campo + calendário
lib/core/widgets/state_views.dart                 # carregando, vazio, erro
lib/features/applications/views/labels.dart
lib/features/applications/views/status_badge.dart
lib/features/applications/views/applications_page.dart     # reescrita
lib/features/applications/views/application_form_page.dart
lib/features/applications/viewmodels/applications_controller.dart
lib/features/applications/viewmodels/application_form_controller.dart
lib/features/applications/models/application_draft.dart    # + copyWith/fromApplication
lib/app/routes/*, lib/app/shell/app_shell.dart, lib/app/app.dart (locale)
test/support/fake_application_repository.dart     # em memória, com falha programável
test/viewmodels/..., test/widget/..., test/unit/core/date_format_test.dart
```

## Critérios de aceitação desta etapa

São os CA-APP-01 a 04, 11, 16 e 17 da spec, mais:

- **CA-E3-01** — A listagem mostra carregando e depois os dados,
  ordenados por data da candidatura (decrescente).
- **CA-E3-02** — Sem candidaturas, aparece o estado vazio com a chamada
  para cadastrar. Com falha de leitura, aparece o erro com "Tentar
  novamente", que recarrega.
- **CA-E3-03** — Com registros ilegíveis, aparece o aviso, e as demais
  candidaturas continuam listadas.
- **CA-E3-04** — A edição carrega os valores atuais, salvar atualiza a
  linha na listagem, e o histórico e os contatos são preservados.
- **CA-E3-05** — Durante a gravação, o botão Salvar fica desabilitado.
  Com falha, aparece a mensagem de erro e o formulário continua
  preenchido.
- **CA-E3-06** — As datas são exibidas e digitadas como `dd/MM/yyyy`.
  Uma data inválida (31/02/2026) mostra erro no campo.
- **CA-E3-07** — Navegar pela barra lateral não acumula páginas, e o
  controller do formulário é descartado ao sair.

## Testes

- **Unitários:** formato e leitura de datas; `ApplicationDraft.copyWith`
  e `fromApplication`.
- **Controllers** (repositório falso em memória, com falhas
  programáveis):
  - listagem: carregar, vazio, erro, ilegíveis, excluir com sucesso e
    com falha;
  - formulário: validação, criar, editar, aviso de duplicidade,
    falha de gravação, "não encontrada".
- **Widgets:**
  - estado vazio;
  - linhas da tabela;
  - diálogo de exclusão (cancelar e confirmar);
  - mensagens de validação;
  - diálogo de duplicidade;
  - badge de status com texto.

## Perguntas para aprovação

1. **Idioma e datas (D-06):** pt-BR, `dd/MM/yyyy` e
   `flutter_localizations` do SDK para o calendário em português?
2. **Editar e excluir antes da página de detalhes:** clicar na linha
   abre a edição, e um menu "⋮" na linha tem Editar e Excluir? Na Etapa
   4, o clique passa a abrir os detalhes.
3. **Alterações não salvas:** ao sair do formulário com mudanças não
   salvas, perguntar "Descartar alterações?"?
