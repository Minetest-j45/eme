import 'package:flutter/material.dart';

class SingleTapButton extends StatelessWidget {
  final Widget child;
  final Function() onPressed;
  final int delay;
  final ButtonStyle style;

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
