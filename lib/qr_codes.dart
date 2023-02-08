import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage({super.key, required this.pub});

  final String pub;

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EME"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Scan the following:',
            ),
            QrImage(
              data: widget.pub,
              version: QrVersions.auto,
              size: MediaQuery.of(context).size.width,
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
