# Spec — Candidaturas (applications)

- **Status:** Implementada (2026-10-28). Ver `specs/roadmap.md` e os planos de cada etapa.
- **Origem:** PROJECT.md RF-01, RF-02, RF-03, RF-04, RF-07, RF-08,
  RF-09; RN-01, RN-02, RN-04, RN-06, RN-07, RN-08. Decisões D-10 a
  D-18 e D-26.

## 1. Objetivo

Permitir que o usuário registre, consulte, edite e exclua candidaturas,
mantendo o histórico de mudanças de status e de contatos com a empresa.

## 2. Escopo

- Cadastro de candidatura, com aviso de possível duplicidade.
- Edição dos dados descritivos.
- Alteração de status com registro no histórico.
- Registro de contato (interação).
- Listagem com busca, filtros e ordenação.
- Página de detalhes com dados, descrição da vaga, histórico de status
  e contatos.
- Exclusão com confirmação explícita.

## 3. Exclusões

- Captura automática de vagas ou leitura de páginas web. A descrição
  da vaga é colada manualmente.
- Envio de mensagens.
- Anexos (arquivo do currículo). Só a "versão do currículo" é
  registrada, como texto.
- Exportação e backup (D-43).

## 4. Modelo de domínio

**Application** (agregado raiz; histórico e contatos embutidos, D-16)

| Campo              | Tipo                | Obrig. | Observação                                    |
|--------------------|---------------------|--------|-----------------------------------------------|
| id                 | String (UUID)       | sim    | Gerado na criação, imutável (RN-01)            |
| companyName        | String              | sim    | Não vazio após trim                           |
| jobTitle           | String              | sim    | Não vazio após trim                           |
| applicationDate    | Data local          | sim    | Não futura                                    |
| channel            | ApplicationChannel  | sim    | LinkedIn, Gupy, Site da empresa, E-mail, Indicação, Outro (D-12) |
| channelOther       | String?             | cond.  | Obrigatório se canal = Outro                  |
| status             | ApplicationStatus   | sim    | 8 status (D-10)                               |
| jobUrl             | String?             | não    | Se preenchida, deve começar com http(s)://    |
| atsName            | String?             | não    | Texto livre (Greenhouse, Lever, Workday...)   |
| resumeVersion      | String?             | não    | Ex.: "CV-backend-v3"                          |
| jobDescription     | String?             | não    | Texto longo colado pelo usuário               |
| jobClosingDate     | Data local?         | não    | Encerramento da vaga (D-26); pode ser futura  |
| workMode           | WorkMode?           | não    | Presencial, Híbrido, Remoto                   |
| city               | String?             | não    |                                               |
| contactName        | String?             | não    | Recrutador ou pessoa que fez a indicação      |
| salaryRange        | String?             | não    | Texto livre                                   |
| notes              | String?             | não    |                                               |
| manualNextFollowUpAt | Data local?       | não    | Data manual de acompanhamento (D-21a)         |
| createdAt          | DataHora            | sim    | Sistema                                       |
| updatedAt          | DataHora            | sim    | Sistema (D-19)                                |
| statusHistory      | List<StatusChange>  | —      | ≥ 1 item                                      |
| interactions       | List<Interaction>   | —      |                                               |

Valores **derivados**, que não são persistidos:
- `lastContactAt` (D-14);
- `hasResponse` (D-11);
- situação de acompanhamento (ver follow-ups).

**StatusChange:** id, previousStatus (nulo na criação), newStatus,
changedAt (DataHora), note?.

**Interaction:** id, interactionDate (Data local, não futura),
interactionType (D-15), summary, receivedResponse (bool),
nextFollowUpAt? (Data local).

A validação de URL (`http(s)://`) é a mínima para "dados inválidos"
(RF-01). Se for restritiva demais, pode ser revista no plano.

## 5. Regras de negócio

- **RN-APP-01** — O id é único, gerado uma vez e nunca alterado.
- **RN-APP-02** — Obrigatórios: empresa, vaga, data da candidatura,
  canal e status. Se o canal for "Outro", a descrição também é
  obrigatória. Textos são validados após `trim`.
