import 'package:eme/ids.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'identities.dart';

void main() {
  runApp(const MyApp());
}

Future<bool> _isFirst() async {
  List<Identity> ids = await Identities().read();
  return ids.isEmpty;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _isFirst(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!) {
              return const MaterialApp(
                title: 'EME',
                home: NewIdentityPage(
                  backwardsEnabled: false,
                ),
              );
            } else {
              return MaterialApp(
                title: 'EME',
                home: HomePage(
                  currIdentity: "",
                ),
              );
            }
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
