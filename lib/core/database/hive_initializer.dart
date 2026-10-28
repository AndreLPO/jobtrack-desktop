import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

/// Ponto único de inicialização do Hive (PROJECT.md §6).
///
/// Os dados ficam em `<Application Support>/data`, que no Windows é
/// `%APPDATA%\com.andre\jobtrack_desktop\data` (D-46).
class HiveInitializer {
  static const dataFolderName = 'data';

  Future<void> initialize() async {
    final supportDir = await getApplicationSupportDirectory();
    final dataDir = Directory(
      '${supportDir.path}${Platform.pathSeparator}$dataFolderName',
    );
    await dataDir.create(recursive: true);
    Hive.init(dataDir.path);
  }
}
