import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_mapper.dart';

import '../../support/application_samples.dart';

void main() {
  test('CA-P-01: ida e volta com todos os campos, histórico e contatos', () {
    final original = fullApplication();
    expect(original.statusHistory, hasLength(3));
    expect(original.interactions, hasLength(2));

    final decoded = ApplicationMapper.fromMap(
      ApplicationMapper.toMap(original),
    );
    expectSameApplication(decoded, original);
  });

  test('CA-P-02: só obrigatórios mantém opcionais nulos', () {
    final original = minimalApplication();
    final decoded = ApplicationMapper.fromMap(
      ApplicationMapper.toMap(original),
    );
    expectSameApplication(decoded, original);
    expect(decoded.details.jobUrl, isNull);
    expect(decoded.details.workMode, isNull);
    expect(decoded.manualNextFollowUpAt, isNull);
  });

  test('grava enums pelo nome e o schemaVersion atual', () {
    final map = ApplicationMapper.toMap(fullApplication());
    expect(map['schemaVersion'], ApplicationMapper.schemaVersion);
    expect(map['status'], 'interview');
    expect(map['channel'], 'other');
    expect(map['applicationDate'], '2026-09-30');
  });

  group('CA-P-06: registros ilegíveis lançam FormatException', () {
    Map<String, Object?> validMap() =>
        ApplicationMapper.toMap(minimalApplication());

    test('enum desconhecido', () {
      final map = validMap()..['status'] = 'hired';
      expect(() => ApplicationMapper.fromMap(map), throwsFormatException);
    });

    test('obrigatório ausente', () {
      final map = validMap()..remove('companyName');
      expect(() => ApplicationMapper.fromMap(map), throwsFormatException);
    });

    test('versão de formato mais nova', () {
      final map = validMap()
        ..['schemaVersion'] = ApplicationMapper.schemaVersion + 1;
      expect(() => ApplicationMapper.fromMap(map), throwsFormatException);
    });

    test('histórico vazio ou inconsistente com o status', () {
      final empty = validMap()..['statusHistory'] = <Object?>[];
      expect(() => ApplicationMapper.fromMap(empty), throwsFormatException);

      final inconsistent = validMap()
        ..['status'] = ApplicationStatus.interview.name;
      expect(
        () => ApplicationMapper.fromMap(inconsistent),
        throwsFormatException,
      );
    });

    test('contato com campo de tipo errado', () {
      final map = ApplicationMapper.toMap(fullApplication());
      final interactions = (map['interactions']! as List).cast<Map>();
      interactions.first['receivedResponse'] = 'sim';
      expect(() => ApplicationMapper.fromMap(map), throwsFormatException);
    });
  });
}
