# Plano — Etapa 0: Base executável

- **Status:** Implementado (2026-10-28). Desvios registrados em `tasks.md` (T2).
- **Referências:** PROJECT.md §5, §6, §7, §9; `specs/roadmap.md`
  (Etapa 0); decisões D-02, D-04, D-41, D-42, D-44.

## Objetivo

Ter um app Windows que abre, mostra a navegação lateral com as 4
páginas principais (sem funcionalidades) e inicializa o Hive de forma
confiável. Se o Hive falhar, o app mostra uma tela de erro
compreensível em vez de fechar.

## Fora desta etapa

Modelos de domínio, adapters, repositórios, formulários e qualquer
regra de negócio, que ficam para as Etapas 1 e 2. As boxes **não**
são abertas aqui; só o Hive é inicializado.

## Abordagem

1. **Criar o projeto** na pasta atual:
   `flutter create --platforms=windows --project-name jobtrack_desktop --org com.andre .`
   - Não sobrescreve `PROJECT.md`, `CLAUDE.md` nem `specs/`. Cria
     `README.md`, `.gitignore`, `pubspec.yaml`, `lib/`, `test/` e
     `windows/`.
   - O `lib/main.dart` e o `test/widget_test.dart` gerados (contador de
     exemplo) serão substituídos.
2. **Dependências.** Adicionar com `flutter pub add` (a resolução
   confirma a compatibilidade) e fixar com `^` na versão resolvida:

   | Pacote            | Última verificada | Motivo                                  |
   |-------------------|-------------------|-----------------------------------------|
   | `get`             | 4.7.3             | Estado, rotas, DI (obrigatório)          |
   | `hive_ce`         | 2.22.0            | Persistência (D-02)                      |
   | `hive_ce_flutter` | 2.5.0             | Inicialização do Hive no Flutter         |
   | `path_provider`   | 2.1.6             | Pasta de dados do app (ver nota abaixo)  |
   | `flutter_lints`   | 6.0.0 (dev)       | Já vem do `flutter create`               |

   O `uuid` (4.6.0) fica para a Etapa 1, quando os ids passarem a
   existir.
3. **Pasta dos dados.** O `Hive.initFlutter()` usa por padrão a pasta
   *Documentos* do usuário no Windows, que é visível e fácil de apagar
   por engano. Proposta: usar `getApplicationSupportDirectory()`
   (`%APPDATA%\<org>\jobtrack_desktop`) + subpasta `data`, e mostrar
   esse caminho na Etapa 9 (D-43).
4. **Estrutura**, seguindo a recomendação D-44 e criando só o que for
   usado:

   ```text
   lib/
   ├── main.dart                     # init Hive → runApp ou tela de erro
   ├── app/
   │   ├── app.dart                  # GetMaterialApp, tema, rotas
   │   ├── routes/app_routes.dart    # nomes das rotas
   │   ├── routes/app_pages.dart     # GetPage + bindings por página
   │   ├── theme/app_colors.dart
   │   ├── theme/app_spacing.dart    # espaçamento + raios
   │   ├── theme/app_theme.dart      # ThemeData claro, elevation 0
   │   └── shell/app_shell.dart      # navegação lateral + área de conteúdo
   ├── core/database/hive_initializer.dart
   └── features/
       ├── dashboard/      {viewmodels/dashboard_controller.dart, views/dashboard_page.dart}
       ├── applications/   {viewmodels/applications_controller.dart, views/applications_page.dart}
       ├── follow_ups/     {viewmodels/follow_ups_controller.dart, views/follow_ups_page.dart}
       └── settings/       {viewmodels/settings_controller.dart, views/settings_page.dart}
   ```

   Cada página tem um controller vazio registrado via `Bindings` da
   rota, para validar o padrão de um controller por página. Não há
   controller global.
5. **Navegação.** Uma `NavigationRail` (ou lista lateral simples) com
   Dashboard, Candidaturas, Acompanhamentos e Configurações. Mostra o
   item selecionado por texto e ícone, não só por cor. O Dashboard é a
   rota inicial.
6. **Tema provisório (D-42).**
   - Tema claro, fundo neutro, uma cor de destaque, bordas de 1px e
     raio pequeno (4–6px).
   - `elevation: 0` em AppBar, Card e diálogos. Sem gradientes.
   - Fonte padrão do sistema (Segoe UI no Windows), sem pacote de
     fontes.
7. **Janela.** Ajustar o tamanho inicial (ex.: 1280×800) e o título
   "JobTrack" em `windows/runner/main.cpp`, sem dependência extra. O
   tamanho mínimo exigiria código nativo ou o pacote `window_manager`;
   fica para a Etapa 9 se houver necessidade.
8. **Falha de inicialização.** `main` captura a exceção do
   `HiveInitializer`, registra o detalhe em `debugPrint`/log e roda um
   `MaterialApp` mínimo com a mensagem "Não foi possível abrir os dados
   locais" + "Tentar novamente".

## Critérios de aceitação

- **CA-F0-01** — `flutter run -d windows` abre o app no Dashboard.
- **CA-F0-02** — Clicar em cada item da navegação mostra a página
  correspondente, com o título correto, e o item fica marcado como
  selecionado.
- **CA-F0-03** — Cada página tem seu próprio controller, criado pela
  rota e descartado ao sair (verificável no teste).
- **CA-F0-04** — Uma falha simulada na inicialização do Hive mostra a
  tela de erro e não fecha o app.
- **CA-F0-05** — `dart format`, `flutter analyze` (sem problemas) e
  `flutter test` passam.
- **CA-F0-06** — Nenhum widget usa gradiente nem `elevation` maior que
  0, e nenhuma página usa cor ou espaçamento fora dos tokens.

## Testes

- Widget: navegação entre as 4 páginas, a partir do Dashboard inicial.
- Widget: tela de erro de inicialização (injetando um inicializador que
  falha).
- O teste do `HiveInitializer` real com diretório temporário fica para
  a Etapa 2, junto com as boxes.

## Perguntas para aprovação

1. **`--org`:** que identificador usar no projeto (ex.: `com.andre`,
   `br.com.seudominio`)? Ele aparece no caminho da pasta de dados.
2. **Pasta dos dados:** aprovar `%APPDATA%` (Application Support) em
   vez de *Documentos* (item 3)?
3. **Estrutura de pastas (D-44):** aprovar a estrutura acima?
