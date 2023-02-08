import 'package:eme/identities.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'contacts.dart';

class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  var _selectedIdentity = "";
  var _error = "No errors so far";

  Future<Widget> _identitiesStrs() async {
    List<Identity> identitiesArr = await Identities().read();
    List<String> identitiesStrs = [];
    for (var identity in identitiesArr) {
      identitiesStrs.add(identity.name);
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton(
        //borderRadius: BorderRadius.circular(10),
        value: _selectedIdentity == "" ? null : _selectedIdentity,
        hint: Container(
            width: MediaQuery.of(context).size.width * 0.65,
            child: const Text("Identity to relate this new contact to")),
        items: identitiesStrs.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? value) {
          _selectedIdentity = value!;
          print(_selectedIdentity);
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var _toggleIndex;
    double width = MediaQuery.of(context).size.width * 0.06;
    var nameController = TextEditingController();

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
                    future: _identitiesStrs(),
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
                    controller: nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText:
                          'Enter the desired username for this contact *',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(width),
                    child: ToggleSwitch(
                      initialLabelIndex: null,
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
                print(_error);
                if (_selectedIdentity == "") {
                  _error = "Please select an identity";
                  setState(() {});
                  return;
                }

                if (nameController.value.text == '') {
                  _error = 'Please enter the desired name for this contact';
                  setState(() {});
                  return;
                }

                //check if contact already exists
                var usernames = await Contacts().read();
                for (var i in usernames) {
                  if (i.name == nameController.value.text) {
                    _error = "This name already exists";
                    setState(() {});
                    return;
                  }
                }

                //get toggle switch value
                if (_toggleIndex == null) {
                  setState(() {
                    _error = "Please select a scan order";
                  });
                  return;
                }

                if (_toggleIndex == 0) {
                  //scan first
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NewContactPage()),
                    );
                  });
                } else if (_toggleIndex == 1) {
                  //display first
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NewContactPage()),
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
