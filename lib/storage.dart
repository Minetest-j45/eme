import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> write(String filename, String text) async {
    final path = await _localPath;

    return File('$path/$filename.txt').writeAsString(text);
  }

  Future<String> read(String filename) async {
    try {
      final path = await _localPath;

      final contents = await File('$path/$filename.txt').readAsString();

      return contents;
    } catch (e) {
      return '';
    }
  }
}
