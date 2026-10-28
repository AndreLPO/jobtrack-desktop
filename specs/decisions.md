# Decisões, ambiguidades e contradições

Registro das decisões do projeto. Itens **Pendentes** não podem ser
assumidos na implementação.

Legenda de impacto: **B** = bloqueia a spec/etapa indicada;
**N** = não bloqueia.

Fontes: `PROJECT.md`; respostas do usuário em 2026-10-28; material de
orientação "Como acompanhar candidaturas e fazer follow-up"
(atualizado em 01/10/2026, baseado em orientação geral do Indeed),
adotado pelo usuário como base para novas regras e campos.

---

## Decisões aprovadas (2026-10-28)

### Ambiente e escopo

- **D-02 — Persistência:** `hive_ce` + `hive_ce_flutter` (fork mantido
  do Hive, mesma API), em vez do `hive` original, abandonado desde 2022.
  Versões resolvidas: `get` ^4.7.3, `hive_ce` ^2.22.0, `uuid` ^4.6.0 (Etapa 1),
  `path_provider` ^2.1.6. O `hive_ce_flutter` foi dispensado: usamos
  `Hive.init()` com o caminho de D-46. O ambiente verificado tem
  Flutter 3.47.7 e Dart 3.13.5.
- **D-04 — Plataforma:** somente Windows na v1.
- **D-16 — Histórico:** o histórico de status e os contatos ficam
  **embutidos** no registro da candidatura.
- **D-17 — Exclusão:** exclusão física com confirmação. A cascata é
  implícita, porque os dados dependentes estão embutidos (D-16).
- **D-30 — Dashboard v1:** sem gráfico semanal e sem período
  selecionável, que ficam para depois da v1.
- **D-41 — Tema:** somente tema claro na v1.
- **D-43 — Backup:** fora da v1. Documentar onde ficam os arquivos do
  Hive.

### Status e resposta

- **D-10 — Status:** lista final com 8 status:
  - **Ativos:** Aplicada, Resposta recebida, Entrevista, Teste
    técnico, Proposta recebida.
  - **Encerrados:** Reprovada, Desisti, Encerrada sem resposta.
  - **Transições livres**, inclusive para reabrir uma candidatura
    encerrada. Toda mudança fica no histórico.
  - O status inicial do cadastro pode ser qualquer um, porque as
    transições são livres.
- **D-11 — Resposta recebida:** a candidatura conta como respondida
  quando o status está em {Resposta recebida, Entrevista, Teste
  técnico, Proposta recebida, Reprovada} **ou** existe algum contato
  marcado como resposta. Registrar uma resposta **não** altera o status
  automaticamente.

### Cadastro

- **D-12 — Canais:** lista fixa: LinkedIn, Gupy, Site da empresa,
  E-mail, Indicação, Outro. "Outro" exige descrição em texto. O canal
  é diferente do ATS (ver D-13).
- **D-13 — Campos:**
  - **Novos campos opcionais vindos do material:**
    - ATS usado: texto livre, com exemplos como Greenhouse, Lever e
      Workday;
    - versão do currículo enviada;
    - cópia da descrição da vaga: texto longo;
    - data de encerramento da vaga.
  - **Localidade:** modalidade opcional (Presencial/Híbrido/Remoto) +
    cidade em texto livre.
  - **Duplicidade:** se já existir candidatura com a mesma empresa e
    vaga, o app **avisa, mas permite salvar**.
- **D-14 — Último contato:** **calculado** a partir do contato mais
  recente e removido do formulário de cadastro.
- **D-15 — Tipos de contato:** Acompanhamento enviado, Mensagem
  recebida, Ligação, Entrevista, Agradecimento enviado, Outro.
- **D-18 — Datas:** a data de um contato **não pode ser futura**.
  Agendamentos usam a próxima data de acompanhamento.

### Acompanhamento

- **D-20 — Prazo:** em **dias corridos**. A base é o **último contato
  registrado**, de qualquer tipo. Sem contatos, a base é a data da
  candidatura.
- **D-21 — Data sugerida:** **calculada**, nunca armazenada. Mudar o
  prazo nas Configurações recalcula todas as candidaturas, exceto as
  que têm data marcada manualmente.
