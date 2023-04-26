import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'colours.dart';
import 'contacts.dart';
import 'home.dart';
import 'identities.dart';
import 'qr_codes.dart';

class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  String _selectedIdentity = "";
  String _error = "";
  final TextEditingController _controller = TextEditingController(text: "");

  Future<Widget> _identitiesDropDown() async {
    List<String> identitiesStrs = await Identities().nameArr();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton(
        dropdownColor: Colours.jet,
        borderRadius: BorderRadius.circular(10),
        value: _selectedIdentity == "" ? null : _selectedIdentity,
        hint: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: const Text(
              "Identity to relate this new contact to",
              style: TextStyle(color: Colours.mintCream),
            )),
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

  Future<Widget> _usernameInput() async {
    var usernames = await Contacts().nameArr();
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (str) {
        if (str == '') {
          return 'Please enter the desired name for this contact';
        }
        //check if contact already exists
        for (var i in usernames) {
          if (i == _controller.value.text) {
            return 'This name already exists';
          }
        }
        return null;
      },
      controller: _controller,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colours.jet,
        border: OutlineInputBorder(),
        hintText: 'Enter the desired username for this contact',
        hintStyle:
            TextStyle(color: Colours.mintCream, overflow: TextOverflow.visible),
      ),
    );
  }

  Future<Widget> _qrImgLoad() async {
    var id = await Identities().get(_selectedIdentity);
    if (id == null) {
      return Column();
    }

    var pub = id.pub;

    return Column(
      children: [
        QrImage(
          data: pub,
          version: QrVersions.auto,
          size: MediaQuery.of(context).size.width,
          backgroundColor: Colours.mintCream,
        ),
        Text((await RSA.hash(pub, Hash.SHA256)).substring(0, 7),
            style: const TextStyle(
                fontWeight: FontWeight.w400, fontFamily: "monospace")),
        ElevatedButton(
            onPressed: () {
              FlutterClipboard.copy(pub);
            },
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colours.slateGray)),
            child: const Icon(
              Icons.copy,
              color: Colours.mintCream,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: Colours.theme,
        home: Scaffold(
            appBar: AppBar(
              title: const Text('EME'),
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.05),
                        child: FutureBuilder(
                          future: _usernameInput(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return snapshot.data!;
                            } else if (snapshot.hasError) {
                              return Text("${snapshot.error}");
                            }

                            return const CircularProgressIndicator();
                          },
                        ),
                      ),
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
                      ),
                      FutureBuilder(
                        future: _qrImgLoad(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return snapshot.data!;
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}");
                          }

                          return const CircularProgressIndicator();
                        },
                      ),
                    ]),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: <
                        Widget>[
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => QRScanPage(
                                          name: _controller.value.text,
                                          linkedIdentity: _selectedIdentity,
                                        )),
                              );
                            });
                          }, //todo
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colours.slateGray)),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colours.mintCream,
                          )),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ManualAddPage(
                                          name: _controller.value.text,
                                          linkedIdentity: _selectedIdentity,
                                        )),
                              );
                            });
                          }, //todo
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colours.slateGray)),
                          child: const Icon(
                            Icons.paste,
                            color: Colours.mintCream,
                          )),
                    ]),
                    Text(_error),
                    TextButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colours.slateGray)),
                      child: const Text(
                        'Add a new contact',
                        style: TextStyle(color: Colours.mintCream),
                      ),
                      onPressed: () async {
                        if (_selectedIdentity == '') {
                          _error = 'Please select an identity';
                          setState(() {});
                          return;
                        }

                        setState(() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QRScanPage(
                                      name: _controller.value.text,
                                      linkedIdentity: _selectedIdentity,
                                    )),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            )));
  }
}

class ConfirmContactPage extends StatefulWidget {
  const ConfirmContactPage({
    super.key,
    required this.name,
    required this.linkedIdentity,
    required this.theirPub,
  });

  final String name;
  final String linkedIdentity;
  final String theirPub;

  @override
  State<ConfirmContactPage> createState() => _ConfirmContactPageState();
}

class _ConfirmContactPageState extends State<ConfirmContactPage> {
  Color? _pubErr;
  String _err = "";

  Future<Widget> _hashLoad() async {
    var id = await Identities().get(widget.linkedIdentity);

    //test their public key
    try {
      await RSA.encryptOAEP("test", "", Hash.SHA256, widget.theirPub);
    } on RSAException {
      _pubErr = Colors.red;
    }

    return Column(children: [
      Text(
          "My public key summary (hash): ${(await RSA.hash(id!.pub, Hash.SHA256)).substring(0, 7)}"),
      Text(
        "Their public key summary (hash): ${(await RSA.hash(widget.theirPub, Hash.SHA256)).substring(0, 7)}",
        style: TextStyle(color: _pubErr ?? Colours.mintCream),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm new contact:'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("New contact name: ${widget.name}"),
            Text("Linked identity: ${widget.linkedIdentity}"),
            FutureBuilder(
              future: _hashLoad(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                return const CircularProgressIndicator();
              },
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewContactPage()),
                  );
                });
              },
              child: const Text("Start again"),
            ),
            Text(
              _err,
              style: const TextStyle(color: Colors.red),
            ),
            TextButton(
                onPressed: () {
                  if (_pubErr == Colors.red) {
                    _err =
                        "*There is a problem with their public key, please start again*";
                    setState(() {});
                    return;
                  }

                  Contacts().add(Contact(
                      name: widget.name,
                      pub: widget.theirPub,
                      linkedIdentity: widget.linkedIdentity));
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomePage(currIdentity: widget.linkedIdentity)),
                    );
                  });
                },
                child: const Text("Confirm")),
          ],
        ),
      ),
    );
  }
}
