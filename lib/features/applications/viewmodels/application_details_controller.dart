import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../../../core/ids.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../settings/models/message_template.dart';
import '../../settings/repositories/settings_repository.dart';
import '../models/application.dart';
import '../models/application_status.dart';
import '../models/application_validation.dart';
import '../models/interaction.dart';
import '../models/interaction_type.dart';
import '../repositories/application_repository.dart';

enum DetailsStatus { loading, ready, notFound, error }

/// ViewModel da página de detalhes da candidatura.
///
/// Todas as ações gravam a candidatura inteira e só atualizam o estado
/// depois de a gravação terminar (RN-APP-13). Devolvem `false` em falha
/// de gravação.
class ApplicationDetailsController extends GetxController {
  ApplicationDetailsController(
    this._repository,
    this._settingsRepository, {
    required this.applicationId,
    this._clock = DateTime.now,
    this._newId = generateId,
  });

  final ApplicationRepository _repository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;
  final IdGenerator _newId;
  final String applicationId;

  final status = DetailsStatus.loading.obs;
  final application = Rxn<Application>();
  final isBusy = false.obs;

  LocalDate get today => _clock.today();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = DetailsStatus.loading;
    try {
      final found = await _repository.getById(applicationId);
      application.value = found;
      status.value = found == null
          ? DetailsStatus.notFound
          : DetailsStatus.ready;
    } on PersistenceException {
      status.value = DetailsStatus.error;
    }
  }

  /// Escolher o status atual não grava nada (RN-APP-05).
  Future<bool> changeStatus(ApplicationStatus newStatus, {String? note}) {
    final current = application.value!;
    if (newStatus == current.status) return Future.value(true);
    return _persist(
      current.changeStatus(
        newStatus,
        changeId: _newId(),
        now: _clock(),
        note: _normalize(note),
      ),
    );
  }

  /// Usada pelo diálogo antes de confirmar (D-18, D-53, D-54).
  List<FieldError<InteractionField>> validateContact({
    required LocalDate? date,
    required InteractionType? type,
    required LocalDate? nextFollowUpAt,
  }) => validateInteraction(
    date: date,
    type: type,
    nextFollowUpAt: nextFollowUpAt,
    today: today,
  );

  /// Espera dados já validados por [validateContact].
  Future<bool> registerInteraction({
    required LocalDate date,
    required InteractionType type,
    required String summary,
    required bool receivedResponse,
    LocalDate? nextFollowUpAt,
  }) {
    final interaction = Interaction(
      id: _newId(),
      date: date,
      type: type,
      summary: _normalize(summary),
      receivedResponse: receivedResponse,
      nextFollowUpAt: nextFollowUpAt,
    );
    return _persist(
      application.value!.registerInteraction(interaction, now: _clock()),
    );
  }

  /// Exclui um contato registrado por engano (D-55).
  Future<bool> removeInteraction(String interactionId) => _persist(
    application.value!.removeInteraction(interactionId, now: _clock()),
  );

  /// Texto para "Copiar mensagem" (D-27), ou `null` se o modelo não
  /// puder ser lido.
  Future<String?> followUpMessage() async {
    try {
      final template = await _settingsRepository.loadMessageTemplate();
      return MessageTemplate.render(template, application.value!);
    } on PersistenceException {
      return null;
    }
  }

  Future<bool> delete() async {
    isBusy.value = true;
    try {
      await _repository.delete(applicationId);
      return true;
    } on PersistenceException {
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> _persist(Application updated) async {
    isBusy.value = true;
    try {
      await _repository.save(updated);
      application.value = updated;
      return true;
    } on PersistenceException {
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  static String? _normalize(String? text) {
    final trimmed = text?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
