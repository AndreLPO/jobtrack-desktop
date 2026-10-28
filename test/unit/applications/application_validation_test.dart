import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application_channel.dart';
import 'package:jobtrack_desktop/features/applications/models/application_draft.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/application_validation.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';

void main() {
  final today = LocalDate(2026, 10, 28);

  ApplicationDraft validDraft({
    String companyName = 'Acme',
    String jobTitle = 'Dev Flutter',
    LocalDate? applicationDate,
    ApplicationChannel channel = ApplicationChannel.linkedIn,
    String channelOther = '',
    String jobUrl = '',
  }) => ApplicationDraft(
    companyName: companyName,
    jobTitle: jobTitle,
    applicationDate: applicationDate ?? today,
    channel: channel,
    channelOther: channelOther,
    status: ApplicationStatus.applied,
    jobUrl: jobUrl,
  );

  group('validateApplicationDraft', () {
    test('rascunho válido não tem erros', () {
      expect(validateApplicationDraft(validDraft(), today: today), isEmpty);
    });

    test('CA-APP-01: formulário vazio aponta cada obrigatório', () {
      final errors = validateApplicationDraft(
        const ApplicationDraft(),
        today: today,
      );
      expect(errors.toSet(), {
        const FieldError(ApplicationField.companyName, ValidationCode.required),
        const FieldError(ApplicationField.jobTitle, ValidationCode.required),
        const FieldError(
          ApplicationField.applicationDate,
          ValidationCode.required,
        ),
        const FieldError(ApplicationField.channel, ValidationCode.required),
        const FieldError(ApplicationField.status, ValidationCode.required),
      });
    });

    test('textos só com espaços contam como vazios', () {
      final errors = validateApplicationDraft(
        validDraft(companyName: '   ', jobTitle: '\t'),
        today: today,
      );
      expect(errors.map((e) => e.field), [
        ApplicationField.companyName,
        ApplicationField.jobTitle,
      ]);
    });

    test('CA-APP-02: data de candidatura futura é recusada; hoje é aceita', () {
      expect(
        validateApplicationDraft(
          validDraft(applicationDate: today.addDays(1)),
          today: today,
        ),
        [
          const FieldError(
            ApplicationField.applicationDate,
            ValidationCode.futureDate,
          ),
        ],
      );
      expect(
        validateApplicationDraft(
          validDraft(applicationDate: today),
          today: today,
        ),
        isEmpty,
      );
    });

    test('CA-APP-03: canal Outro exige descrição', () {
      expect(
        validateApplicationDraft(
          validDraft(channel: ApplicationChannel.other),
          today: today,
        ),
        [
          const FieldError(
            ApplicationField.channelOther,
            ValidationCode.required,
          ),
        ],
      );
      expect(
        validateApplicationDraft(
          validDraft(channel: ApplicationChannel.other, channelOther: 'Feira'),
          today: today,
        ),
        isEmpty,
      );
    });

    test('URL precisa ser http(s) com host', () {
      for (final url in ['www.acme.com', 'ftp://acme.com', 'https://']) {
        expect(
          validateApplicationDraft(validDraft(jobUrl: url), today: today),
          [
            const FieldError(
              ApplicationField.jobUrl,
              ValidationCode.invalidUrl,
            ),
          ],
          reason: url,
        );
      }
      for (final url in ['https://acme.com/vagas/1', 'http://acme.com', '']) {
        expect(
          validateApplicationDraft(validDraft(jobUrl: url), today: today),
          isEmpty,
          reason: url,
        );
      }
    });
  });

  group('ApplicationDraft.toDetails', () {
    test('normaliza textos e descarta descrição de canal não-Outro', () {
      final details = ApplicationDraft(
        companyName: '  Acme ',
        jobTitle: ' Dev ',
        applicationDate: LocalDate(2026, 10, 1),
        channel: ApplicationChannel.email,
        channelOther: 'ignorado',
        status: ApplicationStatus.applied,
        notes: '   ',
        city: ' Recife ',
      ).toDetails();

      expect(details.companyName, 'Acme');
      expect(details.jobTitle, 'Dev');
      expect(details.channelOther, isNull);
      expect(details.notes, isNull);
      expect(details.city, 'Recife');
    });
  });

  group('validateInteraction', () {
    test('CA-APP-12: data futura é recusada', () {
      expect(
        validateInteraction(
          date: today.addDays(1),
          type: InteractionType.call,
          summary: 'ligação',
          today: today,
        ),
        [const FieldError(InteractionField.date, ValidationCode.futureDate)],
      );
    });

    test('obrigatórios: data, tipo e resumo', () {
      expect(
        validateInteraction(
          date: null,
          type: null,
          summary: ' ',
          today: today,
        ).map((e) => e.field),
        [
          InteractionField.date,
          InteractionField.type,
          InteractionField.summary,
        ],
      );
    });

    test('contato de hoje é válido', () {
      expect(
        validateInteraction(
          date: today,
          type: InteractionType.followUpSent,
          summary: 'mensagem no LinkedIn',
          today: today,
        ),
        isEmpty,
      );
    });
  });

  test('validatePostponeDate: hoje ou futura', () {
    expect(validatePostponeDate(today, today: today), isNull);
    expect(validatePostponeDate(today.addDays(3), today: today), isNull);
    expect(
      validatePostponeDate(today.addDays(-1), today: today),
      ValidationCode.pastDate,
    );
  });
}