- **RN-APP-03** — A data da candidatura e a data de um contato não
  podem ser posteriores a hoje (data local). A data de encerramento da
  vaga e a data manual de acompanhamento podem ser futuras.
- **RN-APP-04** — Toda mudança de status, inclusive o status inicial na
  criação, gera um `StatusChange` com data/hora.
- **RN-APP-05** — Transições de status são **livres**, inclusive para
  reabrir uma candidatura encerrada (D-10). O domínio não bloqueia
  nenhuma transição, mas não registra mudança quando o status novo é
  igual ao atual.
- **RN-APP-06** — Classificação, centralizada no enum:
  - ativos: Aplicada, Resposta recebida, Entrevista, Teste técnico,
    Proposta recebida;
  - encerrados: Reprovada, Desisti, Encerrada sem resposta;
  - indicam resposta: Resposta recebida, Entrevista, Teste técnico,
    Proposta recebida, Reprovada.
- **RN-APP-07** — `hasResponse` = status indica resposta **ou** existe
  contato com `receivedResponse`. É uma função única do domínio.
  Registrar uma resposta **não** altera o status (D-11).
- **RN-APP-08** — `lastContactAt` = maior `interactionDate` entre os
  contatos, ou nulo se não houver contatos (D-14).
- **RN-APP-09** — Ao registrar um contato, `manualNextFollowUpAt`
  recebe o `nextFollowUpAt` informado no contato, ou fica nulo se nada
  for informado (D-21a).
- **RN-APP-10** — Editar dados descritivos não altera nem remove
  `statusHistory` ou `interactions` (RN-06).
- **RN-APP-11** — **Duplicidade:** ao salvar, se já existir outra
  candidatura com a mesma empresa e vaga (comparação sem diferenciar
  maiúsculas e minúsculas e após trim), o app exibe um aviso com opção
  de salvar mesmo assim (D-13).
- **RN-APP-12** — Excluir remove o registro inteiro, com histórico e
  contatos embutidos (D-17).
- **RN-APP-13** — Falhas de persistência não podem ser mascaradas. A
  interface só mostra sucesso depois de confirmada a escrita (§9).

## 6. Fluxos

**F1 — Cadastrar.** Listagem → "Nova candidatura" → formulário →
validação por campo → aviso de duplicidade, se houver → salvar →
feedback de sucesso → volta à listagem com o item visível.

**F2 — Editar.** Detalhes → "Editar" → formulário preenchido → salvar.
O status **não** é alterado aqui (ver F3).

**F3 — Alterar status.** Detalhes → "Alterar status" → escolher entre
os 8 status + nota opcional → confirmar → novo `StatusChange`.

**F4 — Registrar contato.** Detalhes ou Acompanhamentos → "Registrar
contato" → data (não futura), tipo, resumo, houve resposta?, próxima
data de acompanhamento (opcional) → salvar.

**F5 — Consultar.** Listagem → busca, filtros e ordenação → clique
abre os detalhes.

**F6 — Excluir.** Detalhes → "Excluir" → diálogo com empresa e vaga →
confirmar → remoção → volta à listagem.

## 7. Listagem: busca, filtros e ordenação (RF-03, RF-04)

- **Colunas:** Empresa, Vaga, Data da candidatura, Canal, Status (badge
  com texto), Indicador de acompanhamento (texto + ícone, não só cor).
- **Busca:** por trecho do nome da empresa ou da vaga, sem diferenciar
  maiúsculas e minúsculas. Busca sem diferenciar acentos: a confirmar
  no plano.
- **Filtros combináveis (E lógico):**
  - status (múltiplo);
  - canal (múltiplo);
  - período de candidatura (início e fim inclusivos);
  - "só precisam de acompanhamento" (situação `due` ou
    `suggestClose`).
- **Ordenação:**
  - data da candidatura (padrão, mais recente primeiro);
  - última atualização;
  - data sugerida de acompanhamento (sem data por último).

