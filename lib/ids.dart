import 'dart:convert';

import 'package:fast_rsa/fast_rsa.dart';
import 'package:file_picker/file_picker.dart';
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (str) {
          if (str == '') {
            return 'Please enter the desired name for this new identity';
          } else if (str!.contains('|')) {
            return 'Disallowed character: |';
          }

          for (var i in identities) {
            if (i == nameController.value.text) {
              return "An identity with this name already exists";
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
            title: const Text('New Identity'),
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
                SingleTapButton(
                  delay: 10,
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colours.slateGray)),
                  child: const Text(
                    'Generate new keypair',
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
                const Text("or", style: TextStyle(color: Colours.mintCream)),
                TextButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colours.slateGray)),
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(withData: true);

                      if (result != null) {
                        var private = utf8.decode(result.files.first.bytes!);
                        String public = "";

                        try {
                          public =
                              await RSA.convertPrivateKeyToPublicKey(private);

                          await RSA.encryptOAEP(
                              "test", "", Hash.SHA256, public);
                        } on RSAException {}

                        if (public != "") {
                          Identities().add(Identity(
                              name: nameController.value.text,
                              pub: public,
                              priv: private));

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
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                  title: const Text(
                                      "Error with uploaded private key"),
                                  content: const Text(
                                      "Please make sure it is PEM encoded in a file with nothing else"),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        child: const Text("Okay")),
                                  ]);
                            },
                          );
                        }
                      } else {
                        // User canceled the picker
                      }
                    },
                    child: const Text(
                      "Upload private key",
                      style: TextStyle(color: Colours.mintCream),
                    )),
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
              showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return MaterialApp(
                    home: AlertDialog(
                      title: Text(
                          "Are you sure you want to delete ${identitiesArr[index].name}?"),
                      content: const Text("This action can not be undone"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              setState(() {
                                Identities().rm(identitiesArr[index]);
                              });

                              Navigator.of(ctx).pop();
                              if (identitiesArr.length == 1) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NewIdentityPage()),
                                );
                              }
                            },
                            child: const Text("Yes")),
                        TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                            child: const Text("No")),
                      ],
                    ),
                  );
                },
              );
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
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
                          title: const Text(
                              "Are you sure you want to delete all your identities"),
                          content: const Text("This action can not be undone"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Identities().rmAll();

                                  setState(
                                    () {
                                      Navigator.of(context).pop();

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const NewIdentityPage()),
                                      );
                                    },
                                  );
                                },
                                child: const Text("Yes")),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("No")),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("Delete all my identities"))
            ],
          ),
        ),
      ),
    );
  }
}
