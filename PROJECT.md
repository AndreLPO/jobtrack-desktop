# PROJECT.md

# JobTrack Desktop

**Tipo:** Monitor de candidaturas a vagas de emprego\
**Plataforma:** Flutter Desktop\
**Persistência local:** HiveDB\
**Arquitetura:** MVVM\
**Gerenciamento de estado e navegação:** GetX\
**Organização:** Controller por página\
**Abordagem de desenvolvimento:** Spec-Driven Development (SDD) com
princípios de Domain-Driven Design (DDD)\
**Status:** Planejamento inicial

------------------------------------------------------------------------

## 1. Visão do Produto

### 1.1 Objetivo

Desenvolver um aplicativo desktop para registrar e acompanhar vagas de
emprego às quais o usuário se candidatou, mantendo em um só lugar os
dados da vaga, da empresa, do canal utilizado para enviar o currículo,
do status do processo seletivo e dos próximos acompanhamentos
necessários.

O aplicativo deverá facilitar a resposta a perguntas como:

-   Quantas vagas foram aplicadas nesta semana?
-   Quantas empresas responderam?
-   Quais candidaturas continuam sem resposta?
-   Para quais empresas devo enviar uma mensagem de acompanhamento?
-   Em qual canal cada candidatura foi enviada?
-   Qual é o histórico de cada candidatura?

### 1.2 Princípios do produto

-   Uso simples, rápido e focado no acompanhamento diário.
-   Aplicativo desktop, sem requisitos de backend ou conta online na
    primeira versão.
-   Persistência local com HiveDB.
-   Interface flat, clean e consistente.
-   Separação entre apresentação, lógica de apresentação e acesso aos
    dados.
-   Regras de negócio explícitas e testáveis.
-   Nenhuma automação de envio de mensagens na primeira versão: o
    sistema apenas sinaliza quando acompanhar uma candidatura.
-   O usuário deve conseguir consultar e editar os registros sem
    depender de conexão com a internet.

### 1.3 Escopo inicial

-   Dashboard com indicadores de candidaturas.
-   Cadastro, edição, visualização e exclusão de candidaturas.
-   Registro da empresa, vaga, canal de candidatura, data e situação.
-   Histórico de mudanças de status e contatos, quando aplicável.
-   Filtros e busca.
-   Lista de candidaturas que precisam de acompanhamento.
-   Configurações simples para o intervalo de acompanhamento.
-   Persistência local usando HiveDB.

### 1.4 Fora do escopo inicial

-   Captura automática de vagas em sites.
-   Integração com LinkedIn, Gupy, Indeed ou outros portais.
-   Envio automático de e-mails ou mensagens.
-   Sincronização em nuvem ou colaboração entre usuários.
-   Backend, API ou autenticação remota.
-   Inteligência artificial para analisar vagas ou currículos.
-   Importação automática de candidaturas por e-mail.

Esses itens somente poderão ser adicionados após uma especificação
própria.

------------------------------------------------------------------------

## 2. Linguagem Ubíqua

Utilizar os seguintes termos de forma consistente no código, na
interface e na documentação.

  -----------------------------------------------------------------------
  Termo                               Significado
  ----------------------------------- -----------------------------------
  Candidatura                         Registro de uma inscrição do
                                      usuário para uma vaga específica.

  Vaga                                Posição profissional à qual o
                                      usuário se candidatou.

  Empresa                             Organização que oferece a vaga.

  Canal de candidatura                Plataforma ou meio pelo qual o
                                      currículo foi enviado.

  Status                              Situação atual da candidatura no
                                      processo seletivo.

  Resposta recebida                   Indicação de que a empresa ou
                                      recrutador entrou em contato após a
                                      candidatura.

  Acompanhamento                      Ação de entrar em contato para
                                      perguntar sobre o andamento do
                                      processo.

  Data da candidatura                 Data em que o usuário enviou ou
                                      registrou o envio do currículo.

  Último contato                      Data da interação mais recente
                                      relacionada à candidatura.

  Próximo acompanhamento              Data a partir da qual a candidatura
                                      deve aparecer como candidata a
                                      acompanhamento.
  -----------------------------------------------------------------------

