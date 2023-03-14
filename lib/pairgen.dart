import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'identities.dart';

class NewIdentityPage extends StatefulWidget {
  const NewIdentityPage({super.key});

  @override
  State<NewIdentityPage> createState() => _NewIdentityPageState();
}

class _NewIdentityPageState extends State<NewIdentityPage> {
  var _nameIsEmpty = "";
  String _keySize = "4096";
  List<String> keySizeOptions = <String>["2048", "3072", "4096"];

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
            const Text(
                "RSA key size: (2048 for lower end devices; 4096 for highest security; 3072 for somewhere inbetween)"),
            DropdownButton(
              items:
                  keySizeOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _keySize = value!;
                });
              },
              value: _keySize,
            ),
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

                int keySize = int.parse(_keySize);

                var pair = await RSA.generate(keySize);
                Identities().add(Identity(
                    name: nameController.value.text,
                    pub: pair.publicKey,
                    priv: pair.privateKey));

                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(
                        currIdentity: "",
                      ),
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
