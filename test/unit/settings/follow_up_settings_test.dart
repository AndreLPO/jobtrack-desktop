import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/settings/models/follow_up_settings.dart';

void main() {
  test('CA-SET-01: padrões de 7 dias e 3 tentativas', () {
    const settings = FollowUpSettings();
    expect(settings.intervalDays, 7);
    expect(settings.maxAttempts, 3);
  });

  test('CA-SET-03: faixa do prazo é 1 a 90', () {
    expect(FollowUpSettings.isValidIntervalDays(0), isFalse);
    expect(FollowUpSettings.isValidIntervalDays(-1), isFalse);
    expect(FollowUpSettings.isValidIntervalDays(1), isTrue);
    expect(FollowUpSettings.isValidIntervalDays(90), isTrue);
    expect(FollowUpSettings.isValidIntervalDays(91), isFalse);
  });

  test('CA-SET-03: faixa de tentativas é 1 a 10', () {
    expect(FollowUpSettings.isValidMaxAttempts(0), isFalse);
    expect(FollowUpSettings.isValidMaxAttempts(1), isTrue);
    expect(FollowUpSettings.isValidMaxAttempts(10), isTrue);
    expect(FollowUpSettings.isValidMaxAttempts(11), isFalse);
  });
}