Evitar usar "vaga" e "candidatura" como sinônimos no domínio. Uma vaga é
a oportunidade; uma candidatura é a inscrição do usuário naquela
oportunidade.

------------------------------------------------------------------------

## 3. Requisitos Funcionais

### RF-01: Cadastrar candidatura

O usuário deverá conseguir cadastrar uma candidatura com, no mínimo:

-   Nome da empresa.
-   Título da vaga.
-   Data da candidatura.
-   Canal pelo qual o currículo foi enviado.
-   Status inicial.

Campos opcionais sugeridos:

-   URL da vaga.
-   Localidade ou modalidade de trabalho.
-   Nome do recrutador ou contato.
-   Faixa salarial ou remuneração informada.
-   Observações.
-   Data do último contato.
-   Data do próximo acompanhamento.

A interface deverá validar campos obrigatórios e apresentar mensagens
claras quando houver dados inválidos.

### RF-02: Editar candidatura

O usuário poderá atualizar os dados da candidatura. Alterações de status
devem ser registradas no histórico, incluindo a data da mudança.

### RF-03: Consultar candidaturas

O usuário poderá visualizar suas candidaturas em uma listagem com, no
mínimo:

-   Empresa.
-   Título da vaga.
-   Data da candidatura.
-   Canal.
-   Status.
-   Indicador de acompanhamento, quando aplicável.

### RF-04: Buscar e filtrar

A listagem deverá permitir:

-   Busca por empresa ou título da vaga.
-   Filtro por status.
-   Filtro por canal.
-   Filtro por período de candidatura.
-   Filtro para exibir somente candidaturas que precisam de
    acompanhamento.
-   Ordenação por data da candidatura, data da última atualização e
    próximo acompanhamento.

### RF-05: Dashboard

O dashboard deverá apresentar:

-   Total de candidaturas enviadas na semana atual.
-   Total de candidaturas enviadas em um período selecionável, se isso
    não complicar a primeira versão.
-   Quantidade de candidaturas que receberam resposta.
-   Quantidade de candidaturas aguardando resposta.
-   Quantidade de candidaturas que precisam de acompanhamento.
-   Resumo por status.
-   Evolução das candidaturas por semana, caso os dados e a interface
    justifiquem o gráfico.

Os indicadores deverão ser calculados a partir dos registros
persistidos, sem armazenar contagens redundantes.

### RF-06: Acompanhamentos pendentes

O sistema deverá destacar candidaturas sem resposta que atingiram o
prazo de acompanhamento.

A lista deverá exibir:

-   Empresa.
-   Título da vaga.
-   Data da candidatura.
-   Quantidade de dias desde a candidatura ou desde o último contato.
-   Data sugerida para acompanhamento.
-   Status atual.
-   Observações ou contato, se preenchidos.

O sistema não enviará mensagens. O usuário decidirá se deseja entrar em
contato e registrará manualmente o resultado.

### RF-07: Registrar contato ou resposta

O usuário poderá registrar uma interação com a empresa, incluindo:

-   Data.
-   Tipo de interação.
-   Resumo ou observação.
-   Se houve resposta da empresa.
-   Próxima data de acompanhamento, quando aplicável.

O registro de uma resposta deve atualizar os indicadores e o histórico
da candidatura.

### RF-08: Alterar status

O usuário poderá alterar o status de uma candidatura.

Conjunto inicial sugerido de status:

-   Aplicada.
-   Resposta recebida.
-   Entrevista.
-   Teste técnico.
-   Proposta recebida.
-   Reprovada.
-   Desisti.
-   Encerrada sem resposta.

Os status poderão ser refinados durante a especificação das telas e dos
fluxos. A aplicação deverá evitar combinações incoerentes, como manter
uma candidatura marcada para acompanhamento quando ela já foi encerrada.

### RF-09: Excluir candidatura

O usuário poderá excluir uma candidatura após uma confirmação explícita.
A exclusão deverá tratar adequadamente os dados associados, como
histórico de status e contatos.

### RF-10: Configurar prazo de acompanhamento

