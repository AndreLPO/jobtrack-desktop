# Plano — Etapa 1: Domínio puro

- **Status:** Implementado (2026-10-28). Perguntas 1 e 2 resolvidas em D-22b e D-25b; ver `tasks.md`.
- **Referências:** `specs/applications/spec.md` (§4, §5),
  `specs/follow-ups/spec.md` (§4, §5, §8),
  `specs/dashboard/spec.md` (RN-DSH-01), `specs/settings/spec.md`
  (RN-SET-01/02); decisões D-10 a D-28, D-40, I-3, I-4.

## Objetivo

Implementar as regras de negócio como código Dart puro, sem Flutter,
GetX ou Hive, e cobri-las com testes unitários. As etapas seguintes
(persistência, telas, dashboard) só consomem estas regras e não as
reimplementam.

## Fora desta etapa

- Persistência, adapters e repositórios (Etapa 2).
- Telas, controllers e textos de interface. Os rótulos em pt-BR dos
  enums ficam na camada de apresentação (Etapa 3); aqui só existem
  códigos.
- `DashboardMetrics`, que fica para a Etapa 8. Nesta etapa entra só o
  cálculo da semana (RN-DSH-01), porque é uma regra de data com risco
  de erro nos limites.
- Um `Clock` injetável. As regras recebem `today` ou `now` por
  parâmetro, o que basta para testar. O `Clock` entra na Etapa 3,
  quando os controllers precisarem dele.

## Decisões técnicas propostas

1. **`LocalDate` (objeto de valor).** O Dart não tem tipo "só data".
   Proponho uma classe pequena (ano, mês, dia) para os campos sem hora
   de D-18: data da candidatura, data do contato, data de encerramento
   da vaga e data manual. Ela evita misturar horário e fuso nas
   comparações.
   - Oferece `addDays`, `daysUntil`, `compareTo`, `==` e
     `fromDateTime(local)`.
   - A aritmética usa `DateTime.utc` internamente, imune a horário de
     verão.
   - Campos de data+hora (`createdAt`, `updatedAt`, `changedAt`)
     continuam `DateTime`.
2. **Entidades imutáveis.** As operações devolvem uma nova instância:
   - `Application.create(...)`, que gera o `StatusChange` inicial;
   - `changeStatus(...)`, que não registra nada se o status for igual
     ao atual;
   - `registerInteraction(...)`, que atualiza a data manual (D-21a);
   - `updateDetails(...)`, que preserva histórico e contatos;
   - `postpone(date)`, para a ação "Adiar".

   Isso combina com o GetX (substituir o valor observável) e facilita
   os testes. Não haverá pacote `equatable` nem gerador de código.
3. **Ids.** As entidades recebem o id pronto. A geração usa
   `const Uuid().v4()` através de um `typedef IdGenerator`, injetável
   nos testes. Dependência nova: `uuid` ^4.6.0.
4. **Validação sem texto.** `validateApplication(draft, today)` devolve
   uma lista de `(campo, código de erro)`. As mensagens em pt-BR ficam
   na interface.
5. **Resultado do acompanhamento.** `FollowUpPolicy.evaluate` devolve
   uma classe selada com quatro casos:
   - `NotApplicable`;
   - `Scheduled(dueDate, base)`;
   - `Due(dueDate, base)`;
   - `SuggestClose(attempts)`.

   `base` informa a data e a origem do cálculo (candidatura, último
   contato, entrevista, mudança de status, encerramento da vaga ou
   data manual), o que permite exibir "dias desde" (RN-FU-09).
6. **Ordem de contatos na mesma data.** O contato "mais recente" é o de
   maior data. Em caso de empate, vale o último registrado (ordem da
   lista).

## Arquivos

Seguem a pasta `models/` do PROJECT.md §5.4 e a decisão D-44:

```text
lib/core/time/
  local_date.dart
  week_range.dart                 # semana seg–dom que contém uma data
lib/features/applications/models/
  application_status.dart         # 8 status + isActive + indicatesResponse
  application_channel.dart
  interaction_type.dart
  work_mode.dart
  status_change.dart
  interaction.dart
  application.dart                # agregado + hasResponse + lastContactAt
  application_draft.dart          # entrada do formulário
  application_validation.dart     # validateApplication, validateInteraction
  duplicate_check.dart            # findPossibleDuplicate
  follow_up_policy.dart
lib/features/settings/models/
  follow_up_settings.dart         # prazo (1–90, padrão 7) e limite (1–10, padrão 3)
lib/core/ids.dart                 # IdGenerator
test/unit/core/time/...
test/unit/applications/...
test/unit/settings/...
```

## Testes (todos unitários)

| Arquivo de teste              | Cobre                                                         |
|-------------------------------|---------------------------------------------------------------|
| `local_date_test`             | Virada de mês e de ano, 29/02, `daysUntil` com valores negativos |
| `week_range_test`             | CA-DSH-01 a 03 (segunda 00:00, domingo, virada de mês e de ano) |
| `application_status_test`     | Classificação de ativo, encerrado e indica resposta (D-10, D-11) |
| `application_test`            | CA-APP-05 a 10: histórico, reabertura, mesmo status, edição preservando dados, `hasResponse`, `lastContactAt`, data manual |
| `application_validation_test` | CA-APP-01 a 03 e 12: obrigatórios, trim, datas futuras, canal Outro, URL |
| `duplicate_check_test`        | CA-APP-11: caixa e espaços; ignora a própria candidatura na edição |
| `follow_up_settings_test`     | Padrões e faixas (CA-SET-01 e 03, no domínio)                   |
| `follow_up_policy_test`       | CA-FU-01 a 13, CA-SET-04/05, em tabela com `today` fixo          |

## Perguntas para aprovação

1. **Inconsistência na regra da Entrevista.** D-22 diz: "sem contato do
   tipo Entrevista, usar a data da mudança de status + 1 dia". Já
   RN-FU-05 diz: "se houver *qualquer* contato depois da mudança, usar
   o último contato + prazo". Exemplo: status mudou para Entrevista em
   10/11, e em 11/11 você registra "Mensagem recebida" (convite com
   horário), sem contato do tipo Entrevista. D-22 sugere o
   acompanhamento em 11/11; RN-FU-05 sugere em 18/11. Qual vale?
   - **Recomendação:** sem contato do tipo Entrevista, usar a mudança
     de status + 1 dia, como em D-22. O prazo padrão volta a valer só
     depois de existir um contato do tipo Entrevista seguido de outro
     contato, como o agradecimento.
2. **Acompanhamento e resposta no mesmo dia.** Se um "Acompanhamento
   enviado" e uma resposta caem na mesma data, o acompanhamento conta
   como tentativa depois da resposta?
   - **Recomendação:** não conta. A tentativa só conta se for de data
     estritamente posterior à última resposta.
