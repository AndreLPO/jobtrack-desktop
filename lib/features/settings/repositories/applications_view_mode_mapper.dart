import '../../../core/database/map_codec.dart';
import '../models/applications_view_mode.dart';

/// Formato gravado da preferência de visualização (D-03, K-04).
abstract final class ApplicationsViewModeMapper {
  static const schemaVersion = 1;

  static Map<String, Object?> toMap(ApplicationsViewMode mode) => {
    'schemaVersion': schemaVersion,
    'mode': mode.name,
  };

  /// Lança [FormatException] se o registro for inválido.
  static ApplicationsViewMode fromMap(Map<dynamic, dynamic> map) {
    final version = MapCodec.requireInt(map['schemaVersion'], 'schemaVersion');
    if (version != schemaVersion) {
      throw FormatException('Versão de formato não suportada', version);
    }
    return MapCodec.decodeEnum(
      ApplicationsViewMode.values,
      map['mode'],
      'mode',
    );
  }
}
