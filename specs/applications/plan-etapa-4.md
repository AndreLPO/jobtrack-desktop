# Plano — Etapa 4: Detalhes da candidatura

- **Status:** Implementado (2026-10-28). Decisões D-19, D-53, D-54 e D-55; ver `tasks-etapa-4.md`.
- **Referências:** `specs/applications/spec.md` (F2, F3, F4, F6, §9,
  CA-APP-05 a 10, 12); PROJECT.md RF-02, RF-07, RF-08, RN-06;
  decisões D-10, D-11, D-15, D-18, D-19, D-21a, D-51;
  `specs/domain/tasks.md` (pontos para revisar).

## Objetivo

Página de detalhes com todos os dados da candidatura, o histórico de
status e os contatos, além das ações: alterar status, registrar
contato, editar e excluir.

## Fora desta etapa

- **Situação de acompanhamento** (vencida, agendada, sugerido encerrar)
  e as ações "Adiar" e "Encerrar sem resposta": Etapa 7, junto com a
  página de Acompanhamentos.
- **Modelo de mensagem:** Etapa 7b.
- **Busca e filtros:** Etapa 5.

## Abordagem

1. **Rota** `/applications/:id`, com o `ApplicationDetailsController`.
   - Clicar na linha da listagem passa a abrir os detalhes (D-51). O
     menu "⋮" continua com Editar e Excluir.
   - Ao voltar dos detalhes, a listagem recarrega, porque status e
     dados podem ter mudado.
   - "Editar" nos detalhes abre o formulário existente. Ao salvar,
     volta para os detalhes recarregados.
2. **`ApplicationDetailsController`.**
   - Estado: `loading | ready | notFound | error`, mais a candidatura.
   - Ações:
     - `changeStatus(newStatus, note)`, que usa
       `Application.changeStatus` com o `Clock`;
     - `registerInteraction(...)`, que usa
       `Application.registerInteraction` com validação de
       `validateInteraction`;
     - `delete()`.
   - Todas as ações gravam inteiro com `repository.save` e só atualizam
     a tela depois de a gravação terminar (RN-APP-13).
   - A página informa o resultado ao usuário (sucesso ou falha).
3. **Página de detalhes**, com cabeçalho e seções:
   - **Cabeçalho:** empresa — vaga, badge de status, e os botões
     Alterar status, Registrar contato, Editar e Excluir.
   - **Resumo:** data da candidatura, canal, último contato (derivado),
     respondida (sim/não, derivado de `hasResponse`), próximo
     acompanhamento manual, se houver.
   - **Dados da vaga:** link (clicável só para copiar; abrir no
     navegador exigiria o pacote `url_launcher`, fora do escopo), ATS,
     versão do currículo, modalidade, cidade, faixa salarial, contato,
     observações.
   - **Descrição da vaga:** recolhida por padrão, com "Mostrar".
   - **Contatos:** do mais recente para o mais antigo, com data, tipo,
     resumo, "Houve resposta", e a próxima data, se informada.
   - **Histórico de status:** do mais recente para o mais antigo, com
     "A → B", data/hora e nota.

   Em janelas largas, Contatos e Histórico ficam lado a lado. Em
   janelas estreitas, um embaixo do outro.
4. **Diálogo "Alterar status" (F3):** lista dos 8 status, com o atual
   marcado, e uma nota opcional. Escolher o mesmo status não grava nada
   (RN-APP-05). Reabrir uma candidatura encerrada é permitido (D-10).
5. **Diálogo "Registrar contato" (F4):**
   - data, com hoje como padrão, sem permitir data futura (D-18);
   - tipo (D-15);
   - resumo (pergunta 1);
   - "Houve resposta da empresa?";
   - próxima data de acompanhamento, opcional (pergunta 2).

   Um texto de ajuda explica que a próxima data substitui a data
   manual atual (D-21a).
6. **Rótulos** pt-BR dos tipos de contato em `labels.dart`, e
   `formatDateTime` (dd/MM/yyyy HH:mm) para o histórico.
7. **`updatedAt` (D-19):** já é atualizado por `changeStatus`,
   `registerInteraction` e `updateDetails`. Proponho fechar D-19 como
   "qualquer alteração persistida atualiza".

## Critérios de aceitação desta etapa

São os CA-APP-05 a 10 e 12 na interface, mais:

- **CA-E4-01** — Clicar na linha da listagem abre os detalhes, e voltar
  recarrega a listagem.
- **CA-E4-02** — Os detalhes mostram todos os campos preenchidos e
  ocultam os vazios.
- **CA-E4-03** — Alterar o status atualiza o badge e adiciona o
  registro "A → B" no topo do histórico. Uma falha de gravação mantém
  o status anterior e avisa.
- **CA-E4-04** — Registrar contato coloca o contato no topo da lista e
  atualiza "Último contato" e "Respondida". Uma data futura é recusada
  no campo.
- **CA-E4-05** — Excluir pelos detalhes pede confirmação e volta para a
  listagem sem a candidatura.
- **CA-E4-06** — Um id inexistente mostra "Candidatura não encontrada".
- **CA-E4-07** — Editar a partir dos detalhes volta para os detalhes
  atualizados.

## Testes

- **Controller:** carregar, não encontrada, erro, alterar status
  (sucesso, mesmo status, falha), registrar contato (sucesso,
  validação, falha) e excluir.
- **Widgets:** navegação da lista para os detalhes, seções, os dois
  diálogos, exclusão e edição com retorno.

## Perguntas para aprovação

1. **Resumo do contato:** obrigatório, como no modelo da spec, ou
   opcional? Contatos simples, como "Agradecimento enviado", muitas
   vezes não precisam de texto.
2. **Próxima data no contato:** exigir hoje ou uma data futura, como no
   "Adiar", ou aceitar qualquer data?
3. **Corrigir contatos:** na v1 os contatos ficam fixos depois de
   registrados, ou é possível excluir um contato (com confirmação) para
   corrigir erros?
4. **D-19:** qualquer alteração persistida atualiza o `updatedAt`?
