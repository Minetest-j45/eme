import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

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
  var _selectedIdentity = "";
  var _error = "No errors so far";
  int? _toggleIndex;
  late TextEditingController _controller;

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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.06;

    return MaterialApp(
        theme: Colours.theme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('EME'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(children: <Widget>[
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
                  Padding(
                    padding: EdgeInsets.all(width),
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
                  Padding(
                    padding: EdgeInsets.all(width),
                    child: ToggleSwitch(
                      inactiveBgColor: Colours.jet,
                      activeBgColor: const [Colours.slateGray],
                      activeFgColor: Colours.mintCream,
                      inactiveFgColor: Colours.mintCream,
                      initialLabelIndex: _toggleIndex,
                      totalSwitches: 2,
                      labels: const ['Scan first', 'Scan second'],
                      cornerRadius: 15,
                      minWidth: width * 5,
                      onToggle: (index) => _toggleIndex = index,
                    ),
                  ),
                  const Text(
                      "Make sure the person you want to add chooses the opposite option on thier device"),
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

                    //get toggle switch value
                    if (_toggleIndex == null) {
                      _error = 'Please select a scan order';
                      setState(() {});
                      return;
                    }

                    if (_toggleIndex == 0) {
                      //scan first
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => QRScanPage(
                                    name: _controller.value.text,
                                    linkedIdentity: _selectedIdentity,
                                    toggleIndex: 0,
                                  )),
                        );
                      });
                    } else if (_toggleIndex == 1) {
                      //display first
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => QrDisplayPage(
                                    name: _controller.value.text,
                                    linkedIdentity: _selectedIdentity,
                                    toggleIndex: 1,
                                  )),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ));
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
  late Color? _pubErr;
  late String _err;

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
