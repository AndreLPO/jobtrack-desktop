import '../../../core/database/map_codec.dart';
import '../../../core/time/local_date.dart';
import '../models/application.dart';
import '../models/application_channel.dart';
import '../models/application_details.dart';
import '../models/application_status.dart';
import '../models/interaction.dart';
import '../models/interaction_type.dart';
import '../models/status_change.dart';
import '../models/work_mode.dart';

/// Formato gravado da candidatura (D-03), com histórico e contatos
/// embutidos (D-16).
///
/// Ao mudar o formato: incrementar [schemaVersion] e migrar as versões
/// anteriores em [fromMap], preservando os dados existentes.
abstract final class ApplicationMapper {
  static const schemaVersion = 1;

  static Map<String, Object?> toMap(Application application) {
    final details = application.details;
    return {
      'schemaVersion': schemaVersion,
      'id': application.id,
      'companyName': details.companyName,
      'jobTitle': details.jobTitle,
      'applicationDate': MapCodec.encodeDate(details.applicationDate),
      'channel': details.channel.name,
      'channelOther': details.channelOther,
      'jobUrl': details.jobUrl,
      'atsName': details.atsName,
      'resumeVersion': details.resumeVersion,
      'jobDescription': details.jobDescription,
      'jobClosingDate': _encodeOptionalDate(details.jobClosingDate),
      'workMode': details.workMode?.name,
      'city': details.city,
      'contactName': details.contactName,
      'salaryRange': details.salaryRange,
      'notes': details.notes,
      'status': application.status.name,
      'manualNextFollowUpAt': _encodeOptionalDate(
        application.manualNextFollowUpAt,
      ),
      'createdAt': MapCodec.encodeDateTime(application.createdAt),
      'updatedAt': MapCodec.encodeDateTime(application.updatedAt),
      'statusHistory': [
        for (final change in application.statusHistory)
          {
            'id': change.id,
            'previousStatus': change.previousStatus?.name,
            'newStatus': change.newStatus.name,
            'changedAt': MapCodec.encodeDateTime(change.changedAt),
            'note': change.note,
          },
      ],
      'interactions': [
        for (final interaction in application.interactions)
          {
            'id': interaction.id,
            'date': MapCodec.encodeDate(interaction.date),
            'type': interaction.type.name,
            'summary': interaction.summary,
            'receivedResponse': interaction.receivedResponse,
            'nextFollowUpAt': _encodeOptionalDate(interaction.nextFollowUpAt),
          },
      ],
    };
  }

  /// Lança [FormatException] se o registro estiver incompleto, inválido
  /// ou em versão de formato não suportada.
  static Application fromMap(Map<dynamic, dynamic> map) {
    final version = MapCodec.requireInt(map['schemaVersion'], 'schemaVersion');
    if (version != schemaVersion) {
      throw FormatException('Versão de formato não suportada', version);
    }

    final status = MapCodec.decodeEnum(
      ApplicationStatus.values,
      map['status'],
      'status',
    );
    final history = [
      for (final item in MapCodec.requireMapList(
        map['statusHistory'],
        'statusHistory',
      ))
        _statusChangeFromMap(item),
    ];
    if (history.isEmpty || history.last.newStatus != status) {
      throw const FormatException('Histórico de status inconsistente');
    }

    return Application(
      id: MapCodec.requireString(map['id'], 'id'),
      details: ApplicationDetails(
        companyName: MapCodec.requireString(map['companyName'], 'companyName'),
        jobTitle: MapCodec.requireString(map['jobTitle'], 'jobTitle'),
        applicationDate: MapCodec.decodeDate(
          map['applicationDate'],
          'applicationDate',
        ),
        channel: MapCodec.decodeEnum(
          ApplicationChannel.values,
          map['channel'],
          'channel',
        ),
        channelOther: MapCodec.optionalString(
          map['channelOther'],
          'channelOther',
        ),
        jobUrl: MapCodec.optionalString(map['jobUrl'], 'jobUrl'),
        atsName: MapCodec.optionalString(map['atsName'], 'atsName'),
        resumeVersion: MapCodec.optionalString(
          map['resumeVersion'],
          'resumeVersion',
        ),
        jobDescription: MapCodec.optionalString(
          map['jobDescription'],
          'jobDescription',
        ),
        jobClosingDate: MapCodec.decodeOptionalDate(
          map['jobClosingDate'],
          'jobClosingDate',
        ),
        workMode: MapCodec.decodeOptionalEnum(
          WorkMode.values,
          map['workMode'],
          'workMode',
        ),
        city: MapCodec.optionalString(map['city'], 'city'),
        contactName: MapCodec.optionalString(map['contactName'], 'contactName'),
        salaryRange: MapCodec.optionalString(map['salaryRange'], 'salaryRange'),
        notes: MapCodec.optionalString(map['notes'], 'notes'),
      ),
      status: status,
      manualNextFollowUpAt: MapCodec.decodeOptionalDate(
        map['manualNextFollowUpAt'],
        'manualNextFollowUpAt',
      ),
      createdAt: MapCodec.decodeDateTime(map['createdAt'], 'createdAt'),
      updatedAt: MapCodec.decodeDateTime(map['updatedAt'], 'updatedAt'),
      statusHistory: history,
      interactions: [
        for (final item in MapCodec.requireMapList(
          map['interactions'],
          'interactions',
        ))
          _interactionFromMap(item),
      ],
    );
  }

  static String? _encodeOptionalDate(LocalDate? date) =>
      date == null ? null : MapCodec.encodeDate(date);

  static StatusChange _statusChangeFromMap(Map<dynamic, dynamic> map) {
    return StatusChange(
      id: MapCodec.requireString(map['id'], 'statusHistory.id'),
      previousStatus: MapCodec.decodeOptionalEnum(
        ApplicationStatus.values,
        map['previousStatus'],
        'statusHistory.previousStatus',
      ),
      newStatus: MapCodec.decodeEnum(
        ApplicationStatus.values,
        map['newStatus'],
        'statusHistory.newStatus',
      ),
      changedAt: MapCodec.decodeDateTime(
        map['changedAt'],
        'statusHistory.changedAt',
      ),
      note: MapCodec.optionalString(map['note'], 'statusHistory.note'),
    );
  }

  static Interaction _interactionFromMap(Map<dynamic, dynamic> map) {
    return Interaction(
      id: MapCodec.requireString(map['id'], 'interactions.id'),
      date: MapCodec.decodeDate(map['date'], 'interactions.date'),
      type: MapCodec.decodeEnum(
        InteractionType.values,
        map['type'],
        'interactions.type',
      ),
      summary: MapCodec.optionalString(map['summary'], 'interactions.summary'),
      receivedResponse: MapCodec.requireBool(
        map['receivedResponse'],
        'interactions.receivedResponse',
      ),
      nextFollowUpAt: MapCodec.decodeOptionalDate(
        map['nextFollowUpAt'],
        'interactions.nextFollowUpAt',
      ),
    );
  }
}