O usuário poderá configurar o número de dias após os quais uma
candidatura sem resposta deve ser sugerida para acompanhamento.

Valor inicial sugerido: 7 dias corridos após a candidatura, ou após o
último contato relevante.

O prazo deverá ser configurável. A regra final deve ser definida na
especificação de acompanhamento, inclusive quanto a finais de semana e
feriados.

------------------------------------------------------------------------

## 4. Regras de Negócio

### RN-01: Identidade da candidatura

Cada candidatura deve possuir um identificador único e estável.

### RN-02: Datas

-   Datas de candidatura não podem ser futuras, salvo se houver uma
    necessidade explícita aprovada.
-   Datas e horários devem ser tratados de maneira consistente.
-   Indicadores semanais devem usar a semana local do usuário, de
    segunda-feira a domingo, salvo decisão posterior em contrário.
-   Testes devem cobrir limites entre semanas, meses e anos.

### RN-03: Contagem semanal

O indicador "candidaturas nesta semana" contará candidaturas cuja data
de candidatura esteja entre segunda-feira às 00:00 e o início da próxima
segunda-feira, usando a data local do dispositivo.

Cada candidatura deve ser contada uma única vez.

### RN-04: Respostas recebidas

Uma candidatura será considerada como tendo recebido resposta quando
houver um contato registrado como resposta da empresa ou quando o status
indicar inequivocamente que houve retorno.

A regra de contagem deverá evitar contar a mesma candidatura várias
vezes por ter recebido múltiplas mensagens.

A definição exata dos status que contam como resposta deve ser
centralizada no domínio, e não repetida nas telas.

### RN-05: Elegibilidade para acompanhamento

Uma candidatura será sugerida para acompanhamento quando:

-   Ainda estiver em um status ativo que permita acompanhamento.
-   Não houver resposta que torne o acompanhamento desnecessário.
-   A data atual for igual ou posterior à data de próximo
    acompanhamento.
-   Não estiver marcada como reprovada, desistência ou encerrada.

A data de próximo acompanhamento deve ser calculada ou persistida de
maneira consistente. A estratégia escolhida precisa ser documentada e
testada.

### RN-06: Registro de histórico

Mudanças relevantes de status e contatos devem preservar a data do
evento. A edição de dados descritivos não deve apagar o histórico de
interações.

### RN-07: Exclusão

A exclusão de uma candidatura deverá remover ou tratar os registros
dependentes de forma consistente. A estratégia de exclusão será
implementada no repositório e coberta por testes.

### RN-08: Persistência

Os dados devem continuar disponíveis após fechar e reabrir o aplicativo.
Falhas de leitura ou escrita devem ser tratadas sem encerrar a aplicação
silenciosamente.

------------------------------------------------------------------------

## 5. Arquitetura e Organização

### 5.1 Arquitetura obrigatória

-   Flutter Desktop.
-   MVVM: Model, View e ViewModel.
-   GetX para gerenciamento de estado, injeção de dependências e
    navegação, conforme necessário.
-   HiveDB para persistência local.
-   Um controller por página.
-   Repositórios para abstrair a persistência e reduzir o acoplamento
    entre a interface e o HiveDB.

No contexto do GetX, os controllers atuarão como ViewModels. A equipe
deverá usar a nomenclatura de forma consistente: arquivos e classes
podem utilizar o sufixo `Controller`, mas a responsabilidade
arquitetural é de ViewModel.

### 5.2 Responsabilidades

**Model / Domain** - Representar os conceitos do negócio. - Definir
enums, objetos de valor e regras que não dependem da interface. - Evitar
dependência de widgets, navegação e controllers. - Manter regras de
contagem e elegibilidade para acompanhamento centralizadas.

**View** - Renderizar os dados. - Capturar interações do usuário. -
Invocar métodos do controller. - Não executar CRUD diretamente no
HiveDB. - Não conter regras de negócio.

**ViewModel / GetX Controller** - Expor o estado necessário para a
página. - Orquestrar ações da interface. - Invocar os casos de uso ou
repositórios. - Controlar carregamento, sucesso, erro, filtros e
paginação local, quando aplicável. - Não conter widgets nem acessar
caixas Hive diretamente.

