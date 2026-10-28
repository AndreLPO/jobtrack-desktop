# Spec — Configurações (settings)

- **Status:** Rascunho. Pronta para aprovação, sem bloqueios abertos.
- **Origem:** PROJECT.md RF-10; §6 (`AppSettings`). Decisões D-20, D-21,
  D-25, D-40, D-41.

## 1. Objetivo

Permitir que o usuário configure as regras de acompanhamento:

- o prazo, em dias corridos;
- o limite de tentativas sem resposta.

## 2. Escopo

- Visualizar e alterar `followUpIntervalDays` e `maxFollowUpAttempts`.
- Valores padrão quando não houver configuração salva.
- Persistência local.
- Texto explicativo sobre como as regras são aplicadas.

## 3. Exclusões

- Tema claro/escuro (D-41: só tema claro na v1).
- Lista editável de canais (D-12: lista fixa).
- Feriados e dias úteis (D-20).
- Backup e exportação (D-43).
- Perfil do usuário e modelo de mensagem: dependem de D-50 e serão
  tratados na Etapa 7b, se aprovados.

## 4. Regras de negócio

- **RN-SET-01** — `followUpIntervalDays`: inteiro de 1 a 90, padrão 7
  (D-40).
- **RN-SET-02** — `maxFollowUpAttempts`: inteiro de 1 a 10, padrão 3
  (D-25, D-40).
- **RN-SET-03** — Valores fora da faixa, vazios ou não numéricos são
  recusados com mensagem junto ao campo.
- **RN-SET-04** — Sem registro salvo, o app usa os padrões sem gravar
  nada até o usuário salvar.
- **RN-SET-05** — As alterações valem imediatamente para todas as
  candidaturas sem data manual, porque o acompanhamento é sempre
  calculado (D-21).
- **RN-SET-06** — As configurações são um registro único com
  `schemaVersion`.

## 5. Fluxos

**F1 — Alterar.** Navegação lateral → Configurações → editar os campos
→ "Salvar" → validação → persistência → feedback de sucesso. Dashboard
e Acompanhamentos refletem o novo valor na próxima visualização.

**F2 — Descartar.** Sair da página sem salvar mantém os valores
anteriores. O aviso de alterações não salvas fica a confirmar no
plano.

## 6. Critérios de aceitação

- **CA-SET-01** — Sem configuração salva, a página exibe 7 dias e 3
  tentativas.
- **CA-SET-02** — Salvar 10 dias e 2 tentativas e reabrir o app exibe
  10 e 2.
- **CA-SET-03** — Os valores 0, 91, -1, vazio ou texto (prazo) e 0 ou
  11 (tentativas) são recusados, e nada é persistido.
- **CA-SET-04** — Mudar o prazo de 7 para 3 faz uma candidatura sem
  resposta aplicada há 4 dias passar a vencida.
- **CA-SET-05** — Mudar o limite de 3 para 2 faz uma candidatura com 2
  tentativas sem resposta passar a "sugerido encerrar".
- **CA-SET-06** — Numa falha de escrita, aparece mensagem de erro, e os
  valores anteriores continuam em vigor.

## 7. Estados de interface

carregando · editando · erro de validação · salvando · salvo (feedback
discreto) · erro de leitura/escrita.

## 8. Dados afetados

Box de configurações, com registro único `AppSettings`. É lida por
dashboard, follow-ups e applications (indicador).

## 9. Testes

- **Repositório:** padrões sem registro, salvar e reler depois de
  reabrir as boxes, erro de escrita.
- **Controller (`SettingsController`):** validação das duas faixas,
  salvar, erro, sem sucesso prematuro.
- **Widget:** campos com rótulos explícitos, mensagens junto ao campo.
- **Domínio:** CA-SET-04 e CA-SET-05 com `FollowUpPolicy`.
