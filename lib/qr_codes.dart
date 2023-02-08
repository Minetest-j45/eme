import 'package:eme/identities.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'contacts.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage(
      {super.key,
      required this.pub,
      required this.name,
      required this.linked_identity,
      required this.toggle_index});

  final String name;
  final String pub;
  final String linked_identity;
  final int toggle_index;

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String _identityPub = '';

  @override
  void initState() async {
    super.initState();
    //get public key of linked identity
    var idList = await Identities().read();
    for (var id in idList) {
      if (id.name == widget.linked_identity) {
        _identityPub = id.pub;
      }
    }
  }

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
              data: _identityPub,
              version: QrVersions.auto,
              size: MediaQuery.of(context).size.width,
            ),
            TextButton(
              child: const Text('Back'),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
            TextButton(
              child: const Text('Next'),
              onPressed: () {
                if (widget.toggle_index == 0) {
                  //they scanned first, so are finished
                } else if (widget.toggle_index == 1) {
                  //they displayed first, so they have to scan now
                  Contacts().add(Contact(
                      name: widget.name,
                      pub: widget.pub,
                      linked_identity: widget.linked_identity));
                  //todo: go to home page
                }
              },
            )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
