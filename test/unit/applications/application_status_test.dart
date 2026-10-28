import 'package:flutter_test/flutter_test.dart';
import 'package:jobtrack_desktop/features/applications/models/application_status.dart';

void main() {
  test('tem exatamente os 8 status de D-10', () {
    expect(ApplicationStatus.values, hasLength(8));
  });

  test('ativos e encerrados (D-10)', () {
    final active = ApplicationStatus.values.where((s) => s.isActive).toSet();
    expect(active, {
      ApplicationStatus.applied,
      ApplicationStatus.responseReceived,
      ApplicationStatus.interview,
      ApplicationStatus.technicalTest,
      ApplicationStatus.offerReceived,
    });

    final closed = ApplicationStatus.values.where((s) => s.isClosed).toSet();
    expect(closed, {
      ApplicationStatus.rejected,
      ApplicationStatus.withdrawn,
      ApplicationStatus.closedWithoutResponse,
    });
  });

  test('status que indicam resposta (D-11)', () {
    final responded = ApplicationStatus.values
        .where((s) => s.indicatesResponse)
        .toSet();
    expect(responded, {
      ApplicationStatus.responseReceived,
      ApplicationStatus.interview,
      ApplicationStatus.technicalTest,
      ApplicationStatus.offerReceived,
      ApplicationStatus.rejected,
    });
  });
}
