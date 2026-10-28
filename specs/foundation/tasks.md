# Tasks — foundation / Etapa 0

- [ ] T1 — `flutter create` com `--platforms=windows`. Conferir que
  `PROJECT.md`, `CLAUDE.md` e `specs/` ficaram intactos. Primeiro
  commit.
- [ ] T2 — `flutter pub add get hive_ce hive_ce_flutter path_provider`.
  Registrar em `decisions.md` (D-02) as versões resolvidas.
- [ ] T3 — Tokens de tema (`app_colors`, `app_spacing`, `app_theme`):
  claro, elevation 0, sem gradientes.
- [ ] T4 — `HiveInitializer` (pasta de Application Support) e `main`
  com a tela de erro de inicialização.
- [ ] T5 — Rotas (`app_routes`, `app_pages`) e as 4 páginas
  placeholder, cada uma com seu controller e binding.
- [ ] T6 — `AppShell` com navegação lateral e o Dashboard como rota
  inicial.
- [ ] T7 — Tamanho inicial e título da janela em
  `windows/runner/main.cpp`.
- [ ] T8 — Testes de widget: navegação (CA-F0-02/03) e tela de erro
  (CA-F0-04). Remover o teste de exemplo do contador.
- [ ] T9 — `dart format .`, `flutter analyze`, `flutter test`,
  `flutter build windows` (ou `flutter run`) para validar o CA-F0-01.
  Reportar as saídas e fazer o commit.