**Repository** - Definir o contrato de acesso aos dados. - Encapsular
operações de consulta, criação, atualização e exclusão. - Fornecer
consultas para dashboard e acompanhamento. - Não depender de widgets ou
controllers.

**Data Source** - Encapsular as operações específicas do HiveDB. -
Mapear modelos de persistência quando necessário. - Isolar detalhes de
adapters, boxes e chaves.

### 5.3 Regra de um controller por página

Cada página principal deverá possuir seu próprio controller.

Exemplos:

-   `DashboardController`
-   `ApplicationsController`
-   `ApplicationFormController`
-   `ApplicationDetailsController`
-   `FollowUpsController`
-   `SettingsController`

Não criar um controller global responsável por toda a aplicação.
Serviços compartilhados e repositórios podem ser registrados no GetX e
reutilizados por diferentes controllers.

Componentes reutilizáveis que não representem uma página não devem
receber controllers próprios automaticamente. Só criar controllers
adicionais quando houver uma responsabilidade de estado independente que
justifique isso.

### 5.4 Organização de diretórios sugerida

``` text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   ├── bindings/
│   │   └── initial_binding.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_spacing.dart
├── core/
│   ├── database/
│   │   ├── hive_initializer.dart
│   │   └── adapters/
│   ├── errors/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── dashboard/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── viewmodels/
│   │   └── views/
│   ├── applications/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── viewmodels/
│   │   └── views/
│   ├── follow_ups/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── viewmodels/
│   │   └── views/
│   └── settings/
│       ├── models/
│       ├── repositories/
│       ├── viewmodels/
│       └── views/
└── shared/
    ├── models/
    ├── repositories/
    └── widgets/

test/
├── unit/
├── repositories/
├── viewmodels/
└── widget/
```

Essa estrutura é uma referência inicial. Evitar criar arquivos ou
camadas vazias sem uso real. Ajustar a organização se o projeto exigir
uma separação mais clara entre domínio, aplicação e infraestrutura.

------------------------------------------------------------------------

## 6. Persistência com HiveDB

### Diretrizes

-   Inicializar o Hive antes de construir a aplicação.
-   Centralizar a abertura e o fechamento das boxes.
-   Registrar adapters de forma explícita.
-   Manter os detalhes do Hive fora das Views e dos controllers.
-   Evitar armazenar dados derivados que possam ser calculados a partir
    das candidaturas.
-   Definir identificadores estáveis para os registros.
-   Planejar evolução de schema e compatibilidade dos dados locais.
-   Testar criação, leitura, atualização e exclusão.
-   Tratar falhas de persistência com mensagens claras.
-   Não depender de conexão com a internet para acessar registros já
    armazenados.

### Entidades de dados sugeridas

**Application** - id - companyName - jobTitle - applicationDate -
channel - status - jobUrl - location - recruiterName - salaryRange -
notes - createdAt - updatedAt - lastContactAt - nextFollowUpAt

**ApplicationStatusHistory** - id - applicationId - previousStatus -
newStatus - changedAt - note

**ApplicationInteraction** - id - applicationId - interactionDate -
interactionType - summary - receivedResponse - nextFollowUpAt

**AppSettings** - followUpIntervalDays - themeMode, se houver escolha de
tema - outras preferências locais justificadas

Esses campos são uma proposta inicial, não um schema definitivo. A
especificação de dados deve decidir quais campos são obrigatórios,
opcionais ou derivados e se o histórico será persistido em boxes
separadas ou embutido no registro da candidatura.

------------------------------------------------------------------------

## 7. Design System e Experiência Visual

### 7.1 Direção visual

O aplicativo deverá adotar um design flat e clean, com aparência
profissional, leve e funcional.

Princípios: - Hierarquia visual clara. - Espaçamento consistente. -
Tipografia legível. - Poucos elementos decorativos. - Superfícies
planas. - Bordas discretas. - Contraste adequado para textos e
estados. - Densidade de informação apropriada para desktop.

### 7.2 Restrições visuais

-   Não utilizar gradientes.
-   Não utilizar sombras fortes.
-   Evitar cartões excessivamente arredondados ou com decoração
    exagerada.
