import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
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
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Encrypt for: ${widget.currContact}'),
        ),
        body: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _rawController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colours.jet,
                      border: const OutlineInputBorder(),
                      hintText:
                          "Type/paste your message here, then press Encrypt",
                      hintStyle: const TextStyle(
                          color: Colours.mintCream,
                          overflow: TextOverflow.visible),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.paste,
                          color: Colours.slateGray,
                        ),
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
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colours.slateGray)),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.lock_outline,
                            color: Colours.mintCream,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Encrypt',
                            style: TextStyle(color: Colours.mintCream),
                          )
                        ]),
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
                        setState(() {
                          _encryptErr = "Error encrypting message";
                        });
                        return;
                      }
                    }),
                TextFormField(
                  controller: _encryptedController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colours.jet,
                    border: const OutlineInputBorder(),
                    hintText: "Copy this text and send it to the recipient",
                    hintStyle: const TextStyle(
                        color: Colours.mintCream,
                        overflow: TextOverflow.visible),
                    suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: Colours.slateGray,
                        ),
                        onPressed: () {
                          FlutterClipboard.copy(_encryptedController.text);
                        }),
                  ),
                  maxLines: null,
                  readOnly: true,
                ),
                TextButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colours.slateGray)),
                  child: const Text(
                    "Done",
                    style: TextStyle(color: Colours.mintCream),
                  ),
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
        ),
      ),
    );
  }
}
