import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

/// Ponto único de abertura e fechamento do Hive (PROJECT.md §6).
///
/// Por padrão os dados ficam em `<Application Support>/data`, que no
/// Windows é `%APPDATA%\com.andre\jobtrack_desktop\data` (D-46).
/// Nenhuma rotina aqui apaga ou recria boxes.
class HiveDatabase {
  static const dataFolderName = 'data';
  static const applicationsBoxName = 'applications';
  static const settingsBoxName = 'settings';

  String? _directory;
  Box<Map<dynamic, dynamic>>? _applications;
  Box<Map<dynamic, dynamic>>? _settings;

  Box<Map<dynamic, dynamic>> get applications => _requireOpen(_applications);
  Box<Map<dynamic, dynamic>> get settings => _requireOpen(_settings);

  /// Pasta onde os dados ficam gravados (D-43), após [open].
  String? get directory => _directory;

  /// [directory] permite usar uma pasta temporária nos testes.
  Future<void> open({String? directory}) async {
    final path = directory ?? await _defaultDirectory();
    await Directory(path).create(recursive: true);
    Hive.init(path);
    _directory = path;
    _applications = await Hive.openBox<Map<dynamic, dynamic>>(
      applicationsBoxName,
    );
    _settings = await Hive.openBox<Map<dynamic, dynamic>>(settingsBoxName);
  }

  Future<void> close() async {
    await Hive.close();
    _applications = null;
    _settings = null;
  }

  static Future<String> _defaultDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return '${supportDir.path}${Platform.pathSeparator}$dataFolderName';
  }

  static Box<Map<dynamic, dynamic>> _requireOpen(
    Box<Map<dynamic, dynamic>>? box,
  ) {
    if (box == null) throw StateError('HiveDatabase não foi aberto.');
    return box;
  }
}
