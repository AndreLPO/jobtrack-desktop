import 'package:get/get.dart';

import '../../../core/errors/persistence_exception.dart';
import '../models/follow_up_settings.dart';
import '../repositories/settings_repository.dart';

enum SettingsStatus { loading, ready, error }

enum SettingsSaveResult { saved, invalid, failed }

/// ViewModel da página "Configurações".
class SettingsController extends GetxController {
  SettingsController(this._repository, {this.dataDirectory});

  final SettingsRepository _repository;

  /// Pasta dos dados locais, exibida para o usuário (D-43).
  final String? dataDirectory;

  final status = SettingsStatus.loading.obs;
  final intervalText = ''.obs;
  final attemptsText = ''.obs;
  final intervalInvalid = false.obs;
  final attemptsInvalid = false.obs;
  final isSaving = false.obs;
  final _saved = const FollowUpSettings().obs;

  FollowUpSettings get saved => _saved.value;

  /// Há alterações não salvas (D-59).
  bool get isDirty =>
      intervalText.value.trim() != '${_saved.value.intervalDays}' ||
      attemptsText.value.trim() != '${_saved.value.maxAttempts}';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = SettingsStatus.loading;
    try {
      _applySaved(await _repository.loadFollowUp());
      status.value = SettingsStatus.ready;
    } on PersistenceException {
      status.value = SettingsStatus.error;
    }
  }

  void setInterval(String text) {
    intervalText.value = text;
    intervalInvalid.value = false;
  }

  void setAttempts(String text) {
    attemptsText.value = text;
    attemptsInvalid.value = false;
  }

  /// Valida as faixas (RN-SET-01 a 03) e grava. Em falha, os valores
  /// salvos anteriormente continuam valendo (CA-SET-06).
  Future<SettingsSaveResult> save() async {
    final interval = int.tryParse(intervalText.value.trim());
    final attempts = int.tryParse(attemptsText.value.trim());
    intervalInvalid.value =
        interval == null || !FollowUpSettings.isValidIntervalDays(interval);
    attemptsInvalid.value =
        attempts == null || !FollowUpSettings.isValidMaxAttempts(attempts);
    if (intervalInvalid.value || attemptsInvalid.value) {
      return SettingsSaveResult.invalid;
    }

    final settings = FollowUpSettings(
      intervalDays: interval!,
      maxAttempts: attempts!,
    );
    isSaving.value = true;
    try {
      await _repository.saveFollowUp(settings);
      _applySaved(settings);
      return SettingsSaveResult.saved;
    } on PersistenceException {
      return SettingsSaveResult.failed;
    } finally {
      isSaving.value = false;
    }
  }

  void _applySaved(FollowUpSettings settings) {
    _saved.value = settings;
    intervalText.value = '${settings.intervalDays}';
    attemptsText.value = '${settings.maxAttempts}';
    intervalInvalid.value = false;
    attemptsInvalid.value = false;
  }
}
