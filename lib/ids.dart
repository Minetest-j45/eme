import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'home.dart';
import 'identities.dart';
import 'util.dart';

class NewIdentityPage extends StatefulWidget {
  const NewIdentityPage({super.key});

  @override
  State<NewIdentityPage> createState() => _NewIdentityPageState();
}

class _NewIdentityPageState extends State<NewIdentityPage> {
  String _keySize = "4096";
  List<String> keySizeOptions = <String>["2048", "3072", "4096"];
  final _usernameInputFormKey = GlobalKey<FormState>();

  Future<Widget> _usernameInput() async {
    var identities = await Identities().nameArr();
    return Form(
      key: _usernameInputFormKey,
      autovalidateMode: AutovalidateMode.always,
      child: TextFormField(
        autovalidateMode: AutovalidateMode.always,
        validator: (str) {
          if (str == '') {
            return 'Please enter the desired name for this new contact';
          } else if (str!.contains('|')) {
            return 'Disallowed character: |';
          }

          for (var i in identities) {
            if (i == nameController.value.text) {
              return "This name already exists";
            }
          }

          return null;
        },
        controller: nameController,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colours.jet,
          border: OutlineInputBorder(),
          hintText: 'Enter the desired username for this identity',
          hintStyle: TextStyle(color: Colours.mintCream),
        ),
      ),
    );
  }

  final nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: Colours.theme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Generate a new keypair'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownButton(
                      dropdownColor: Colours.jet,
                      items: keySizeOptions
                          .map<DropdownMenuItem<String>>((String value) {
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
                          _keySize = value!;
                        });
                      },
                      value: _keySize,
                    ),
                  ],
                ),
                TextButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colours.slateGray)),
                  child: const Text(
                    'Generate new pair',
                    style: TextStyle(color: Colours.mintCream),
                  ),
                  onPressed: () async {
                    if (_usernameInputFormKey.currentState!.validate()) {
                      _usernameInputFormKey.currentState!.save();
                    } else {
                      return;
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
        ));
  }
}

class ManageIdentitiesPage extends StatefulWidget {
  const ManageIdentitiesPage({super.key});

  @override
  State<ManageIdentitiesPage> createState() => _ManageIdentitiesPageState();
}

class _ManageIdentitiesPageState extends State<ManageIdentitiesPage> {
  Future<Widget> _identitiesList() async {
    List<Identity> identitiesArr = await Identities().read();

    return ListView.builder(
      itemCount: identitiesArr.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(identitiesArr[index].name),
          trailing: TextButton(
            child: const Icon(
              Icons.delete,
              color: Colours.slateGray,
            ),
            onPressed: () {
              Identities().rm(identitiesArr[index]);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Generate a new keypair'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                future: _identitiesList(),
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
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor:
                        MaterialStateProperty.all(Colours.mintCream),
                  ),
                  onPressed: () {
                    confirmation(
                        context,
                        "Are you sure you want to delete all your identities",
                        "This action can not be undone",
                        setState(
                          () {},
                        ));
                  },
                  child: const Text("Delete all my identities"))
            ],
          ),
        ),
      ),
    );
  }
}
