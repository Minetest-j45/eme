import 'dart:convert';

import 'package:eme/ids.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'contacts.dart';
import 'identities.dart';
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor:
                        MaterialStateProperty.all(Colours.mintCream),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
                          title: const Text(
                              "Are you sure you want to delete all your identities and contacts"),
                          content: const Text("This action can not be undone"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Identities().rmAll();
                                  Contacts().rmAll();

                                  setState(
                                    () {
                                      Navigator.of(ctx).pop();

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const NewIdentityPage(
                                                  backwardsEnabled: false,
                                                )),
                                      );
                                    },
                                  );
                                },
                                child: const Text("Yes")),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                                child: const Text("No")),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("Delete all"))
            ],
          ),
        ),
      ),
    );
  }
}
