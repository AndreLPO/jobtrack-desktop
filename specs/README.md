# Especificações (SDD)

Estrutura simples de Spec-Driven Development em Markdown, sem
ferramentas externas.

```text
specs/
├── README.md          # este arquivo: fluxo e convenções
├── decisions.md       # decisões (pendentes e aprovadas) e ambiguidades
├── roadmap.md         # ordem incremental de implementação
├── <feature>/
│   ├── spec.md        # O QUÊ: comportamento, regras, critérios de aceite
│   ├── plan.md        # COMO: arquivos, modelos, abordagem técnica (criado ao iniciar a etapa)
│   └── tasks.md       # tarefas pequenas e verificáveis (criado junto com o plan)
```

Features iniciais: `dashboard`, `applications`, `follow-ups`,
`settings`. A pasta `foundation/` guarda o plano e as tarefas da base
técnica (Etapa 0), que não tem regra de negócio e por isso não tem
`spec.md`. A pasta `domain/` guarda o plano da Etapa 1, que implementa
regras de várias specs; as regras em si continuam nas specs de cada
feature. A pasta `persistence/` guarda o plano da Etapa 2, pelo mesmo
motivo.

## Ciclo de vida de uma spec

| Status       | Significado                                              |
|--------------|----------------------------------------------------------|
| Rascunho     | Em elaboração; pode conter itens `[PENDENTE D-xx]`.       |
| Aprovada     | Sem pendências bloqueantes; pode gerar plan/tasks.        |
| Implementada | Critérios de aceite verificados e testes passando.        |

Uma spec só passa a `Aprovada` quando todas as decisões que ela
referencia como bloqueantes estiverem resolvidas em `decisions.md`.

## Convenções

- Regras de negócio: `RN-<FEATURE>-nn` (ex.: `RN-APP-03`).
- Critérios de aceite: `CA-<FEATURE>-nn`, escritos como
  Dado / Quando / Então, verificáveis por teste.
- Referências ao `PROJECT.md`: `RF-xx`, `RN-xx`.
- Lacunas: `[PENDENTE D-xx]`, apontando para `decisions.md`. Nunca
  preencher lacunas com regras inventadas.

## Modelo de `tasks.md`

```md
# Tasks — <feature> / Etapa N
- [ ] T1 — descrição curta (arquivos: ..., teste: ...)
- [ ] T2 — ...
```

## Sobre OpenSpec

O CLI `openspec` (1.14.1) está instalado globalmente nesta máquina, mas
**não** está inicializado neste repositório. Adotá-lo é a decisão
D-01 em `decisions.md`; até lá, vale esta estrutura.
