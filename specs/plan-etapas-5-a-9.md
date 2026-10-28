# Plano — Etapas 5 a 9

- **Status:** Implementado (2026-10-28). Dúvidas resolvidas em D-50,
  D-56 a D-59. Ver "Resultado" no fim.
- **Referências:** specs de applications (§7), follow-ups, settings e
  dashboard; `specs/roadmap.md`.

Cada etapa termina com `dart format`, `flutter analyze`,
`flutter test` e um commit próprio.

## Etapa 5 — Busca, filtros e ordenação

- **Domínio puro** (`application_query.dart`):
  - `ApplicationFilter`: texto, status (vários), canais (vários),
    período de/até inclusivo e "só acompanhamento";
  - `ApplicationSort`: data da candidatura (padrão), última atualização
    e próximo acompanhamento;
  - `normalizeForSearch`, que tira acentos e caixa (D-56);
  - `queryApplications`.
- **Controller:** filtro e ordenação observáveis, lista visível
  derivada, contagem "N de M" e "Limpar filtros".
- **View:** barra com busca, menus de Status e Canal (com caixas de
  seleção), Período (diálogo com De/Até e validação De ≤ Até) e
  Ordenar. Estado "nenhuma candidatura corresponde aos filtros".
- **Testes:** busca com e sem acento, cada filtro, combinação dos
  filtros, limites do período e ordenações.

## Etapa 6 — Configurações

- `SettingsController`: prazo (1–90) e limite (1–10) como texto
  validado, salvar, alterações não salvas (D-59) e o caminho da pasta
  de dados (D-43).
- **View:** campos numéricos, texto explicativo das regras e "Salvar".
- **Testes:** CA-SET-01 a 06 (controller e widget).

## Etapa 7 — Acompanhamentos

- **Listagem:**
  - coluna "Acompanhamento" (Vencido, Hoje, Em dd/MM/yyyy, Sugerido
    encerrar, —);
  - filtro "só acompanhamento";
  - ordenação por próximo acompanhamento.

  A listagem passa a carregar as configurações.
- **`FollowUpsController`:** seções Vencidos (data sugerida mais antiga
  primeiro) e Sugerido encerrar. Ações: registrar contato, adiar (hoje
  ou futura), encerrar sem resposta (com confirmação) e copiar
  mensagem (Etapa 7b).
- **View:** itens com empresa, vaga, status, data da candidatura, dias
  desde a base (com a base escrita), data sugerida, tentativas n/limite
  e contato ou observações. Clicar abre os detalhes.
- **Testes:** controller (seções, ordem, ações, falhas), widget e
  CA-FU-13 (mesma contagem na listagem e em Acompanhamentos).

## Etapa 7b — Modelo de mensagem

- Domínio `MessageTemplate.render(application)` com `{empresa}`,
  `{vaga}`, `{data}` e `{contato}` (D-50, D-59).
- Persistência: chave `messageTemplate` na box `settings`, com mapper
  próprio (`schemaVersion` 1). O padrão em pt-BR é usado se não houver
  registro.
- Configurações: seção para editar, lista de variáveis e "Restaurar
  padrão".
- "Copiar mensagem" nos Acompanhamentos e nos detalhes, com o aviso
  "Revise antes de enviar".
- **Testes:** substituição de variáveis, contato vazio, mapper,
  repositório, salvar e restaurar, e cópia.

## Etapa 8 — Dashboard

- **Domínio** `DashboardMetrics.compute(applications, settings, today)`:
  - semana atual com o período;
  - com resposta e aguardando resposta (total geral);
  - pendentes (`due`);
  - sugerido encerrar;
  - resumo por status, com zeros;
  - total.
- **Controller e view:** cards com número, rótulo e escopo; cards
  clicáveis (D-57); resumo por status com barra proporcional e
  contagem; estados carregando, vazio e erro.
- **Testes:** CA-DSH-01 a 10 no domínio, controller e widget,
  incluindo a navegação com filtro.

## Etapa 9 — Acabamento

- `url_launcher` com o botão "Abrir" no link da vaga (D-58).
- Tamanho mínimo da janela (`WM_GETMINMAXINFO` no runner Win32, sem
  dependência).
- Revisão da Definition of Done:
  - nenhum gradiente ou sombra (grep);
  - estados vazio e erro em todas as páginas;
  - nenhuma View ou controller acessa o Hive.
- `README.md` do projeto: como rodar e testar, e onde ficam os dados.

## Resultado (2026-10-28)

| Etapa | Commit | Testes no total |
|-------|--------|-----------------|
| 5 | `c6d7ac1` | 193 |
| 6 | `35355c0` | 204 |
| 7 | `1928d82` | 218 |
| 7b | `c67f0c2` | 233 |
| 8 | `6aac6e5` | 251 |
| 9 | este commit | 251 |

Verificação final:

- `dart format .`: sem pendências.
- `flutter analyze`: "No issues found!".
- `flutter test`: 251 testes, "All tests passed!".
- `flutter build windows --release`: build concluído.
- O app em release abriu com a janela "JobTrack". O tamanho mínimo foi
  confirmado pedindo 400×300 via `SetWindowPos`: a janela ficou em
  960×600 a 96 DPI.

Auditoria da Definition of Done, feita por grep em `lib/`:

- nenhum `Gradient`, `BoxShadow` ou `elevation` maior que 0;
- `hive_ce` importado só em `core/database` e `repositories/hive_*`;
- nenhum controller importa widgets;
- domínio (`models`, `core/time`, `core/formatting`) sem Flutter, GetX
  ou Hive;
- cores só em `app/theme`.

Ajustes e desvios:

- **Etapa 5:** o filtro "Precisam de acompanhamento" e a ordenação por
  próximo acompanhamento entraram já aqui, porque o domínio e o
  carregamento das configurações ficaram prontos nesta etapa. A Etapa 7
  adicionou a coluna do indicador.
- **Etapa 7:** bug encontrado pelos testes e corrigido: a página de
  Acompanhamentos não se redesenhava depois de uma ação, porque o corpo
  não estava em um `Obx`.
- **Etapa 8:** `DashboardMetrics` fica em `applications/models`, porque
  é uma consulta sobre candidaturas (D-44). O widget `UnderConstruction`
  foi removido.
- **Etapa 9:** `url_launcher` ^6.3.3; tamanho mínimo de 960×600 em
  pixels lógicos no runner Win32; README do projeto.

Pendentes não bloqueantes: D-01 (adotar OpenSpec) e D-42 (identidade
visual final).
