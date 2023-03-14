import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'identities.dart';

class DecryptPage extends StatefulWidget {
  const DecryptPage({super.key, required this.currIdentity});

  final String currIdentity;

  @override
  State<DecryptPage> createState() => _DecryptPageState();
}

class _DecryptPageState extends State<DecryptPage> {
  final _rawController = TextEditingController();
  final _decryptedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decrypt'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _rawController,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText:
                      "Paste the encrypted message here, then press Decrypt",
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
            TextButton(
                child: const Text('Decrypt'),
                onPressed: () async {
                  Identity? id = await Identities().get(widget.currIdentity);

                  /*var encrypted = await RSA.encryptOAEP(
                      _rawController.text, "", Hash.SHA256, ctact.pub);*/

                  var decrypted = await RSA.decryptOAEP(
                      _rawController.text, "", Hash.SHA256, id!.priv);

                  setState(() {
                    _decryptedController.text = decrypted;
                  });
                }),
            TextFormField(
              controller: _decryptedController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "This is the message the sender wanted you to read",
                suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      FlutterClipboard.copy(_decryptedController.text);
                    }),
              ),
              maxLines: null,
              enabled: false,
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
