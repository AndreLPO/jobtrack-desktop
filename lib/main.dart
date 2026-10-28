import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bindings/initial_binding.dart';
import 'app/bootstrap.dart';
import 'core/database/hive_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = HiveDatabase();
  runApp(
    Bootstrap(
      initialize: database.open,
      appBuilder: (_) => JobTrackApp(initialBinding: InitialBinding(database)),
    ),
  );
}