- **D-22 — Depois de uma resposta:** a sugestão é **automática**:
  - **Entrevista:** acompanhamento (agradecimento) 1 dia depois da data
    da entrevista. A data da entrevista é a do contato do tipo
    "Entrevista" mais recente; sem esse contato, é a data da mudança de
    status para Entrevista.
  - **Resposta recebida, Teste técnico e Proposta recebida:** prazo
    padrão a partir do último contato.
  - **Reprovada** é encerrada e não gera sugestão.
- **D-25 — Limite de tentativas (novo, vindo do material):** padrão de
  3, configurável. Ao atingir o limite de acompanhamentos enviados sem
  resposta, o app **para de sugerir** e mostra "sugerido encerrar". O
  status só muda se o usuário confirmar.
- **D-26 — Data de encerramento da vaga (novo, vindo do material):**
  se preenchida, a **primeira** data sugerida é o encerramento + 2 dias
  corridos, em vez de candidatura + prazo.
- **D-40 — Faixas das Configurações:** prazo de 1 a 90 dias (padrão
  7); limite de tentativas de 1 a 10 (padrão 3).

### Dashboard

- **D-31 — Indicadores:** "Com resposta" e "Aguardando resposta" usam
  o **total geral**. Só "Na semana" tem período, e os rótulos devem
  deixar isso claro.

### Novas funcionalidades

- **D-27 — Modelo de mensagem de acompanhamento (novo, vindo do
  material):** texto pronto para copiar, com dados da candidatura
  preenchidos. Entra na v1 como etapa logo após Acompanhamentos. Nada é
  enviado: o usuário só copia o texto. O conteúdo e a configuração do
  modelo estão em D-50.

### Detalhes do acompanhamento (2026-10-28, segunda rodada)

- **D-25a — O que conta como tentativa:** contatos do tipo
  "Acompanhamento enviado" registrados **depois do último evento de
  resposta**. Evento de resposta = contato com resposta, ou mudança
  para um status que indica resposta. Assim, uma nova resposta zera a
  contagem. "Agradecimento enviado" não conta como tentativa.
- **D-28 — Limite depois de uma resposta:** o limite de tentativas
  também vale depois de uma resposta, com a contagem zerada a cada
  resposta.
- **D-21a — Data manual:** a candidatura tem um único campo,
  `manualNextFollowUpAt`, preenchido pelo formulário, pelo contato mais
  recente ou pela ação "Adiar". Ao registrar um novo contato, o campo
  recebe o valor informado nesse contato, ou fica vazio se nada for
  informado. A data manual tem prioridade sobre todas as outras regras,
  inclusive o limite.
- **D-23 — Ações da lista de Acompanhamentos:** Registrar contato,
  Adiar, Encerrar sem resposta (com confirmação) e Copiar mensagem,
  esta última disponível só a partir da Etapa 7b.

### Etapa 1 (2026-10-28, aprovação do plano de domínio)

- **D-22b — Entrevista sem contato do tipo Entrevista:** a data
  sugerida é a data da mudança para Entrevista + 1 dia, mesmo que
  existam outros contatos depois dela. O prazo padrão só volta a valer
  quando existe um contato do tipo Entrevista e outro contato depois
  dele. Isso corrige a inconsistência entre D-22 e a versão anterior
  da RN-FU-05.
- **D-25b — Tentativa no mesmo dia da resposta:** não conta. Só contam
  acompanhamentos com data estritamente posterior à do último evento
  de resposta.
- **D-47 — Técnica de domínio:**
  - `LocalDate` para campos sem hora;
  - entidades imutáveis;
  - `uuid` para ids;
  - erros de validação como códigos, com as mensagens na interface;
  - código em `features/*/models/`.

### Etapa 2 (2026-10-28, aprovação do plano de persistência)

- **D-03 — Formato gravado:** mapas simples com mappers escritos à mão
  e `schemaVersion` em cada registro. Enums gravados pelo nome,
  `LocalDate` como `yyyy-MM-dd` e `DateTime` como ISO-8601 em UTC. Sem
  adapters nem `build_runner`.
- **D-48 — Registro ilegível:** a listagem mostra os demais registros e
  avisa quantos não puderam ser lidos. O registro ilegível nunca é
  apagado nem sobrescrito automaticamente. Configurações ilegíveis
  usam os padrões, sem gravar por cima até o usuário salvar.
- **D-49 — Consultas:** o repositório oferece só criar, ler, atualizar
  e excluir. Filtros por status, canal e período são funções puras do
  domínio, testadas na Etapa 5. Isso substitui os "testes de consulta
  no repositório" do PROJECT.md §10.

