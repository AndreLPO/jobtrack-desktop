import '../../../core/database/map_codec.dart';
import '../models/follow_up_settings.dart';

/// Formato gravado das configurações de acompanhamento (D-03).
abstract final class FollowUpSettingsMapper {
  static const schemaVersion = 1;

  static Map<String, Object?> toMap(FollowUpSettings settings) => {
    'schemaVersion': schemaVersion,
    'intervalDays': settings.intervalDays,
    'maxAttempts': settings.maxAttempts,
  };

  /// Lança [FormatException] se o registro for inválido ou estiver fora
  /// das faixas permitidas.
  static FollowUpSettings fromMap(Map<dynamic, dynamic> map) {
    final version = MapCodec.requireInt(map['schemaVersion'], 'schemaVersion');
    if (version != schemaVersion) {
      throw FormatException('Versão de formato não suportada', version);
    }
    final intervalDays = MapCodec.requireInt(
      map['intervalDays'],
      'intervalDays',
    );
    final maxAttempts = MapCodec.requireInt(map['maxAttempts'], 'maxAttempts');
    if (!FollowUpSettings.isValidIntervalDays(intervalDays) ||
        !FollowUpSettings.isValidMaxAttempts(maxAttempts)) {
      throw const FormatException('Configuração fora da faixa permitida');
    }
    return FollowUpSettings(
      intervalDays: intervalDays,
      maxAttempts: maxAttempts,
    );
  }
}
