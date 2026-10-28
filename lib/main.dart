import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/database/hive_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    Bootstrap(
      initialize: HiveInitializer().initialize,
      appBuilder: (_) => const JobTrackApp(),
    ),
  );
}