### Etapa 3 (2026-10-28, aprovação do plano de listagem e formulário)

- **D-06 — Idioma e formato:** interface em pt-BR, datas `dd/MM/yyyy`,
  código em inglês. `flutter_localizations` (do Flutter SDK) com
  `locale` pt_BR para o calendário e os textos padrão do Material.
- **D-51 — Ações na listagem antes dos detalhes:** clicar na linha abre
  a edição, e o menu "⋮" tem Editar e Excluir. Na Etapa 4, o clique
  passa a abrir os detalhes.
- **D-52 — Alterações não salvas:** ao sair do formulário com mudanças,
  o app pergunta "Descartar alterações?".

### Etapa 4 (2026-10-28, aprovação do plano de detalhes)

- **D-19 — `updatedAt`:** qualquer alteração persistida atualiza o
  campo: dados, status, contatos e data manual.
- **D-53 — Resumo do contato:** opcional. Tipo e data bastam para
  contatos simples. O formato gravado continua na `schemaVersion` 1,
  porque `summary` passa a aceitar `null` e todos os registros
  existentes continuam válidos, sem migração.
- **D-54 — Próxima data no contato:** deve ser hoje ou futura, como na
  ação "Adiar". A data manual editada no formulário continua sem essa
  validação (ver `specs/domain/tasks.md`).
- **D-55 — Correção de contatos:** um contato registrado pode ser
  excluído, com confirmação, mas não editado. Excluir um contato não
  altera a data manual de próximo acompanhamento. O histórico de status
  é imutável.

- **I-3 — Base sem contato após resposta (D-22), confirmada:** quando
  o status muda para Resposta recebida, Teste técnico ou Proposta
  recebida e não existe contato posterior, a base é a data da mudança
  de status.
- **I-4 — Data de encerramento da vaga e contatos (D-26),
  confirmada:** a regra vale só enquanto não houver contatos. Depois do
  primeiro contato, vale a regra do último contato.
- **D-05 — Controle de versão:** repositório git inicializado em
  2026-10-28, na branch `main`.

### Base técnica (2026-10-28, aprovação do plano da Etapa 0)

- **D-44 — Estrutura de diretórios:** a estrutura de
  `specs/foundation/plan.md` foi aprovada.
  - Domínio e repositório de candidaturas ficam em
    `features/applications/`.
  - Dashboard e follow-ups têm apenas `viewmodels/` e `views/` e usam
    serviços de domínio puros.
  - Uma classe por repositório (interface + implementação Hive), sem
    DataSource separado nem camada de casos de uso, até haver
    justificativa concreta.
- **D-45 — Identificador do projeto:** `--org com.andre`, nome do
  projeto `jobtrack_desktop`.
- **D-46 — Pasta dos dados:** `getApplicationSupportDirectory()` +
  `data`, o que no Windows resulta em
  `%APPDATA%\com.andre\jobtrack_desktop\data`. A pasta *Documentos* não
  é usada.

---

## Pendentes

### D-01 — Ferramenta SDD
- **Status:** Pendente (N)
- **Situação:** usa-se provisoriamente a estrutura simples em `specs/`.
  O CLI OpenSpec 1.14.1 está instalado globalmente, mas não foi
  inicializado aqui.

### D-42 — Identidade visual
- **Status:** Pendente (N; tokens provisórios na Etapa 0)
- **Recomendação:** tokens neutros, fonte do sistema e uma cor de
  destaque. Ajustar depois.

### D-50 — Conteúdo do modelo de mensagem
- **Status:** Pendente (B: Etapa 7b)
- **Perguntas:**
  - O modelo do material está em inglês. Ele será fixo, em pt-BR,
    bilíngue ou editável nas Configurações?
  - Os campos "anos de experiência", "stack", "conquista", "seu nome"
    e "LinkedIn" pertencem ao usuário e não à candidatura. Para
    preenchê-los automaticamente, seria preciso um "perfil" nas
    Configurações; a alternativa é deixá-los como marcadores para
    editar depois de copiar.

---

## Fora do escopo (registrado do material)

- Orientação sobre indicações (referral): é uma recomendação de
  conduta, não uma funcionalidade. "Indicação" existe como canal
  (D-12), e quem indicou pode ser registrado no campo de contato.
