# Spec — Dashboard

- **Status:** Implementada (2026-10-28). Ver `specs/roadmap.md` e os planos de cada etapa.
  depende.
- **Origem:** PROJECT.md RF-05; RN-02, RN-03, RN-04, RN-05; §8.
  Decisões D-10, D-11, D-21, D-30, D-31.
- **Depende de:** applications (modelo, `hasResponse`), follow-ups
  (`FollowUpPolicy`), settings (prazo e limite)

## 1. Objetivo

Dar ao usuário uma visão rápida e confiável da situação das
candidaturas, com indicadores calculados a partir dos registros
persistidos.

## 2. Escopo (v1, D-30)

- Candidaturas na semana atual.
- Candidaturas com resposta (total geral).
- Candidaturas aguardando resposta (total geral).
- Acompanhamentos pendentes (situação `due`).
- Resumo por status (quantidade por status, incluindo zeros).
- Cada indicador exibe explicitamente o período a que se refere (ex.:
  "Semana de 26/10 a 01/11").
- Os indicadores levam à listagem já filtrada, se for simples de fazer
  (a confirmar no plano).

## 3. Exclusões

- Período selecionável e gráfico de evolução semanal ficam para depois
  da v1 (D-30).
- Metas, comparativos e taxas de conversão.
- Contadores persistidos ou cache em disco.

## 4. Regras de negócio

- **RN-DSH-01 — Semana atual (RN-02/RN-03):** de segunda-feira 00:00
  (local) até antes da segunda-feira seguinte 00:00. Uma candidatura
  conta se `applicationDate` estiver nesse intervalo, e conta uma única
  vez.
- **RN-DSH-02 — Com resposta:** número de candidaturas distintas com
  `hasResponse == true` (D-11), contando todas as candidaturas
  cadastradas (D-31). Várias interações não multiplicam a contagem.
- **RN-DSH-03 — Aguardando resposta:** candidaturas com status ativo
  (D-10) e `hasResponse == false`, contando o total geral (D-31).
- **RN-DSH-04 — Acompanhamentos pendentes:** quantidade de candidaturas
  com situação `due` em `FollowUpPolicy.evaluate`, a mesma função usada
  em follow-ups. "Sugerido encerrar" não entra nessa contagem. Exibir
  um indicador próprio para ele fica a confirmar.
- **RN-DSH-05 — Resumo por status:** contagem por status atual. A soma
  é igual ao total de candidaturas.
- **RN-DSH-06:** todas as métricas vêm de um serviço de domínio puro
  (`DashboardMetrics.compute(applications, settings, today)`), sem
  lógica em widgets e sem gravar nada no Hive.

## 5. Fluxos

**F1 — Abrir o app.** O dashboard é a página inicial (a confirmar) e
calcula os indicadores ao abrir.

**F2 — Voltar ao dashboard após alterações.** Os indicadores refletem
cadastros, edições, exclusões e interações feitos em outras páginas.
Mecanismo: recarregar ao entrar na página ou observar o repositório;
decidir no plano.

**F3 — Clicar em um indicador (opcional).** Abre a listagem ou a página
de acompanhamentos com o filtro equivalente.

## 6. Critérios de aceitação

- **CA-DSH-01** — Com hoje = domingo 01/11/2026, candidaturas em
  26/10 (seg), 01/11 (dom) e 25/10 (dom anterior) resultam em
  "na semana" = 2.
- **CA-DSH-02** — Semana que cruza meses e anos: hoje = qui
  31/12/2026, semana de 28/12/2026 a 03/01/2027.
- **CA-DSH-03** — Hoje = segunda 00:00: a semana começa nesse dia, e o
  domingo anterior não conta.
- **CA-DSH-04** — Uma candidatura com 3 interações de resposta conta 1
  em "com resposta".
- **CA-DSH-05** — "Com resposta" + "aguardando resposta" + (encerradas
  e sem resposta) = total de candidaturas.
- **CA-DSH-06** — "Acompanhamentos pendentes" é igual à quantidade da
  seção "Vencidos" da página de Acompanhamentos para os mesmos dados.
- **CA-DSH-10** — Os rótulos indicam o escopo: "Na semana (26/10 a
  01/11)", "Com resposta (total)" e "Aguardando resposta (total)".
- **CA-DSH-07** — Após excluir uma candidatura e voltar ao dashboard,
  todos os indicadores refletem a exclusão.
- **CA-DSH-08** — Cada indicador exibe o rótulo do período.
- **CA-DSH-09** — Sem nenhuma candidatura: estado vazio com chamada
  para cadastrar, sem erro e sem divisões por zero.

## 7. Estados de interface

carregando · com dados · vazio (nenhuma candidatura cadastrada) · erro
de leitura (mensagem + "tentar novamente").

## 8. Dados afetados

Somente leitura: candidaturas (com histórico e interações) e
`AppSettings`. Nenhuma escrita.

## 9. Testes

- **Unitários:** `DashboardMetrics` com "hoje" injetado: limites de
  semana (segunda 00:00, domingo, virada de mês e de ano), contagem
  única de respostas, consistência com `FollowUpPolicy`, soma do resumo
  por status.
- **Controller (`DashboardController`):** carregamento, vazio, erro,
  atualização após mudanças nos dados.
- **Widget:** indicadores com número + rótulo + período, estado vazio.
