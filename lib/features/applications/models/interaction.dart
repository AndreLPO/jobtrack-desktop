import '../../../core/time/local_date.dart';
import 'interaction_type.dart';

/// Contato com a empresa registrado pelo usuário (RF-07).
class Interaction {
  const Interaction({
    required this.id,
    required this.date,
    required this.type,
    this.summary,
    required this.receivedResponse,
    this.nextFollowUpAt,
  });

  final String id;

  /// Não pode ser futura (D-18).
  final LocalDate date;
  final InteractionType type;

  /// Opcional (D-53).
  final String? summary;

  /// Houve resposta da empresa neste contato (D-11).
  final bool receivedResponse;

  /// Data manual de próximo acompanhamento informada no contato (D-21a).
  final LocalDate? nextFollowUpAt;
}
