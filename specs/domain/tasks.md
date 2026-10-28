# Tasks — domain / Etapa 1

- [x] T1 — `uuid` ^4.6.0 adicionado (D-02).
- [x] T2 — `LocalDate` e `WeekRange`, com testes (limites de mês, ano,
  29/02 e semana: CA-DSH-01 a 03).
- [x] T3 — Enums de status (com classificação), canal, tipo de contato
  e modalidade, com teste de classificação.
- [x] T4 — `StatusChange`, `Interaction` e `Application` (`create`,
  `changeStatus`, `registerInteraction`, `updateDetails`, `postpone`,
  `hasResponse`, `lastContactAt`). Testes CA-APP-05 a 10.
  - **Adição ao plano:** `ApplicationDetails`, que agrupa os dados
    descritivos já normalizados e evita repetir os 15 campos em
    `Application` e no rascunho.
- [x] T5 — `ApplicationDraft`, `validateApplicationDraft`,
  `validateInteraction`, `validatePostponeDate`,
  `findPossibleDuplicate`. Testes CA-APP-01 a 03, 11 e 12 e URL.
- [x] T6 — `FollowUpSettings` (padrões e faixas), com testes CA-SET-01
  e 03.
- [x] T7 — `FollowUpPolicy.evaluate` e
  `attemptsSinceLastResponse`. Testes CA-FU-01 a 12, CA-FU-10b/10c,
  CA-SET-04/05, D-22b e D-25b. O CA-FU-13 fica para os testes de
  controller das Etapas 7 e 8.
- [x] T8 — Nenhum arquivo em `models/`, `core/time/` ou `core/ids.dart`
  importa Flutter, GetX ou Hive. Verificado por grep.
- [x] T9 — Verificação em 2026-10-28:
  - `dart format .`: sem alterações pendentes.
  - `flutter analyze`: "No issues found!".
  - `flutter test`: 84 testes, "All tests passed!".

## Pontos para revisar na Etapa 3 ou 4 (não bloqueiam)

- O **resumo do contato** está como obrigatório, seguindo o modelo da
  spec (`summary` sem `?`). Se for incômodo em contatos simples, como
  "Agradecimento enviado", pode virar opcional.
- A **próxima data de acompanhamento** informada no contato ou no
  formulário não é validada. Só a ação "Adiar" exige hoje ou data
  futura. Motivo: ao editar uma candidatura cuja data manual já
  passou, a validação impediria salvar o formulário.
