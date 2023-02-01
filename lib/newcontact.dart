import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'contacts.dart';

class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  var _nameIsEmpty = "";

  @override
  Widget build(BuildContext context) {
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
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: _nameIsEmpty,
                      labelText:
                          'Enter the desired username for this identity *',
                    ),
                  ),
                  ToggleSwitch(
                    initialLabelIndex: null,
                    totalSwitches: 2,
                    labels: const ['Scan first', 'Scan second'],
                    cornerRadius: 15,
                    minWidth: width * 5,
                  ),
                  const Text(
                      "Make sure the person you want to add chooses the opposite option on thier device"),
                ])),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.purple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: const Text('Add a new contact'),
              onPressed: () async {
                if (nameController.value.text == '') {
                  setState(() {
                    _nameIsEmpty =
                        'Please enter the desired name for this contact';
                  });
                  //return;
                } /* else if (nameController.value.text.contains('|')) {
                  setState(() {
                    _nameIsEmpty = 'Disallowed character: |';
                  });
                  return;
                }*/

                //check if contact already exists
                var usernames = await Contacts().read();
                for (var i in usernames) {
                  if (i.name == nameController.value.text) {
                    setState(() {
                      _nameIsEmpty = "This name already exists";
                    });
                    return;
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
