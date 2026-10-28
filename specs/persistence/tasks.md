# Tasks — persistence / Etapa 2

- [x] T1 — `PersistenceException` e `MapCodec` (LocalDate, DateTime
  UTC e enum por nome), com testes.
- [x] T2 — `ApplicationMapper` (`schemaVersion` 1, histórico e
  contatos embutidos), com testes CA-P-01, 02 e 06.
- [x] T3 — `FollowUpSettingsMapper`, com testes (faixas, tipos,
  versão).
- [x] T4 — `HiveDatabase` substitui o `HiveInitializer` (removido).
  `main` abre o banco pelo `Bootstrap`, e a tela de erro existente
  cobre a falha de abertura (CA-P-10).
- [x] T5 — `ApplicationRepository` + `HiveApplicationRepository`, com
  testes CA-P-03 a 07 usando Hive real em diretório temporário.
- [x] T6 — `SettingsRepository` + `HiveSettingsRepository`, com testes
  CA-P-08 e 09 e falha de gravação.
- [x] T7 — `InitialBinding` registra o banco e os repositórios como
  permanentes, via `JobTrackApp(initialBinding:)`.
- [x] T8 — CA-P-11: `hive_ce` é importado só em
  `core/database/hive_database.dart` e nos dois `repositories/hive_*`.
  Linha da Etapa 1 do roadmap corrigida.
- [x] T9 — Verificação em 2026-10-28:
  - `dart format .`: sem pendências.
  - `flutter analyze`: "No issues found!".
  - `flutter test`: 112 testes, "All tests passed!".
  - `flutter build windows --debug`: build concluído.
  - O app abriu (janela "JobTrack") e criou `applications.hive` e
    `settings.hive` em `%APPDATA%\com.andre\jobtrack_desktop\data`.
  - Reabriu normalmente depois de ser encerrado à força.

## Observações

- CA-P-10: a abertura real das boxes foi verificada executando o app.
  O teste automatizado cobre a tela de erro com falha simulada. A
  `InitialBinding` ainda não tem teste de widget próprio: ela passa a
  ser exercitada na Etapa 3, quando os controllers usarem os
  repositórios.
