import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../../../core/ids.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/local_date.dart';
import '../models/application.dart';
import '../models/application_draft.dart';
import '../models/application_status.dart';
import '../models/application_validation.dart';
import '../models/duplicate_check.dart';
import '../repositories/application_repository.dart';

enum FormLoadStatus { loading, ready, notFound, error }

enum SaveResult { saved, invalid, duplicateWarning, failed }

/// Campos de data do formulário, que podem ter texto inválido digitado.
enum FormDateField { applicationDate, jobClosingDate, manualNextFollowUpAt }

/// ViewModel do formulário de cadastro e edição de candidatura.
class ApplicationFormController extends GetxController {
  ApplicationFormController(
    this._repository, {
    this.applicationId,
    this._clock = DateTime.now,
    this._newId = generateId,
  });

  final ApplicationRepository _repository;
  final Clock _clock;
  final IdGenerator _newId;

  /// `null` no cadastro.
  final String? applicationId;

  bool get isEditing => applicationId != null;

  final loadStatus = FormLoadStatus.loading.obs;
  final draft = const ApplicationDraft().obs;
  final errors = <ApplicationField, ValidationCode>{}.obs;
  final invalidDates = <FormDateField>{}.obs;
  final isSaving = false.obs;
  final isDirty = false.obs;

  /// Candidatura apontada pelo último aviso de duplicidade.
  final duplicateOf = Rxn<Application>();

  Application? _original;
  List<Application> _existing = const [];
  bool _submitted = false;

  ApplicationStatus? get originalStatus => _original?.status;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loadStatus.value = FormLoadStatus.loading;
    try {
      final snapshot = await _repository.getAll();
      _existing = snapshot.applications;
      if (isEditing) {
        _original = _existing.firstWhereOrNull((a) => a.id == applicationId);
        if (_original == null) {
          loadStatus.value = FormLoadStatus.notFound;
          return;
        }
        draft.value = ApplicationDraft.fromApplication(_original!);
      } else {
        draft.value = ApplicationDraft(
          applicationDate: _clock.today(),
          status: ApplicationStatus.applied,
        );
      }
      isDirty.value = false;
      loadStatus.value = FormLoadStatus.ready;
    } on PersistenceException {
      loadStatus.value = FormLoadStatus.error;
    }
  }

  void edit(ApplicationDraft Function(ApplicationDraft draft) change) {
    draft.value = change(draft.value);
    isDirty.value = true;
    if (_submitted) _validate();
  }

  /// [invalid] indica texto que não é uma data dd/MM/yyyy válida.
  void setDate(FormDateField field, LocalDate? date, {bool invalid = false}) {
    if (invalid) {
      invalidDates.add(field);
    } else {
      invalidDates.remove(field);
    }
    edit(
      (d) => switch (field) {
        FormDateField.applicationDate => d.copyWith(
          applicationDate: () => date,
        ),
        FormDateField.jobClosingDate => d.copyWith(jobClosingDate: () => date),
        FormDateField.manualNextFollowUpAt => d.copyWith(
          manualNextFollowUpAt: () => date,
        ),
      },
    );
  }

  ValidationCode? errorFor(ApplicationField field) => errors[field];

  /// Valida, avisa sobre duplicidade (a menos que já confirmada) e grava.
  /// Não informa sucesso antes de a gravação terminar (RN-APP-13).
  Future<SaveResult> save({bool confirmDuplicate = false}) async {
    if (isSaving.value) return SaveResult.invalid;
    _submitted = true;
    if (!_validate() || invalidDates.isNotEmpty) return SaveResult.invalid;

    final current = draft.value;
    if (!confirmDuplicate) {
      final duplicate = findPossibleDuplicate(
        companyName: current.companyName,
        jobTitle: current.jobTitle,
        existing: _existing,
        excludingId: applicationId,
      );
      duplicateOf.value = duplicate;
      if (duplicate != null) return SaveResult.duplicateWarning;
    }

    isSaving.value = true;
    try {
      final now = _clock();
      final application = isEditing
          ? _original!.updateDetails(
              current.toDetails(),
              manualNextFollowUpAt: current.manualNextFollowUpAt,
              now: now,
            )
          : Application.create(
              id: _newId(),
              statusChangeId: _newId(),
              details: current.toDetails(),
              status: current.status!,
              now: now,
              manualNextFollowUpAt: current.manualNextFollowUpAt,
            );
      await _repository.save(application);
      _original = application;
      isDirty.value = false;
      return SaveResult.saved;
    } on PersistenceException {
      return SaveResult.failed;
    } finally {
      isSaving.value = false;
    }
  }

  bool _validate() {
    final result = validateApplicationDraft(draft.value, today: _clock.today());
    errors.assignAll({for (final e in result.reversed) e.field: e.code});
    return result.isEmpty;
  }
}
