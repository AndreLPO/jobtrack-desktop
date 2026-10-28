import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/applications/models/duplicate_check.dart';

import 'fixtures.dart';

void main() {
  final existing = [
    buildApplication(id: 'a', companyName: 'acme ', jobTitle: 'dev flutter'),
    buildApplication(id: 'b', companyName: 'Globex', jobTitle: 'QA'),
  ];

  test('CA-APP-11: ignora caixa e espaços nas pontas', () {
    final duplicate = findPossibleDuplicate(
      companyName: 'Acme',
      jobTitle: ' Dev Flutter',
      existing: existing,
    );
    expect(duplicate?.id, 'a');
  });

  test('empresa igual com vaga diferente não é duplicidade', () {
    expect(
      findPossibleDuplicate(
        companyName: 'Acme',
        jobTitle: 'Dev Backend',
        existing: existing,
      ),
      isNull,
    );
  });

  test('na edição, a própria candidatura não conta', () {
    expect(
      findPossibleDuplicate(
        companyName: 'Acme',
        jobTitle: 'Dev Flutter',
        existing: existing,
        excludingId: 'a',
      ),
      isNull,
    );
  });
}