-   Evitar animações que prejudiquem a produtividade.
-   Não depender apenas de cores para comunicar status.
-   Evitar excesso de cores de destaque.

### 7.3 Componentes visuais

-   Navegação lateral ou outra navegação desktop consistente.
-   Indicadores de dashboard com números destacados e rótulos claros.
-   Tabelas ou listas adequadas para consultar muitas candidaturas.
-   Badges discretos para status.
-   Formulários com rótulos explícitos e validação próxima ao campo.
-   Estados de carregamento, erro, vazio e sucesso.
-   Confirmação antes de excluir registros.
-   Diálogos e menus dimensionados para desktop.

### 7.4 Tema

Criar tokens centralizados para: - Cores. - Espaçamento. - Tipografia. -
Bordas e raios. - Estados de status. - Dimensões e comportamento
responsivo da janela.

Não espalhar valores visuais arbitrários pelas páginas.

### 7.5 Responsividade desktop

A interface deverá funcionar em tamanhos de janela desktop comuns, sem
assumir que a janela estará sempre maximizada. Tabelas, formulários,
navegação e diálogos devem se adaptar à largura disponível.

------------------------------------------------------------------------

## 8. Dashboard e Métricas

### Métricas principais

**Candidaturas na semana** - Contar candidaturas pela data de envio. -
Usar semana de segunda-feira a domingo. - Não contar registros
duplicados.

**Candidaturas com resposta** - Contar candidaturas únicas que atendam à
regra de resposta recebida. - Não contar interações múltiplas da mesma
candidatura como múltiplas respostas no indicador de candidaturas
respondidas.

**Aguardando resposta** - Contar candidaturas ativas que ainda não
receberam resposta. - Excluir candidaturas encerradas conforme a regra
de domínio.

**Acompanhamentos pendentes** - Contar candidaturas elegíveis cuja data
de acompanhamento chegou ou passou. - Excluir candidaturas encerradas e
as que não exigem mais contato.

### Regras de implementação

-   A lógica das métricas deve ficar fora dos widgets.
-   Reutilizar regras centralizadas no domínio ou em serviços de
    consulta apropriados.
-   Não manter contadores duplicados no HiveDB sem uma justificativa de
    desempenho comprovada.
-   Testar datas-limite e alterações de status.
-   Exibir claramente o período ao qual cada indicador se refere.

------------------------------------------------------------------------

## 9. Tratamento de Erros e Estado da Interface

Toda página que carrega dados deve tratar:

-   Estado inicial.
-   Carregamento, quando aplicável.
-   Estado com dados.
-   Estado vazio.
-   Erro de leitura ou escrita.
-   Confirmação de operações destrutivas.

Mensagens de erro devem ser compreensíveis para o usuário. Detalhes
técnicos podem ser registrados em logs locais sem expor informações
desnecessárias.

O controller não deve ocultar falhas de persistência nem exibir sucesso
antes da conclusão da operação.

------------------------------------------------------------------------

## 10. Estratégia de Testes

### Testes unitários de domínio

-   Regras de status.
-   Cálculo de semana atual.
-   Contagem de candidaturas respondidas.
-   Elegibilidade para acompanhamento.
-   Cálculo da próxima data de acompanhamento.

### Testes de repositório

-   Criar, consultar, atualizar e excluir candidaturas.
-   Persistência após reabertura das boxes.
-   Consultas por status, canal e intervalo de datas.
-   Tratamento de registros relacionados e histórico.

### Testes de controllers

-   Carregamento dos dados.
-   Estados de sucesso e erro.
-   Filtros e busca.
-   Atualização de indicadores após alterações.
-   Ações de acompanhamento.

### Testes de widgets

-   Formulários e validações.
-   Navegação.
-   Estado vazio.
-   Confirmação de exclusão.
-   Exibição de status e indicadores.

### Qualidade mínima

-   Executar `dart format`.
-   Executar `flutter analyze`.
-   Executar os testes relevantes.
-   Não considerar uma funcionalidade concluída quando os testes
    falharem sem justificativa documentada.

------------------------------------------------------------------------

## 11. Spec-Driven Development

