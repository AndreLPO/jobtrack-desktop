# Tasks — foundation / Etapa 0

- [x] T1 — `flutter create` com `--platforms=windows`. `PROJECT.md`,
  `CLAUDE.md` e `specs/` ficaram intactos. Commit próprio.
- [x] T2 — Dependências resolvidas: `get` 4.7.3, `hive_ce` 2.22.0,
  `path_provider` 2.1.6 (D-02). **Desvio do plano:** removidos
  `hive_ce_flutter` (só serviria para o `initFlutter()`, que grava em
  *Documentos*; usamos `Hive.init()` com o caminho de D-46) e
  `cupertino_icons` (padrão do template, sem uso no Windows).
- [x] T3 — Tokens de tema (`app_colors`, `app_spacing`, `app_theme`):
  claro, elevation 0, sem gradientes.
- [x] T4 — `HiveInitializer` (Application Support/`data`) e
  `Bootstrap` com tela de erro e "Tentar novamente".
- [x] T5 — Rotas (`app_routes`, `app_pages`) e 4 páginas placeholder,
  cada uma com controller e binding próprios.
- [x] T6 — `AppShell` com `NavigationRail` (rótulos laterais a partir
  de 900px de largura), Dashboard como rota inicial e sem transição
  animada.
- [x] T7 — Janela inicial 1280×800 e título "JobTrack" em
  `windows/runner/main.cpp`.
- [x] T8 — Testes `test/widget/navigation_test.dart` (CA-F0-02/03) e
  `test/widget/bootstrap_test.dart` (CA-F0-04). Teste de exemplo do
  contador removido.
- [x] T9 — Verificação em 2026-10-28:
  - `dart format .`: 4 arquivos formatados.
  - `flutter analyze`: "No issues found!".
  - `flutter test`: 3 testes, "All tests passed!".
  - `flutter build windows --debug`: build concluído.
  - O executável abriu e ficou ativo, com a janela "JobTrack".
  - A pasta `%APPDATA%\com.andre\jobtrack_desktop\data` foi criada.
  - O conteúdo da janela foi verificado pelos testes de widget, não
    por inspeção visual.
