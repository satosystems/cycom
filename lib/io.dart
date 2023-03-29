import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class IO {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<List<String>> list() async {
    final path = await _localPath;
    final dir = Directory(path);
    return dir
        .list()
        .map((entity) => entity.path.substring(path.length + 1))
        .toList();
  }

  static Future<File> _open(final String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  static Future<String?> read(final String filename) async {
    try {
      final file = await _open(filename);
      return await file.readAsString();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(e);
        print(stackTrace);
      }
      return null;
    }
  }

  static Future<File> write(
      final String filename, final String contents) async {
    final file = await _open(filename);
    return file.writeAsString(contents);
  }
}
