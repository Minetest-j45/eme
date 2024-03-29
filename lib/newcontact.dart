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
  NewContactPage(
      {super.key,
      required this.newContactName,
      required this.newContactLinked});

  String newContactName = "";
  String newContactLinked = "";

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  final _dropDownFormKey = GlobalKey<FormState>();
  final _usernameInputFormKey = GlobalKey<FormState>();
  late TextEditingController _controller;

  Future<Widget> _identitiesDropDown(context) async {
    List<String> identitiesStrs = await Identities().nameArr();

    return Form(
      key: _dropDownFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DropdownButtonFormField(
          dropdownColor: Colours.jet,
          borderRadius: BorderRadius.circular(10),
          value: widget.newContactLinked == "" ? null : widget.newContactLinked,
          validator: (value) => value == null
              ? "Please select the identity you want to link this contact to"
              : null,
          hint: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: const Text(
                "Identity to link this new contact to",
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
            setState(() {
              widget.newContactLinked = value!;
            });
          },
        ),
      ),
    );
  }

  Future<Widget> _usernameInput() async {
    var usernames = await Contacts().nameArr();
    return Form(
      key: _usernameInputFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        validator: (str) {
          if (str == '') {
            return 'Please enter the desired name for this contact';
          }

          for (var i in usernames) {
            if (i == str) {
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
          hintStyle: TextStyle(
              color: Colours.mintCream, overflow: TextOverflow.visible),
        ),
      ),
    );
  }

  bool _qrShow = false;
  Future<Widget> _qrImgLoad(context) async {
    var id = await Identities().get(widget.newContactLinked);
    if (id == null) {
      return const Column();
    }

    var pub = id.pub;

    return Column(
      children: <Widget>[
        Offstage(
          offstage: _qrShow,
          child: QrImage(
            data: pub,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width,
            backgroundColor: Colours.mintCream,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            if (_qrShow)
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _qrShow = !_qrShow;
                    });
                  },
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colours.slateGray)),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colours.mintCream,
                  )),
            if (!_qrShow)
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _qrShow = !_qrShow;
                    });
                  },
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colours.slateGray)),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colours.mintCream,
                  )),
            ElevatedButton(
                onPressed: () {
                  FlutterClipboard.copy(pub);
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colours.slateGray)),
                child: const Icon(
                  Icons.copy,
                  color: Colours.mintCream,
                )),
          ],
        )
      ],
    );
  }

  @override
  void initState() {
    _controller = TextEditingController(text: widget.newContactName);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: Colours.theme,
        home: Scaffold(
            appBar: AppBar(
              title: const Text('New Contact'),
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.width * 0.05,
                            left: MediaQuery.of(context).size.width * 0.05,
                            right: MediaQuery.of(context).size.width * 0.05),
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
                      const Divider(
                        thickness: 2,
                        color: Colours.raisinBlack,
                      ),
                      FutureBuilder(
                        future: _identitiesDropDown(context),
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
                        future: _qrImgLoad(context),
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
                    const Divider(
                      thickness: 2,
                      color: Colours.raisinBlack,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          ElevatedButton(
                              onPressed: () {
                                if (_usernameInputFormKey.currentState!
                                    .validate()) {
                                  _usernameInputFormKey.currentState!.save();
                                } else {
                                  return;
                                }
                                if (_dropDownFormKey.currentState!.validate()) {
                                  _dropDownFormKey.currentState!.save();
                                } else {
                                  return;
                                }

                                setState(() {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => QRScanPage(
                                              name: _controller.value.text,
                                              linkedIdentity:
                                                  widget.newContactLinked,
                                            )),
                                  );
                                });
                              },
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colours.slateGray)),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colours.mintCream,
                              )),
                          const Text("or"),
                          ElevatedButton(
                              onPressed: () {
                                if (_usernameInputFormKey.currentState!
                                    .validate()) {
                                  _usernameInputFormKey.currentState!.save();
                                } else {
                                  return;
                                }
                                if (_dropDownFormKey.currentState!.validate()) {
                                  _dropDownFormKey.currentState!.save();
                                } else {
                                  return;
                                }

                                setState(() {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ManualAddPage(
                                              name: _controller.value.text,
                                              linkedIdentity:
                                                  widget.newContactLinked,
                                            )),
                                  );
                                });
                              },
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colours.slateGray)),
                              child: const Icon(
                                Icons.paste,
                                color: Colours.mintCream,
                              )),
                        ]),
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
  String _err = "";

  bool _qrShow = true;
  Future<Widget> _hashLoad() async {
    var id = await Identities().get(widget.linkedIdentity);

    try {
      await RSA.encryptOAEP("test", "", Hash.SHA256, widget.theirPub);
    } on RSAException {
      _err = "Error while testing their public key";
    }

    if (id == null) {
      return const Column(
        children: [Text("Error")],
      );
    }

    return Column(children: [
      Text("Linked identity: ${widget.linkedIdentity}"),
      Text(
          "My public key summary (hash): ${(await RSA.hash(id.pub, Hash.SHA256)).substring(0, 7)}"),
      Offstage(
        offstage: _qrShow,
        child: QrImage(
          data: id.pub,
          version: QrVersions.auto,
          size: MediaQuery.of(context).size.width,
          backgroundColor: Colours.mintCream,
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        if (_qrShow)
          ElevatedButton(
              onPressed: () {
                setState(() {
                  _qrShow = !_qrShow;
                });
              },
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colours.slateGray)),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colours.mintCream,
              )),
        if (!_qrShow)
          ElevatedButton(
              onPressed: () {
                setState(() {
                  _qrShow = !_qrShow;
                });
              },
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(Colours.slateGray)),
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colours.mintCream,
              )),
        ElevatedButton(
            onPressed: () {
              FlutterClipboard.copy(id.pub);
            },
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colours.slateGray)),
            child: const Icon(
              Icons.copy,
              color: Colours.mintCream,
            )),
      ]),
      const Divider(
        thickness: 2,
        color: Colours.raisinBlack,
      ),
      Text("New contact name: ${widget.name}"),
      Text(
        "Their public key summary (hash): ${(await RSA.hash(widget.theirPub, Hash.SHA256)).substring(0, 7)}",
        style: TextStyle(color: _err == "" ? Colours.mintCream : Colors.red),
      ),
      if (_err != "") ...[
        Text(
          _err,
          style: const TextStyle(color: Colors.red),
        ),
        TextButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colours.slateGray)),
          onPressed: () {
            setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewContactPage(
                          newContactName: widget.name,
                          newContactLinked: widget.linkedIdentity,
                        )),
              );
            });
          },
          child: const Text(
            "Start again",
            style: TextStyle(color: Colours.mintCream),
          ),
        ),
      ] else ...[
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colours.slateGray)),
                onPressed: () {
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NewContactPage(
                                newContactName: "",
                                newContactLinked: "",
                              )),
                    );
                  });
                },
                child: const Text(
                  "Start again",
                  style: TextStyle(color: Colours.mintCream),
                ),
              ),
              TextButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colours.slateGray)),
                  onPressed: () {
                    if (_err != "") {
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
                            builder: (context) => HomePage(
                                  currIdentity: widget.linkedIdentity,
                                )),
                      );
                    });
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(color: Colours.mintCream),
                  )),
            ]),
      ]
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Confirm new contact:'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
            ],
          ),
        ),
      ),
    );
  }
}
