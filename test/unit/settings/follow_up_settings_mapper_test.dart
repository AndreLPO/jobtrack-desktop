import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';
import 'package:jobtrack_desktop/features/settings/repositories/follow_up_settings_mapper.dart';

void main() {
  test('ida e volta', () {
    const settings = FollowUpSettings(intervalDays: 10, maxAttempts: 2);
    final decoded = FollowUpSettingsMapper.fromMap(
      FollowUpSettingsMapper.toMap(settings),
    );
    expect(decoded.intervalDays, 10);
    expect(decoded.maxAttempts, 2);
  });

  test('fora da faixa, tipo errado ou versão nova são ilegíveis', () {
    final cases = <Map<String, Object?>>[
      {'schemaVersion': 1, 'intervalDays': 0, 'maxAttempts': 3},
      {'schemaVersion': 1, 'intervalDays': 7, 'maxAttempts': 11},
      {'schemaVersion': 1, 'intervalDays': '7', 'maxAttempts': 3},
      {'schemaVersion': 2, 'intervalDays': 7, 'maxAttempts': 3},
      {'intervalDays': 7, 'maxAttempts': 3},
    ];
    for (final map in cases) {
      expect(
        () => FollowUpSettingsMapper.fromMap(map),
        throwsFormatException,
        reason: '$map',
      );
    }
  });
}
