import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'identities.dart';

class NewIdentityPage extends StatefulWidget {
  const NewIdentityPage({super.key});

  @override
  State<NewIdentityPage> createState() => _NewIdentityPageState();
}

class _NewIdentityPageState extends State<NewIdentityPage> {
  var _nameIsEmpty = "";

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.06;
    var nameController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate a new keypair'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(width),
                child: TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: _nameIsEmpty,
                    labelText: 'Enter the desired username for this identity *',
                  ),
                )),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.purple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: const Text('Generate new pair'),
              onPressed: () async {
                if (nameController.value.text == '') {
                  setState(() {
                    _nameIsEmpty = 'Please enter a name';
                  });
                  return;
                } else if (nameController.value.text.contains('|')) {
                  setState(() {
                    _nameIsEmpty = 'Disallowed character: |';
                  });
                  return;
                }

                //check if name already exists
                var usernames = await Identities().read();
                for (var i in usernames) {
                  if (i.name == nameController.value.text) {
                    setState(() {
                      _nameIsEmpty = "This name already exists";
                    });
                    return;
                  }
                }

                var pair = await RSA.generate(4096);
                Identities().add(Identity(
                    name: nameController.value.text,
                    pub: pair.publicKey,
                    priv: pair.privateKey));
                //setState(() {
                //_HomePageState();
                //});
              },
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.purple),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
              child: const Text('Display saved pairs'),
              onPressed: () async {
                var identities = await Identities().read();
                for (var i in identities) {
                  print(i.name);
                  print(i.pub);
                  print(i.priv);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
