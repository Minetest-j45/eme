import 'dart:convert';

import 'storage.dart';

class Setting {
  String key;
  String value;

  Setting({required this.key, required this.value});
}

class Settings {
  Future<String> get(String key) async {
    var rawSettings = await Storage().read('settings');
    if (rawSettings.isEmpty) {
      rawSettings = '{"settings":[]}';
    }
    final json = jsonDecode(rawSettings);

    for (var setting in json['settings']) {
      if (setting['key'] == key) {
        return setting['value'];
      }
    }

    return '';
  }

  void set(String key, String value) async {
    var rawSettings = await Storage().read('settings');
    if (rawSettings.isEmpty) {
      rawSettings = '{"settings":[]}';
    }
    final json = jsonDecode(rawSettings);

    var found = false;
    for (var setting in json['settings']) {
      if (setting['key'] == key) {
        found = true;
        setting['value'] = value;
        return;
      }
    }

    if (!found) {
      json['settings'].add({'key': key, 'value': value});
    }

    await Storage().write('settings', jsonEncode(json));
  }
}
