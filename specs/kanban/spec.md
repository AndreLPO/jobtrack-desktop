# Spec — Quadro Kanban de candidaturas

- **Status:** Implementada (2026-10-28), com as decisões K-01 a K-04 em
  `specs/decisions.md`. Ver `tasks.md`.
- **Origem:** pedido do usuário (2026-10-28). É uma funcionalidade nova,
  fora do escopo inicial do PROJECT.md, que pede especificação própria
  (§1.4, §11). Reaproveita RF-03, RF-04, RF-08, RN-06; decisões D-10,
  D-11, D-23, D-56, D-59.
- **Depende de:** applications (modelo, `changeStatus`, filtros),
  follow-ups (indicador).

## 1. Objetivo

Visualizar as candidaturas agrupadas por status em colunas, e mudar o
status arrastando um cartão de uma coluna para outra. É a mesma
informação da listagem, organizada pelo andamento do processo.

## 2. Escopo

- Modo de visualização "Quadro", além da "Lista" atual (K-01).
- Colunas por status (K-02), com a quantidade de cartões no cabeçalho.
- Cartão com empresa, vaga, data da candidatura e indicador de
  acompanhamento. Clicar no cartão abre os detalhes.
- Arrastar e soltar entre colunas, que muda o status (K-03).
- Alternativa sem arrastar: menu do cartão com "Mover para…", para
  quem usa teclado e para acessibilidade.
- Busca, filtros e ordenação da barra atual também valem no quadro.

## 3. Exclusões

- Ordem manual dentro da coluna, porque exigiria gravar posição: a
  ordem segue a ordenação escolhida na barra.
- Colunas personalizadas, limites por coluna (WIP) e raias.
- Mudança automática de status (D-11 continua valendo).
- Edição de dados no próprio cartão.

## 4. Regras de negócio

- **RN-KB-01** — Cada candidatura aparece em exatamente uma coluna, a
  do seu status atual.
- **RN-KB-02** — Soltar um cartão em outra coluna equivale a "Alterar
  status" (F3): gera um `StatusChange` com data/hora e respeita as
  transições livres, inclusive reabrir (D-10). Soltar na mesma coluna
  não grava nada (RN-APP-05).
- **RN-KB-03** — O cartão só muda de coluna depois de a gravação
  terminar. Se a gravação falhar, ele volta para a coluna de origem e o
  app avisa (RN-APP-13).
- **RN-KB-04** — O filtro de status da barra limita as colunas
  exibidas. Os demais filtros limitam os cartões.
- **RN-KB-05** — Dentro da coluna, a ordem é a escolhida em "Ordenar"
  (data da candidatura, última atualização ou próximo acompanhamento).
- **RN-KB-06** — O agrupamento é uma função pura do domínio, sem
  persistir nada novo. A única exceção possível é a preferência de modo
  de visualização (K-04).

## 5. Fluxos

**F1 — Alternar modo.** Candidaturas → "Lista | Quadro" → o quadro
aparece com os mesmos filtros aplicados.

**F2 — Mover por arrastar.** Arrastar o cartão → as colunas que aceitam
o cartão são destacadas → soltar → gravar → o cartão aparece na nova
coluna, com a mensagem prevista em K-03.

**F3 — Mover pelo menu.** Cartão → "⋮" → "Mover para…" → escolher o
status → mesma gravação de F2.

**F4 — Abrir.** Clicar no cartão → detalhes. Ao voltar, o quadro
recarrega.

## 6. Critérios de aceitação

- **CA-KB-01** — Com candidaturas em 3 status, cada uma aparece uma vez,
  na coluna do seu status, e o cabeçalho mostra a contagem correta.
- **CA-KB-02** — Arrastar de "Aplicada" para "Entrevista" muda o status,
  grava "Aplicada → Entrevista" no histórico, e o cartão aparece na nova
  coluna.
- **CA-KB-03** — Soltar na própria coluna não altera o histórico.
- **CA-KB-04** — Com falha de gravação, o cartão permanece na coluna de
  origem e o app mostra um aviso de erro.
- **CA-KB-05** — "Mover para…" produz o mesmo efeito do arrastar.
- **CA-KB-06** — Busca e filtros reduzem os cartões, e o filtro de
  status reduz as colunas. A contagem do cabeçalho reflete o que está
  visível.
- **CA-KB-07** — O cartão mostra o indicador de acompanhamento com ícone
  e texto, igual ao da listagem.
- **CA-KB-08** — Em uma janela de 960px de largura, o quadro rola
  horizontalmente, sem cortar cartões.
- **CA-KB-09** — Uma coluna vazia mostra "Nenhuma candidatura" e
  continua aceitando cartões soltos.

## 7. Estados de interface

carregando · com dados · nenhuma candidatura (mesmo estado da lista) ·
nenhuma por filtro · erro de leitura · gravando o movimento · falha ao
mover.

## 8. Dados afetados

- Candidaturas: só `status`, `statusHistory` e `updatedAt`, através de
  `Application.changeStatus`.
- Opcional, conforme K-04: a preferência de modo de visualização na box
  `settings`.

## 9. Decisões (aprovadas em 2026-10-28)

- **K-01 — Onde fica:** alternância "Lista | Quadro" dentro de
  Candidaturas, com os mesmos busca, filtros e ordenação.
- **K-02 — Colunas:** as 5 ativas (Aplicada, Resposta recebida,
  Entrevista, Teste técnico, Proposta recebida) mais "Encerradas", que
  agrupa Reprovada, Desisti e Encerrada sem resposta. Os cartões dessa
  coluna mostram o badge do status. Ao soltar nela, o usuário escolhe
  qual dos três status.
- **K-03 — Ao soltar:** muda na hora e o aviso oferece "Desfazer", que
  registra a mudança inversa no histórico (D-55).
- **K-04 — Lembrar o modo** entre sessões: sim, com a preferência
  gravada na box `settings` e "Lista" como padrão.
