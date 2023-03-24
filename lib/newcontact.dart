import 'package:adler32/adler32.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'contacts.dart';
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
  final String _newName = "";
  var _toggleIndex;
  late TextEditingController _controller;

  Future<Widget> _identitiesDropDown() async {
    List<Identity> identitiesArr = await Identities().read();
    List<String> identitiesStrs = [];
    for (var identity in identitiesArr) {
      identitiesStrs.add(identity.name);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton(
        borderRadius: BorderRadius.circular(10),
        value: _selectedIdentity == "" ? null : _selectedIdentity,
        hint: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: const Text("Identity to relate this new contact to")),
        items: identitiesStrs.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
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
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _newName);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.06;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EME'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(width),
                child: Column(children: <Widget>[
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
                  TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter the desired username for this contact',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(width),
                    child: ToggleSwitch(
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
                ])),
            Text(_error),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.purple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: const Text('Add a new contact'),
              onPressed: () async {
                if (_selectedIdentity == '') {
                  _error = 'Please select an identity';
                  setState(() {});
                  return;
                }

                if (_controller.value.text == '') {
                  _error = 'Please enter the desired name for this contact';
                  setState(() {});
                  return;
                }

                //check if contact already exists
                var usernames = await Contacts().read();
                for (var i in usernames) {
                  if (i.name == _controller.value.text) {
                    _error = 'This name already exists';
                    setState(() {});
                    return;
                  }
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
    );
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
  Future<Widget> _myHashLoad() async {
    var id = await Identities().get(widget.linkedIdentity);

    return Text(
        "My public key summary (hash): ${Adler32.str(id!.pub).toString()}");
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
              future: _myHashLoad(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!;
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                return const CircularProgressIndicator();
              },
            ),
            Text(
                "Their public key summary (hash): ${Adler32.str(widget.theirPub).toString()}"),
            TextButton(
                onPressed: () {
                  Contacts().add(Contact(
                      name: widget.name,
                      pub: widget.theirPub,
                      linkedIdentity: widget.linkedIdentity));
                },
                //TODO: check if their public key is a valid one (actually is a public key)?
                child: Text("Confirm"))
            //TODO: buttons: restart (go to NewContactPage), confirm (add contact, go home)
          ],
        ),
      ),
    );
  }
}
