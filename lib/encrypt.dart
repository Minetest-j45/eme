import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'contacts.dart';
import 'home.dart';

class EncryptPage extends StatefulWidget {
  const EncryptPage(
      {super.key, required this.currContact, required this.currIdentity});

  final String currContact;
  final String currIdentity;

  @override
  State<EncryptPage> createState() => _EncryptPageState();
}

class _EncryptPageState extends State<EncryptPage> {
  String _encryptErr = "";
  final _rawController = TextEditingController();
  final _encryptedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypt for'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //todo: dropdown menu, preset to the one they clicked on
            TextFormField(
              controller: _rawController,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Type/paste your message here, then press Encrypt",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () {
                      FlutterClipboard.paste().then((value) => setState(() {
                            _rawController.text = value;
                          }));
                    },
                  )),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            Text(
              _encryptErr,
              style: const TextStyle(color: Colors.red),
            ),
            TextButton(
                child: const Text('Encrypt'),
                onPressed: () async {
                  Contact? ctact = await Contacts().get(widget.currContact);
                  if (ctact == null) {
                    return;
                  }

                  try {
                    String encrypted = await RSA.encryptOAEP(
                        _rawController.text, "", Hash.SHA256, ctact.pub);

                    setState(() {
                      _encryptedController.text = encrypted;
                    });
                  } on RSAException {
                    _encryptErr =
                        "*Encryption failed, please try again or try removing and readding this persons contact*";
                    setState(() {});
                    return;
                  }
                }),
            TextFormField(
              controller: _encryptedController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Copy this text and send it to the recipient",
                suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      FlutterClipboard.copy(_encryptedController.text);
                    }),
              ),
              maxLines: null,
              readOnly: true,
            ),
            TextButton(
              child: const Text("Done"),
              onPressed: () {
                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        currIdentity: widget.currIdentity,
                      ),
                    ),
                  );
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