Toda funcionalidade relevante deve seguir este fluxo:

1.  Entender o objetivo e o comportamento esperado.
2.  Inspecionar os documentos e o código existente.
3.  Escrever ou atualizar a especificação.
4.  Definir critérios de aceitação verificáveis.
5.  Identificar regras de domínio, telas e persistência afetadas.
6.  Criar um plano de implementação.
7.  Dividir o plano em tarefas pequenas.
8.  Implementar por etapas.
9.  Executar testes e análise estática.
10. Revisar a implementação contra a especificação.
11. Atualizar a documentação afetada.

Não iniciar uma funcionalidade complexa sem especificação. Pequenas
correções podem usar um fluxo simplificado, desde que não alterem regras
de negócio ou contratos de persistência de maneira não documentada.

------------------------------------------------------------------------

## 12. Definition of Done

Uma funcionalidade estará concluída quando:

-   [ ] A especificação e os critérios de aceitação forem atendidos.
-   [ ] As responsabilidades MVVM estiverem respeitadas.
-   [ ] Cada página tiver seu controller próprio quando necessário.
-   [ ] As Views não acessarem HiveDB diretamente.
-   [ ] As regras de negócio estiverem fora dos widgets.
-   [ ] A persistência estiver testada.
-   [ ] Os estados de erro e vazio estiverem tratados.
-   [ ] O visual seguir o design flat e clean.
-   [ ] Não houver gradientes ou sombras fortes.
-   [ ] `dart format` tiver sido executado.
-   [ ] `flutter analyze` não apresentar problemas não justificados.
-   [ ] Os testes relevantes estiverem passando.
-   [ ] A documentação afetada estiver atualizada.

------------------------------------------------------------------------

## 13. Instruções para o Claude Code

Antes de implementar: 1. Leia `PROJECT.md` e `CLAUDE.md`, se existir. 2.
Inspecione o repositório e os arquivos existentes. 3. Identifique a fase
atual do SDD e as especificações aplicáveis. 4. Não presuma que decisões
pendentes já foram aprovadas. 5. Apresente dúvidas que possam alterar
regras de negócio ou arquitetura.

Durante a implementação: - Respeite a stack e as restrições visuais
deste documento. - Use GetX de maneira consistente. - Mantenha um
controller por página. - Não acesse HiveDB diretamente nas Views ou
controllers. - Evite abstrações desnecessárias. - Não adicione
integrações externas sem aprovação. - Não implemente funcionalidades
fora do escopo aprovado. - Preserve os dados locais ao alterar schemas e
adapters.

Ao finalizar cada tarefa: - Liste os arquivos alterados. - Informe os
testes executados e seus resultados. - Descreva decisões relevantes. -
Informe limitações e tarefas pendentes. - Confirme a aderência aos
critérios de aceitação.

------------------------------------------------------------------------

## 14. Decisões Pendentes

As decisões abaixo podem ser tomadas durante a fase de especificação,
antes de implementar os componentes correspondentes:

-   [ ] Versões e compatibilidade de Flutter, Dart, GetX e HiveDB.
-   [ ] Sistema operacional desktop prioritário e sistemas secundários
    desejados.
-   [ ] Campos obrigatórios e opcionais do cadastro de candidatura.
-   [ ] Lista final de canais de candidatura.
-   [ ] Lista final de status e transições permitidas.
-   [ ] Regra exata para considerar uma candidatura como respondida.
-   [ ] Prazo e política de acompanhamento.
-   [ ] Histórico de status e contatos: estrutura de persistência.
-   [ ] Estratégia de backup e exportação dos dados locais.
-   [ ] Identidade visual final, incluindo paleta e tipografia.

------------------------------------------------------------------------

## 15. Princípio Final

O sistema deve reduzir o esforço mental de acompanhar candidaturas,
oferecendo uma visão confiável e simples do que foi enviado, do que teve
retorno e do que merece acompanhamento.

A prioridade é a clareza dos dados, a consistência das regras e a
facilidade de uso. A arquitetura deve apoiar esses objetivos, sem
transformar um aplicativo desktop individual em uma plataforma
desnecessariamente complexa.
