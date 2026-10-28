import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_draft.dart';
import 'package:jobtrack_desktop/features/applications/models/work_mode.dart';

import '../../support/application_samples.dart';

void main() {
  test('fromApplication preserva todos os dados descritivos', () {
    final application = fullApplication();
    final draft = ApplicationDraft.fromApplication(application);
    final details = draft.toDetails();

    expect(draft.status, application.status);
    expect(draft.manualNextFollowUpAt, application.manualNextFollowUpAt);
    expect(details.companyName, application.details.companyName);
    expect(details.channelOther, application.details.channelOther);
    expect(details.jobDescription, application.details.jobDescription);
    expect(details.jobClosingDate, application.details.jobClosingDate);
    expect(details.workMode, application.details.workMode);
    expect(details.notes, application.details.notes);
  });

  test('fromApplication converte opcionais nulos em texto vazio', () {
    final draft = ApplicationDraft.fromApplication(minimalApplication());
    expect(draft.jobUrl, '');
    expect(draft.notes, '');
    expect(draft.toDetails().jobUrl, isNull);
  });

  test('copyWith altera, mantém e limpa campos anuláveis', () {
    final draft = ApplicationDraft(
      companyName: 'Acme',
      jobClosingDate: LocalDate(2026, 11, 1),
      workMode: WorkMode.remote,
    );

    final changed = draft.copyWith(companyName: 'Globex');
    expect(changed.companyName, 'Globex');
    expect(changed.jobClosingDate, LocalDate(2026, 11, 1));

    final cleared = draft.copyWith(
      jobClosingDate: () => null,
      workMode: () => null,
    );
    expect(cleared.jobClosingDate, isNull);
    expect(cleared.workMode, isNull);
    expect(cleared.companyName, 'Acme');
  });
}
