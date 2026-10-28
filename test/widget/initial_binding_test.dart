import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jobtrack_desktop/app/app.dart';
import 'package:jobtrack_desktop/app/bindings/initial_binding.dart';
import 'package:jobtrack_desktop/app/routes/app_routes.dart';
import 'package:jobtrack_desktop/core/database/hive_database.dart';
import 'package:jobtrack_desktop/features/applications/repositories/application_repository.dart';
import 'package:jobtrack_desktop/features/applications/repositories/hive_application_repository.dart';
import 'package:jobtrack_desktop/features/settings/repositories/settings_repository.dart';

void main() {
  testWidgets('InitialBinding liga a listagem ao Hive real', (tester) async {
    late Directory directory;
    final database = HiveDatabase();
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('jobtrack_test_');
      await database.open(directory: directory.path);
    });
    addTearDown(() async {
      Get.reset();
      await tester.runAsync(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
    });

    await tester.pumpWidget(
      JobTrackApp(
        initialBinding: InitialBinding(database),
        initialRoute: AppRoutes.applications,
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(Get.find<ApplicationRepository>(), isA<HiveApplicationRepository>());
    expect(Get.isRegistered<SettingsRepository>(), isTrue);
    expect(find.text('Nenhuma candidatura cadastrada.'), findsOneWidget);
  });
}
