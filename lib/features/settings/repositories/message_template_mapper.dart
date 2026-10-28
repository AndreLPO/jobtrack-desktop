import '../../../core/database/map_codec.dart';
import '../models/message_template.dart';

/// Formato gravado do modelo de mensagem (D-03).
abstract final class MessageTemplateMapper {
  static const schemaVersion = 1;

  static Map<String, Object?> toMap(String text) => {
    'schemaVersion': schemaVersion,
    'text': text,
  };

  /// Lança [FormatException] se o registro for inválido.
  static String fromMap(Map<dynamic, dynamic> map) {
    final version = MapCodec.requireInt(map['schemaVersion'], 'schemaVersion');
    if (version != schemaVersion) {
      throw FormatException('Versão de formato não suportada', version);
    }
    final text = MapCodec.requireString(map['text'], 'text');
    if (!MessageTemplate.isValid(text)) {
      throw const FormatException('Modelo de mensagem vazio');
    }
    return text;
  }
}
