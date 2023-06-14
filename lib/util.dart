import 'package:flutter/material.dart';

import 'identities.dart';

void rmAllConfirmation(
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

class SingleTapButton extends StatelessWidget {
  final Widget child;
  final Function() onPressed;
  final int delay;
  ButtonStyle style;

  bool singleTap = false;

  SingleTapButton(
      {Key? key,
      required this.child,
      required this.onPressed,
      required this.delay,
      required this.style,
      singleTap = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: style,
        onPressed: () {
          if (!singleTap) {
            Function.apply(onPressed, []);
            singleTap = true;
            Future.delayed(Duration(seconds: delay))
                .then((value) => singleTap = false);
          }
        },
        child: child);
  }
}
