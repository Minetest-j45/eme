import 'package:flutter/material.dart';

import 'identities.dart';

void confirmation(
    BuildContext context, String mainText, subtitle, void setStateFunc) {
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(mainText),
        content: Text(subtitle),
        actions: [
          TextButton(
              onPressed: () {
                setStateFunc;

                Identities().rmAll();
                Navigator.of(context).pop();
              },
              child: const Text("Yes")),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("No")),
        ],
      );
    },
  );
}
