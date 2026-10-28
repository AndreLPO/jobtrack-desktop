# Roadmap incremental

Cada etapa gera um app executável, com testes passando, e é aprovada
antes da próxima. Antes de iniciar uma etapa, criar `plan.md` e
`tasks.md` da feature correspondente.

| #  | Etapa | Entrega | Decisões ainda abertas |
|----|-------|---------|------------------------|
| 0 ✅ | **Base executável** | `flutter create --platforms=windows`; `get`, `hive_ce` e `hive_ce_flutter` com versões verificadas por `flutter pub get`; lints; tokens de tema claro (cores, espaçamento, tipografia, raios, sem sombra); shell com navegação lateral e 4 páginas placeholder com seus controllers e rotas; inicialização do Hive antes do `runApp`, com tela de erro amigável se falhar. Teste: smoke de navegação. | D-44, D-42 (provisório) |
| 1 ✅ | **Domínio puro** | Enums (status com classificação, canal, tipo de contato, modalidade); `Application`, `StatusChange`, `Interaction`; validações; `hasResponse`, `lastContactAt`, semana atual, `FollowUpPolicy`. Somente testes unitários. (`Clock` adiado para a Etapa 3.) | — |
| 2 ✅ | **Persistência** | Repositórios de candidaturas e de configurações (interface + implementação Hive); mapeamento com `schemaVersion`; falhas tipadas; testes de CRUD, de reabertura de boxes e de exclusão. | — |
| 3 ✅ | **Candidaturas: listagem + formulário** | Cadastrar, editar e listar, com aviso de duplicidade; estados vazio, erro e carregando; exclusão com confirmação. | — |
| 4 ✅ | **Detalhes** | Histórico de status, alterar status, registrar contato, descrição da vaga. | — |
| 5 ✅ | **Busca, filtros e ordenação** | RF-04 completo (busca sem acento, status, canal, período, "precisam de acompanhamento", 3 ordenações). | — |
| 6  | **Configurações** | Prazo e limite de tentativas. | — |
| 7  | **Acompanhamentos** | Seções "Vencidos" e "Sugerido encerrar"; indicador e filtro na listagem; registrar contato, adiar, encerrar sem resposta. | — |
| 7b | **Modelo de mensagem** | Texto pronto para copiar com os dados da candidatura (D-27). Requer spec própria. | D-50 |
| 8  | **Dashboard** | Indicadores, resumo por status, rótulos de escopo. | — |
| 9  | **Acabamento** | Revisão contra a Definition of Done, responsividade de janela, acessibilidade básica, revisão visual, documentação do local dos dados. | — |

## Racional da ordem

- **0 → 2** priorizam o app executável e a persistência confiável,
  antes de qualquer tela de negócio.
- **1** isola as regras mais arriscadas (datas, resposta, tentativas,
  entrevista, encerramento da vaga) em código puro e testável.
- **3 → 5** entregam o fluxo essencial: registrar e consultar.
- **6 → 7b** dependem das configurações e da política de
  acompanhamento.
- **8** é só leitura e reutiliza as regras já testadas.
