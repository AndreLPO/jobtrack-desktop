# Plano — Etapa 2: Persistência

- **Status:** Implementado (2026-10-28). Decisões D-03, D-48 e D-49; ver `tasks.md`.
- **Referências:** PROJECT.md §5.2, §6, RN-07, RN-08;
  `specs/applications/spec.md` (§10, §11),
  `specs/settings/spec.md` (RN-SET-04 a 06, §9); decisões D-02, D-03,
  D-16, D-17, D-46, D-47; CLAUDE.md ("Dados locais").

## Objetivo

Gravar e ler candidaturas e configurações no Hive de forma confiável,
sem que nenhuma View ou controller conheça o Hive. Falhas viram erros
tipados e compreensíveis. Os dados continuam disponíveis depois de
fechar e reabrir o app.

## Fora desta etapa

- Telas e controllers, que começam na Etapa 3. Os repositórios ficam
  registrados no GetX, mas ainda não são usados por nenhuma página.
- Filtros, busca e ordenação: ficam como funções puras de domínio na
  Etapa 5 (ver item 5).
- Backup, exportação e migração de versões antigas: ainda não existe
  versão antiga.

## Abordagem

1. **Formato gravado (D-03, recomendação (c)).** Cada candidatura é
   gravada como um `Map` simples (strings, números, booleanos, listas e
   mapas), sem adapters nem gerador de código.
   - Chave: o `id` da candidatura.
   - Cada registro leva `schemaVersion: 1`.
   - Enums são gravados pelo **nome** (`"interview"`), não pela
     posição, para que reordenar o enum não corrompa dados.
   - `LocalDate` vira `"yyyy-MM-dd"`. `DateTime` vira ISO-8601 em UTC.
   - Histórico e contatos ficam embutidos como listas de mapas (D-16).

   A conversão fica em mappers explícitos (`ApplicationMapper`,
   `FollowUpSettingsMapper`), com teste de ida e volta para todos os
   campos.
2. **Boxes.**
   - `applications`: uma entrada por candidatura.
   - `settings`: uma entrada única com a chave `followUp`.

   A abertura e o fechamento ficam centralizados em `HiveDatabase`
   (substitui o `HiveInitializer`): `open()` inicializa o Hive no
   caminho de D-46 e abre as duas boxes. O `Bootstrap` chama `open()`,
   e a tela de erro existente cobre falhas na abertura.
   - Mantenho o padrão `crashRecovery: true` do Hive. Ele descarta só
     uma gravação incompleta no fim do arquivo (por exemplo, queda de
     energia), nunca registros completos.
   - Nenhuma rotina apaga ou recria boxes (CLAUDE.md).
3. **Repositórios.** Uma interface e uma implementação Hive para cada
   um (D-44):

   ```dart
   abstract interface class ApplicationRepository {
     Future<ApplicationsSnapshot> getAll();   // ver item 6
     Future<Application?> getById(String id);
     Future<void> save(Application application); // cria ou atualiza
     Future<void> delete(String id);             // remove tudo (D-17)
   }

   abstract interface class SettingsRepository {
     Future<FollowUpSettings> loadFollowUp(); // padrões se não houver registro
     Future<void> saveFollowUp(FollowUpSettings settings);
   }
   ```

   O agregado é gravado inteiro em uma única operação, então salvar ou
   excluir uma candidatura com seu histórico é atômico por natureza.
4. **Erros (RN-08).** `PersistenceException` em `core/errors/`, com o
   tipo (`read`/`write`) e a causa original. Os repositórios capturam
   erros do Hive e de E/S e relançam esse tipo. Os controllers (Etapa
   3+) só conhecem `PersistenceException`.
5. **Consultas.** O repositório oferece só criar, ler, atualizar e
   excluir. Filtros por status, canal e período serão funções puras
   aplicadas à lista carregada, na Etapa 5. Motivo: o volume é pequeno
   (uso individual), todos os indicadores precisam da lista inteira de
   qualquer forma, e filtrar no domínio permite testar sem Hive.
   - **Diferença em relação ao PROJECT.md §10:** os "testes de consulta
     por status, canal e período" passam a ser testes unitários da
     Etapa 5, não testes de repositório.
