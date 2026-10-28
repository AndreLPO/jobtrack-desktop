import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../../../core/ids.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../../applications/models/application.dart';
import '../../applications/models/application_status.dart';
import '../../applications/models/application_validation.dart';
import '../../applications/models/follow_up_policy.dart';
import '../../applications/models/interaction.dart';
import '../../applications/models/interaction_type.dart';
import '../../applications/repositories/application_repository.dart';
import '../../settings/models/follow_up_settings.dart';
import '../../settings/repositories/settings_repository.dart';

enum FollowUpsStatus { loading, ready, error }

/// Candidatura com a situação de acompanhamento já calculada.
class FollowUpEntry {
  const FollowUpEntry(this.application, this.state, this.attempts);

  final Application application;
  final FollowUpState state;

  /// Acompanhamentos sem resposta desde a última resposta (D-25a).
  final int attempts;
}

/// ViewModel da página "Acompanhamentos" (RF-06).
///
/// As ações gravam a candidatura inteira e só atualizam as listas depois
/// de a gravação terminar. Devolvem `false` em falha.
class FollowUpsController extends GetxController {
  FollowUpsController(
    this._repository,
    this._settingsRepository, {
    this._clock = DateTime.now,
    this._newId = generateId,
  });

  final ApplicationRepository _repository;
  final SettingsRepository _settingsRepository;
  final Clock _clock;
  final IdGenerator _newId;

  final status = FollowUpsStatus.loading.obs;
  final settings = const FollowUpSettings().obs;

  /// Vencidas, da data sugerida mais antiga para a mais recente.
  final due = <FollowUpEntry>[].obs;

  /// Limite de tentativas atingido.
  final suggestClose = <FollowUpEntry>[].obs;
  final isBusy = false.obs;

  List<Application> _applications = const [];

  LocalDate get today => _clock.today();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = FollowUpsStatus.loading;
    try {
      final snapshot = await _repository.getAll();
      settings.value = await _settingsRepository.loadFollowUp();
      _applications = snapshot.applications;
      _recompute();
      status.value = FollowUpsStatus.ready;
    } on PersistenceException {
      status.value = FollowUpsStatus.error;
    }
  }

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

  Future<bool> registerInteraction(
    Application application, {
    required LocalDate date,
    required InteractionType type,
    required String summary,
    required bool receivedResponse,
    LocalDate? nextFollowUpAt,
  }) {
    final trimmed = summary.trim();
    return _persist(
      application.registerInteraction(
        Interaction(
          id: _newId(),
          date: date,
          type: type,
          summary: trimmed.isEmpty ? null : trimmed,
          receivedResponse: receivedResponse,
          nextFollowUpAt: nextFollowUpAt,
        ),
        now: _clock(),
      ),
    );
  }

  /// "Adiar" (D-23): a data deve ser hoje ou futura.
  ValidationCode? validatePostpone(LocalDate date) =>
      validatePostponeDate(date, today: today);

  Future<bool> postpone(Application application, LocalDate date) =>
      _persist(application.postpone(date, now: _clock()));

  /// "Encerrar sem resposta" (D-23, D-25): só por ação do usuário.
  Future<bool> closeWithoutResponse(Application application) => _persist(
    application.changeStatus(
      ApplicationStatus.closedWithoutResponse,
      changeId: _newId(),
      now: _clock(),
    ),
  );

  Future<bool> _persist(Application updated) async {
    isBusy.value = true;
    try {
      await _repository.save(updated);
    } on PersistenceException {
      return false;
    } finally {
      isBusy.value = false;
    }
    _applications = [
      for (final a in _applications) a.id == updated.id ? updated : a,
    ];
    _recompute();
    return true;
  }

  void _recompute() {
    final day = today;
    final dueEntries = <(LocalDate, FollowUpEntry)>[];
    final closeEntries = <FollowUpEntry>[];
    for (final application in _applications) {
      final state = FollowUpPolicy.evaluate(application, settings.value, day);
      final entry = FollowUpEntry(
        application,
        state,
        FollowUpPolicy.attemptsSinceLastResponse(application),
      );
      switch (state) {
        case FollowUpDue(:final dueDate):
          dueEntries.add((dueDate, entry));
        case FollowUpSuggestClose():
          closeEntries.add(entry);
        case FollowUpScheduled() || FollowUpNotApplicable():
          break;
      }
    }
    dueEntries.sort((a, b) => a.$1.compareTo(b.$1));
    due.assignAll(dueEntries.map((e) => e.$2));
    closeEntries.sort(
      (a, b) => a.application.details.companyName.toLowerCase().compareTo(
        b.application.details.companyName.toLowerCase(),
      ),
    );
    suggestClose.assignAll(closeEntries);
  }
}
