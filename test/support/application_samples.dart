import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/core/time/local_date.dart';
import 'package:jobtrack_desktop/features/applications/models/application.dart';
import 'package:jobtrack_desktop/features/applications/models/application_channel.dart';
import 'package:jobtrack_desktop/features/applications/models/application_details.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction.dart';
import 'package:jobtrack_desktop/features/applications/models/interaction_type.dart';
import 'package:jobtrack_desktop/features/applications/models/work_mode.dart';

final _created = DateTime(2026, 10, 1, 9, 15, 30, 250);

/// Candidatura com todos os campos preenchidos, 3 mudanças de status e
/// 2 contatos.
Application fullApplication({String id = 'app-full'}) {
  return Application.create(
        id: id,
        statusChangeId: '$id-sc1',
        details: ApplicationDetails(
          companyName: 'Acme',
          jobTitle: 'Dev Flutter Sênior',
          applicationDate: LocalDate(2026, 9, 30),
          channel: ApplicationChannel.other,
          channelOther: 'Feira de carreiras',
          jobUrl: 'https://acme.com/vagas/1',
          atsName: 'Greenhouse',
          resumeVersion: 'CV-flutter-v3',
          jobDescription: 'Descrição longa\ncom várias linhas e acentuação.',
          jobClosingDate: LocalDate(2026, 10, 15),
          workMode: WorkMode.hybrid,
          city: 'Recife',
          contactName: 'Maria (recrutadora)',
          salaryRange: 'R\$ 15k–18k',
          notes: 'Indicação de colega',
        ),
        status: ApplicationStatus.applied,
        now: _created,
        manualNextFollowUpAt: LocalDate(2026, 10, 20),
      )
      .changeStatus(
        ApplicationStatus.responseReceived,
        changeId: '$id-sc2',
        now: _created.add(const Duration(days: 3)),
        note: 'Retorno por e-mail',
      )
      .registerInteraction(
        Interaction(
          id: '$id-i1',
          date: LocalDate(2026, 10, 4),
          type: InteractionType.messageReceived,
          summary: 'Convite para entrevista',
          receivedResponse: true,
          nextFollowUpAt: LocalDate(2026, 10, 9),
        ),
        now: _created.add(const Duration(days: 3, hours: 1)),
      )
      .changeStatus(
        ApplicationStatus.interview,
        changeId: '$id-sc3',
        now: _created.add(const Duration(days: 5)),
      )
      .registerInteraction(
        Interaction(
          id: '$id-i2',
          date: LocalDate(2026, 10, 8),
          type: InteractionType.interview,
          summary: 'Entrevista técnica',
          receivedResponse: false,
        ),
        now: _created.add(const Duration(days: 7)),
      )
      .postpone(
        LocalDate(2026, 10, 20),
        now: _created.add(const Duration(days: 8)),
      );
}

/// Candidatura só com os campos obrigatórios.
Application minimalApplication({
  String id = 'app-min',
  String companyName = 'Globex',
}) {
  return Application.create(
    id: id,
    statusChangeId: '$id-sc1',
    details: ApplicationDetails(
      companyName: companyName,
      jobTitle: 'QA',
      applicationDate: LocalDate(2026, 10, 2),
      channel: ApplicationChannel.linkedIn,
    ),
    status: ApplicationStatus.applied,
    now: _created,
  );
}

/// Compara campo a campo, sem depender do mapper.
void expectSameApplication(Application actual, Application expected) {
  expect(actual.id, expected.id);
  expect(actual.status, expected.status);
  expect(actual.manualNextFollowUpAt, expected.manualNextFollowUpAt);
  expect(actual.createdAt, expected.createdAt);
  expect(actual.updatedAt, expected.updatedAt);

  final a = actual.details;
  final e = expected.details;
  expect(a.companyName, e.companyName);
  expect(a.jobTitle, e.jobTitle);
  expect(a.applicationDate, e.applicationDate);
  expect(a.channel, e.channel);
  expect(a.channelOther, e.channelOther);
  expect(a.jobUrl, e.jobUrl);
  expect(a.atsName, e.atsName);
  expect(a.resumeVersion, e.resumeVersion);
  expect(a.jobDescription, e.jobDescription);
  expect(a.jobClosingDate, e.jobClosingDate);
  expect(a.workMode, e.workMode);
  expect(a.city, e.city);
  expect(a.contactName, e.contactName);
  expect(a.salaryRange, e.salaryRange);
  expect(a.notes, e.notes);

  expect(actual.statusHistory.length, expected.statusHistory.length);
  for (var i = 0; i < expected.statusHistory.length; i++) {
    final ac = actual.statusHistory[i];
    final ec = expected.statusHistory[i];
    expect(ac.id, ec.id);
    expect(ac.previousStatus, ec.previousStatus);
    expect(ac.newStatus, ec.newStatus);
    expect(ac.changedAt, ec.changedAt);
    expect(ac.note, ec.note);
  }

  expect(actual.interactions.length, expected.interactions.length);
  for (var i = 0; i < expected.interactions.length; i++) {
    final ai = actual.interactions[i];
    final ei = expected.interactions[i];
    expect(ai.id, ei.id);
    expect(ai.date, ei.date);
    expect(ai.type, ei.type);
    expect(ai.summary, ei.summary);
    expect(ai.receivedResponse, ei.receivedResponse);
    expect(ai.nextFollowUpAt, ei.nextFollowUpAt);
  }
}