6. **Registro ilegível (pergunta 2).** Um registro pode estar ilegível
   por dados corrompidos, versão de formato desconhecida ou enum
   inexistente. Proposta: `getAll()` devolve
   `ApplicationsSnapshot(applications, unreadableIds)`. A interface
   (Etapa 3) mostra as demais candidaturas e um aviso "N registros não
   puderam ser lidos". O registro ilegível **não é apagado nem
   sobrescrito**.
   - Registro com `schemaVersion` maior que o suportado (dados de uma
     versão mais nova do app) também conta como ilegível.
   - Configurações ilegíveis: usar os padrões, registrar em log e não
     gravar por cima até o usuário salvar.
7. **Injeção (GetX).** `app/bindings/initial_binding.dart` registra
   `HiveDatabase`, `ApplicationRepository` e `SettingsRepository` como
   permanentes. Isso não é um controller global: são serviços
   compartilhados (§5.3).
8. **Roadmap.** Corrigir a linha da Etapa 1, onde o `Clock` foi
   adiado para a Etapa 3.

## Arquivos

```text
lib/core/errors/persistence_exception.dart
lib/core/database/hive_database.dart         # substitui hive_initializer.dart
lib/core/database/map_codec.dart             # LocalDate/DateTime/enum <-> valores simples
lib/features/applications/repositories/
  application_repository.dart                # interface + ApplicationsSnapshot
  hive_application_repository.dart
  application_mapper.dart
lib/features/settings/repositories/
  settings_repository.dart
  hive_settings_repository.dart
  follow_up_settings_mapper.dart
lib/app/bindings/initial_binding.dart
test/repositories/...                        # Hive real em diretório temporário
test/unit/...                                # mappers
```

## Critérios de aceitação

- **CA-P-01** — Ida e volta de uma candidatura com todos os campos
  preenchidos, histórico com 3 mudanças e 2 contatos devolve valores
  iguais em todos os campos.
- **CA-P-02** — Ida e volta de uma candidatura só com os obrigatórios:
  os opcionais continuam nulos.
- **CA-P-03 (CA-APP-04)** — Salvar, fechar o Hive e reabrir no mesmo
  diretório: a candidatura continua lá, igual.
- **CA-P-04** — `save` de uma candidatura existente atualiza o
  registro, sem duplicar.
- **CA-P-05 (CA-APP-16)** — `delete` remove o registro com histórico e
  contatos, e ele não volta depois de reabrir.
- **CA-P-06** — Registro com enum desconhecido, campo obrigatório
  ausente ou `schemaVersion` maior que o suportado vai para
  `unreadableIds`, os demais são devolvidos, e o registro continua
  intacto na box.
- **CA-P-07 (CA-APP-17)** — Uma falha de gravação (box fechada)
  resulta em `PersistenceException` do tipo `write`.
- **CA-P-08 (CA-SET-01/02)** — Sem registro, as configurações carregam
  os padrões sem gravar nada. Depois de salvar 10/2 e reabrir, carregam
  10/2.
- **CA-P-09** — Configuração ilegível ou fora da faixa resulta nos
  padrões, sem sobrescrever o registro.
- **CA-P-10** — O app abre normalmente com as boxes, e a falha ao
  abrir mostra a tela de erro existente (teste de widget do
  `Bootstrap` mantido).
- **CA-P-11** — Nenhum arquivo fora de `core/database/` e
  `*/repositories/hive_*` importa `hive_ce`.

## Perguntas para aprovação

1. **Formato (D-03):** mapas simples com `schemaVersion` (recomendado)
   ou adapters gerados (`hive_ce_generator` + `build_runner`)?
2. **Registro ilegível:** mostrar os demais com aviso (recomendado) ou
   bloquear a listagem inteira com erro?
3. **Consultas:** só CRUD no repositório, com filtros no domínio
   (recomendado), ou filtros no repositório, como sugere o §10?
