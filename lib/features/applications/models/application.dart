import '../../../core/time/local_date.dart';
import 'application_details.dart';
import 'application_status.dart';
import 'interaction.dart';
import 'status_change.dart';

/// Candidatura: agregado raiz, com histórico de status e contatos
/// embutidos (D-16). Imutável: as operações devolvem uma nova instância.
///
/// As operações assumem entradas já validadas (ver
/// `application_validation.dart`).
class Application {
  Application({
    required this.id,
    required this.details,
    required this.status,
    required this.manualNextFollowUpAt,
    required this.createdAt,
    required this.updatedAt,
    required List<StatusChange> statusHistory,
    required List<Interaction> interactions,
  }) : assert(statusHistory.isNotEmpty),
       assert(statusHistory.last.newStatus == status),
       statusHistory = List.unmodifiable(statusHistory),
       interactions = List.unmodifiable(interactions);

  /// Cria a candidatura com o `StatusChange` inicial (RN-APP-04).
  factory Application.create({
    required String id,
    required String statusChangeId,
    required ApplicationDetails details,
    required ApplicationStatus status,
    required DateTime now,
    LocalDate? manualNextFollowUpAt,
  }) {
    return Application(
      id: id,
      details: details,
      status: status,
      manualNextFollowUpAt: manualNextFollowUpAt,
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        StatusChange(
          id: statusChangeId,
          previousStatus: null,
          newStatus: status,
          changedAt: now,
        ),
      ],
      interactions: const [],
    );
  }

  final String id;
  final ApplicationDetails details;
  final ApplicationStatus status;

  /// Data manual de próximo acompanhamento (D-21a). Tem prioridade sobre
  /// as demais regras de acompanhamento.
  final LocalDate? manualNextFollowUpAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Em ordem cronológica; o último item corresponde ao [status] atual.
  final List<StatusChange> statusHistory;

  /// Em ordem de registro.
  final List<Interaction> interactions;

  /// Respondida = status que indica resposta ou algum contato com
  /// resposta (D-11, RN-APP-07).
  bool get hasResponse =>
      status.indicatesResponse || interactions.any((i) => i.receivedResponse);

  /// Contato mais recente: maior data; no empate, o último registrado.
  Interaction? get latestInteraction {
    Interaction? latest;
    for (final interaction in interactions) {
      if (latest == null || !interaction.date.isBefore(latest.date)) {
        latest = interaction;
      }
    }
    return latest;
  }

  /// Derivado, não persistido (D-14).
  LocalDate? get lastContactAt => latestInteraction?.date;

  /// Mudança que levou ao [status] atual.
  StatusChange get lastStatusChange => statusHistory.last;

  /// Altera o status registrando no histórico. Não faz nada se o status
  /// for o mesmo (RN-APP-05).
  Application changeStatus(
    ApplicationStatus newStatus, {
    required String changeId,
    required DateTime now,
    String? note,
  }) {
    if (newStatus == status) return this;
    return _copy(
      status: newStatus,
      updatedAt: now,
      statusHistory: [
        ...statusHistory,
        StatusChange(
          id: changeId,
          previousStatus: status,
          newStatus: newStatus,
          changedAt: now,
          note: note,
        ),
      ],
    );
  }

  /// Registra um contato. A data manual passa a ser a informada no
  /// contato, ou nenhuma (RN-APP-09).
  Application registerInteraction(
    Interaction interaction, {
    required DateTime now,
  }) {
    return _copy(
      updatedAt: now,
      interactions: [...interactions, interaction],
      manualNextFollowUpAt: () => interaction.nextFollowUpAt,
    );
  }

  /// Atualiza os dados descritivos e a data manual, preservando
  /// histórico e contatos (RN-APP-10).
  Application updateDetails(
    ApplicationDetails details, {
    required LocalDate? manualNextFollowUpAt,
    required DateTime now,
  }) {
    return _copy(
      details: details,
      updatedAt: now,
      manualNextFollowUpAt: () => manualNextFollowUpAt,
    );
  }

  /// Ação "Adiar" da lista de acompanhamentos (D-23).
  Application postpone(LocalDate date, {required DateTime now}) {
    return _copy(updatedAt: now, manualNextFollowUpAt: () => date);
  }

  Application _copy({
    ApplicationDetails? details,
    ApplicationStatus? status,
    LocalDate? Function()? manualNextFollowUpAt,
    required DateTime updatedAt,
    List<StatusChange>? statusHistory,
    List<Interaction>? interactions,
  }) {
    return Application(
      id: id,
      details: details ?? this.details,
      status: status ?? this.status,
      manualNextFollowUpAt: manualNextFollowUpAt != null
          ? manualNextFollowUpAt()
          : this.manualNextFollowUpAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      interactions: interactions ?? this.interactions,
    );
  }
}
