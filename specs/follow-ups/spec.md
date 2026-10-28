# Spec — Acompanhamentos (follow-ups)

- **Status:** Rascunho. Sem bloqueios; pronta para aprovação.
- **Origem:** PROJECT.md RF-06, RF-07, RF-10; RN-04, RN-05; §8.
  Decisões D-10, D-11, D-20 a D-23, D-25, D-26, D-28, D-40.
- **Depende de:** applications (modelo), settings (prazo e limite de
  tentativas)

## 1. Objetivo

Indicar, de forma confiável, quais candidaturas precisam de
acompanhamento e quando. O usuário decide se entra em contato e
registra o resultado manualmente.

## 2. Escopo

- Função de domínio única que calcula a situação de acompanhamento de
  uma candidatura (`FollowUpPolicy.evaluate`).
- Página "Acompanhamentos" com as candidaturas vencidas e as marcadas
  como "sugerido encerrar".
- Indicador na listagem de candidaturas e contagem no dashboard, ambos
  com a mesma função.
- Atalho para registrar contato (reusa o F4 de applications).

## 3. Exclusões

- Envio de e-mail, mensagem ou qualquer automação externa. O modelo de
  mensagem para copiar está na Etapa 7b (D-27).
- Notificações do sistema operacional e lembretes em segundo plano.
- Dias úteis e feriados (D-20).
- Mudança automática de status. O limite de tentativas só **sugere**
  encerrar (D-25).

## 4. Termos

- **Hoje:** data local atual, sem hora.
- **Prazo:** `followUpIntervalDays` (padrão 7).
- **Limite:** `maxFollowUpAttempts` (padrão 3).
- **Último contato:** data do contato mais recente (D-14).
- **Evento de resposta:** contato com `receivedResponse = true` ou
  mudança para um status que indica resposta (D-11).
- **Tentativas:** contatos do tipo "Acompanhamento enviado" posteriores
  ao último evento de resposta (D-25). "Agradecimento enviado" não
  conta.
- **Data manual:** campo único da candidatura, `manualNextFollowUpAt`
  (D-21).

## 5. Regras de negócio

`FollowUpPolicy.evaluate(application, settings, today)` retorna uma de
quatro situações:

| Situação           | Significado                                           |
|--------------------|-------------------------------------------------------|
| `notApplicable`    | Status encerrado. Nunca aparece na lista.             |
| `scheduled(date)`  | Ativa, com data sugerida no futuro.                   |
| `due(date)`        | Ativa, com data sugerida hoje ou no passado: aparece na lista. |
| `suggestClose`     | Ativa, com o limite de tentativas atingido.           |

As regras são avaliadas **nesta ordem**:

- **RN-FU-01 — Status encerrado** (Reprovada, Desisti, Encerrada sem
  resposta) resulta em `notApplicable`.
- **RN-FU-02 — A data manual tem prioridade** (D-21): se existir, a
  data sugerida é a data manual, independentemente das regras
  seguintes, inclusive do limite.
- **RN-FU-03 — Limite de tentativas** (D-25, D-28): se tentativas ≥
  limite, o resultado é `suggestClose`. Vale com ou sem resposta
  anterior, porque a contagem recomeça a cada evento de resposta.
- **RN-FU-04 — Sem resposta** (`hasResponse == false`):
  1. Se não há contatos e há data de encerramento da vaga, a data
     sugerida é encerramento + 2 dias (D-26, I-4).
  2. Senão, a data sugerida é (último contato ou, na falta dele, data
     da candidatura) + prazo.
- **RN-FU-05 — Com resposta e status Entrevista** (D-22):
  1. Se o contato mais recente é do tipo "Entrevista", a data sugerida
     é a data desse contato + 1 dia.
  2. Se não há contato posterior à mudança para Entrevista, a data
     sugerida é a data dessa mudança + 1 dia.
  3. Senão, a data sugerida é o último contato + prazo. Por exemplo,
     depois do "Agradecimento enviado", volta a valer o prazo padrão.
- **RN-FU-06 — Com resposta e status Resposta recebida, Teste técnico
  ou Proposta recebida:** a data sugerida é a mais recente entre o
  último contato e a última mudança de status (I-3), + prazo.
- **RN-FU-07 — Com resposta e status Aplicada:** acontece quando há um
  contato marcado como resposta, mas o status não mudou. Aplica-se a
  mesma regra do RN-FU-06.
- **RN-FU-08 — Cálculo de datas:** só datas locais, em dias corridos. A
  candidatura vence a partir do próprio dia sugerido (limite
  inclusivo).
- **RN-FU-09 — "Dias desde":** hoje − base usada no cálculo. A
  interface exibe também qual é a base (candidatura, último contato,
  entrevista, encerramento da vaga ou data manual).
