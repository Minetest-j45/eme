import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'contacts.dart';
import 'home.dart';
import 'identities.dart';

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

  var _selectedIdentity = "";
  Future<Widget> _identitiesDropDown() async {
    List<String> identitiesStrs = await Identities().nameArr();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton(
        dropdownColor: Colours.jet,
        borderRadius: BorderRadius.circular(10),
        value: _selectedIdentity == "" ? null : _selectedIdentity,
        hint: SizedBox(
          width: MediaQuery.of(context).size.width * 0.65,
          child: const Text(
            "Identity to use for encryption",
            style: TextStyle(color: Colours.mintCream),
          ),
        ),
        items: identitiesStrs.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: Colours.mintCream),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          _selectedIdentity = value!;
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Encrypt for'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //todo: dropdown menu, preset to the one they clicked on
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text("From: "),
                  FutureBuilder(
                    future: _identitiesDropDown(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!;
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }

                      return const CircularProgressIndicator();
                    },
                  )
                ],
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (str) {},
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
                  child: const Text(
                    'Encrypt',
                    style: TextStyle(color: Colours.mintCream),
                  ),
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
                  filled: true,
                  fillColor: Colours.jet,
                  border: const OutlineInputBorder(),
                  hintText: "Copy this text and send it to the recipient",
                  hintStyle: const TextStyle(
                      color: Colours.mintCream, overflow: TextOverflow.visible),
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
    );
  }
}
