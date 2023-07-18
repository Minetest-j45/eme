import 'dart:convert';

import 'package:fast_rsa/fast_rsa.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'home.dart';
import 'identities.dart';
import 'util.dart';

class NewIdentityPage extends StatefulWidget {
  const NewIdentityPage({super.key, required this.backwardsEnabled});

  final bool backwardsEnabled;

  @override
  State<NewIdentityPage> createState() => _NewIdentityPageState();
}

class _NewIdentityPageState extends State<NewIdentityPage> {
  final _usernameInputFormKey = GlobalKey<FormState>();

  Future<List<String>> _identitiesNameArr() async {
    return await Identities().nameArr();
  }

  final nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => widget.backwardsEnabled,
        child: MaterialApp(
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
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.06),
                      child: FutureBuilder(
                        future: _identitiesNameArr(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Form(
                              key: _usernameInputFormKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: TextFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (str) {
                                  if (str == '') {
                                    return 'Please enter the desired name for this new identity';
                                  } else if (str!.contains('|')) {
                                    return 'Disallowed character: |';
                                  }

                                  for (var i in snapshot.data!) {
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
                                  hintText:
                                      'Enter the desired username for this identity',
                                  hintStyle:
                                      TextStyle(color: Colours.mintCream),
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}");
                          }

                          return const CircularProgressIndicator();
                        },
                      ),
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

                        var pair = await RSA.generate(4096);
                        Identities().add(Identity(
                            name: nameController.value.text,
                            pub: pair.publicKey,
                            priv: pair.privateKey));

                        setState(() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                currIdentity: "",
                              ),
                            ),
                          );
                        });
                      },
                    ),
                    TextButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(withData: true);

                          if (result != null) {
                            var private =
                                utf8.decode(result.files.first.bytes!);
                            String public = "";

                            try {
                              public = await RSA
                                  .convertPrivateKeyToPublicKey(private);

                              await RSA.encryptOAEP(
                                  "test", "", Hash.SHA256, public);
                            } on RSAException {
                              //
                            }

                            if (public != "") {
                              Identities().add(Identity(
                                  name: nameController.value.text,
                                  pub: public,
                                  priv: private));

                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(
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
                          }
                        },
                        child: const Text(
                          "Or upload private key",
                          style: TextStyle(
                            color: Colours.slateGray,
                            decoration: TextDecoration.underline,
                          ),
                        )),
                  ],
                ),
              ),
            )));
  }
}

class ManageIdentitiesPage extends StatefulWidget {
  const ManageIdentitiesPage({super.key});

  @override
  State<ManageIdentitiesPage> createState() => _ManageIdentitiesPageState();
}

class _ManageIdentitiesPageState extends State<ManageIdentitiesPage> {
  Future<List<Identity>> _identitiesList() async {
    return await Identities().read();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Colours.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Identities'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                future: _identitiesList(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(snapshot.data![index].name),
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
                                          "Are you sure you want to delete ${snapshot.data![index].name}?"),
                                      content: const Text(
                                          "This action can not be undone"),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              setState(() {
                                                Identities()
                                                    .rm(snapshot.data![index]);
                                              });

                                              Navigator.of(ctx).pop();
                                              if (snapshot.data!.length == 1) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const NewIdentityPage(
                                                              backwardsEnabled:
                                                                  false)),
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
                                                const NewIdentityPage(
                                                  backwardsEnabled: false,
                                                )),
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