## 8. Critérios de aceitação

- **CA-APP-01** — Ao salvar o formulário vazio, cada campo obrigatório
  mostra mensagem junto ao campo, e nada é persistido.
- **CA-APP-02** — Ao salvar com data de candidatura futura, a
  validação recusa.
- **CA-APP-03** — Ao salvar com canal "Outro" sem descrição, a
  validação recusa.
- **CA-APP-04** — Uma candidatura válida salva aparece na listagem e
  continua disponível depois de fechar e reabrir o app.
- **CA-APP-05** — Uma candidatura recém-criada tem exatamente 1
  `StatusChange` (previousStatus nulo).
- **CA-APP-06** — Mudar o status de A para B adiciona `StatusChange`
  A→B e preserva os anteriores. Escolher o mesmo status não gera
  registro.
- **CA-APP-07** — É possível reabrir uma candidatura encerrada (ex.:
  Reprovada → Entrevista).
- **CA-APP-08** — Editar empresa ou notas mantém histórico e contatos.
- **CA-APP-09** — Uma candidatura com N contatos de resposta conta 1
  vez como respondida. Registrar uma resposta com status Aplicada
  mantém o status Aplicada.
- **CA-APP-10** — `lastContactAt` reflete o contato mais recente, e o
  formulário de cadastro não tem esse campo.
- **CA-APP-11** — Salvar "Acme" + "Dev Flutter" quando já existe
  "acme " + "dev flutter" exibe o aviso. Confirmar o aviso salva.
- **CA-APP-12** — Um contato com data futura é recusado.
- **CA-APP-13** — A busca por "acme" encontra a empresa "ACME Ltda".
- **CA-APP-14** — Com os filtros status=X e canal=Y, só aparecem itens
  que atendem aos dois.
- **CA-APP-15** — No filtro de período [d1, d2], itens com data d1 ou
  d2 aparecem.
- **CA-APP-16** — Cancelar a exclusão não remove nada. Confirmar remove
  a candidatura, que não volta a aparecer depois de reabrir o app.
- **CA-APP-17** — Numa falha de escrita simulada, aparece uma mensagem
  compreensível, nenhuma mensagem de sucesso, e o app continua
  utilizável.

## 9. Estados de interface

| Página     | Estados                                                                 |
|------------|-------------------------------------------------------------------------|
| Listagem   | carregando · com dados · vazio (com chamada para cadastrar) · vazio por filtro ("limpar filtros") · erro de leitura ("tentar novamente") |
| Formulário | edição · erro de validação por campo · aviso de duplicidade · salvando · erro de escrita · sucesso |
| Detalhes   | carregando · com dados · não encontrada · erro                           |
| Exclusão   | confirmação · excluindo · erro                                          |

## 10. Dados afetados

- Box de candidaturas: um registro por candidatura, com histórico e
  contatos embutidos e `schemaVersion` (D-03).
- Leitura de `AppSettings` para o indicador de acompanhamento.

## 11. Testes

- **Unitários (domínio):**
  - validações (obrigatórios, canal Outro, URL, datas futuras);
  - classificação de status;
  - `hasResponse`;
  - `lastContactAt`;
  - histórico em mudanças e reaberturas;
  - regra de duplicidade.
- **Repositório:**
  - criar, consultar, atualizar e excluir;
  - persistência depois de reabrir as boxes (diretório temporário);
  - exclusão com todos os dados embutidos;
  - erro de escrita propagado como falha tipada.
- **Controllers:**
  - `ApplicationsController`: carregar, busca, filtros, ordenação,
    estados vazio e de erro;
  - `ApplicationFormController`: validação, aviso de duplicidade,
    salvar, erro;
  - `ApplicationDetailsController`: alterar status, registrar contato,
    excluir.
- **Widgets:**
  - mensagens de validação;
  - diálogo de duplicidade;
  - diálogo de exclusão;
  - badge de status com texto;
  - estado vazio.