- **RN-FU-10 — Nada é persistido:** situação e data sugerida são
  sempre calculadas (D-21). Mudar o prazo ou o limite nas
  Configurações tem efeito imediato em todas as candidaturas sem data
  manual.

## 6. Fluxos

**F1 — Consultar pendências.** Navegação lateral → Acompanhamentos →
duas seções:
- **Vencidos:** situação `due`, ordenados pela data sugerida, da mais
  antiga para a mais recente.
- **Sugerido encerrar:** situação `suggestClose`.

**F2 — Registrar contato.** Item → "Registrar contato" → formulário de
contato (F4 de applications) → ao salvar, a lista é recalculada.

**F3 — Abrir detalhes.** Item → detalhes da candidatura.

**F4 — Adiar.** Item → "Adiar" → escolher a nova data (hoje ou
futura) → grava `manualNextFollowUpAt` → o item sai de "Vencidos" até
a data escolhida (D-23).

**F5 — Encerrar sem resposta.** Item → "Encerrar sem resposta" →
confirmação → status muda para "Encerrada sem resposta", com registro
no histórico → o item sai da lista (D-23).

**F6 — Copiar mensagem.** Item → "Copiar mensagem" → modelo da Etapa
7b. A ação só aparece depois que a Etapa 7b for implementada (D-23,
D-27).

## 7. Colunas da lista (RF-06)

Empresa · Vaga · Data da candidatura · Dias desde (com a base) · Data
sugerida · Status · Tentativas (n/limite) · Contato/Observações
(resumido, se houver).

## 8. Critérios de aceitação

Prazo = 7, limite = 3, sem data manual, salvo indicação:

- **CA-FU-01** — Aplicada há 6 dias, sem contatos: `scheduled`.
- **CA-FU-02** — Aplicada há exatamente 7 dias: `due` (limite
  inclusivo).
- **CA-FU-03** — Status encerrado, aplicada há 30 dias:
  `notApplicable`.
- **CA-FU-04** — Sem resposta, com 3 "Acompanhamento enviado":
  `suggestClose`, e o status continua inalterado.
- **CA-FU-05** — Sem resposta, com 2 tentativas, a última há 7 dias:
  `due`.
- **CA-FU-06** — Data de encerramento da vaga = hoje − 2, sem
  contatos, aplicada há 1 dia: `due`. Com encerramento = hoje − 1:
  `scheduled`.
- **CA-FU-07** — Status Entrevista, contato "Entrevista" ontem: `due`
  (data sugerida = hoje).
- **CA-FU-08** — Status Entrevista, contato "Entrevista" há 3 dias e
  "Agradecimento enviado" há 2 dias: data sugerida = "Agradecimento"
  + 7 dias, resultado `scheduled`.
- **CA-FU-09** — Status Teste técnico, sem contatos, status alterado
  há 7 dias: `due` (I-3).
- **CA-FU-10** — Data manual futura em uma candidatura com
  `suggestClose`: `scheduled(data manual)`.
- **CA-FU-10b** — Status Resposta recebida, seguido de 3
  "Acompanhamento enviado" posteriores à resposta: `suggestClose`.
  Com uma nova resposta depois deles, a contagem volta a 0.
- **CA-FU-10c** — "Adiar" para hoje + 5: `scheduled`. Ao confirmar
  "Encerrar sem resposta", o resultado é `notApplicable`, e o
  histórico ganha o `StatusChange`. Ao cancelar, nada muda.
- **CA-FU-11** — Mudar o prazo de 7 para 3 dias: uma candidatura sem
  resposta aplicada há 4 dias passa a `due`.
- **CA-FU-12** — Limites de calendário: virada de mês, de ano (28/12 +
  7 = 04/01) e 29/02 em ano bissexto.
- **CA-FU-13** — A contagem de `due` é idêntica na página de
  Acompanhamentos, no dashboard e no filtro da listagem.

## 9. Estados de interface

carregando · com dados (seções Vencidos e Sugerido encerrar) · vazio
("Nenhum acompanhamento pendente") · erro de leitura (com "tentar
novamente").

## 10. Dados afetados

- Leitura: candidaturas (status, histórico, contatos, data manual,
  data de encerramento da vaga) e `AppSettings`
  (`followUpIntervalDays`, `maxFollowUpAttempts`).
- Escrita: só através do repositório de candidaturas (registrar
  contato, adiar = data manual, encerrar = mudança de status).

## 11. Testes

- **Unitários:** tabela de casos de `FollowUpPolicy.evaluate` cobrindo
  todos os CA, com "hoje" injetado.
- **Controller (`FollowUpsController`):** carregar, seções, vazio,
  erro, recálculo após registrar contato.
- **Widget:** colunas obrigatórias, as duas seções, estado vazio,
  status exibido como texto.
