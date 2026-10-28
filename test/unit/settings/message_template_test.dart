import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/settings/models/message_template.dart';
import 'package:jobtrack_desktop/features/settings/repositories/message_template_mapper.dart';

import '../../support/application_samples.dart';

void main() {
  group('MessageTemplate.render (D-50)', () {
    test('substitui todas as variáveis, inclusive repetidas', () {
      final text = MessageTemplate.render(
        '{contato}: {vaga} na {empresa} em {data}. {empresa}!',
        fullApplication(),
      );
      expect(
        text,
        'Maria (recrutadora): Dev Flutter Sênior na Acme em 30/09/2026. Acme!',
      );
    });

    test('contato vazio vira "equipe de recrutamento" (D-59)', () {
      expect(
        MessageTemplate.render('Olá, {contato}!', minimalApplication()),
        'Olá, equipe de recrutamento!',
      );
    });

    test('padrão em pt-BR usa as 4 variáveis', () {
      for (final variable in MessageTemplate.variables.keys) {
        expect(MessageTemplate.defaultText, contains(variable));
      }
      expect(MessageTemplate.isValid('  '), isFalse);
    });
  });

  group('MessageTemplateMapper', () {
    test('ida e volta', () {
      expect(
        MessageTemplateMapper.fromMap(MessageTemplateMapper.toMap('Olá')),
        'Olá',
      );
    });

    test('vazio, tipo errado ou versão nova são ilegíveis', () {
      for (final map in <Map<String, Object?>>[
        {'schemaVersion': 1, 'text': '  '},
        {'schemaVersion': 1, 'text': 3},
        {'schemaVersion': 2, 'text': 'Olá'},
      ]) {
        expect(
          () => MessageTemplateMapper.fromMap(map),
          throwsFormatException,
          reason: '$map',
        );
      }
    });
  });
}
