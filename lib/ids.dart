import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'home.dart';
import 'identities.dart';

class NewIdentityPage extends StatefulWidget {
  const NewIdentityPage({super.key});

  @override
  State<NewIdentityPage> createState() => _NewIdentityPageState();
}

class _NewIdentityPageState extends State<NewIdentityPage> {
  String _keySize = "4096";
  List<String> keySizeOptions = <String>["2048", "3072", "4096"];

  Future<Widget> _usernameInput() async {
    var identities = await Identities().read();
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (str) {
        if (str == null) {
          return null;
        } else if (str == '') {
          return '*Please enter a name*';
        } else if (str.contains('|')) {
          return '*Disallowed character: |*';
        }

        for (var i in identities) {
          if (i.name == nameController.value.text) {
            return "*This name already exists*";
          }
        }
        return null;
      },
      controller: nameController,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colours.jet,
        border: OutlineInputBorder(),
        errorStyle: TextStyle(fontWeight: FontWeight.bold),
        hintText: 'Enter the desired username for this identity',
        hintStyle: TextStyle(color: Colours.mintCream),
      ),
    );
  }

  final nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.06;
    return MaterialApp(
        theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: Colours.raisinBlack,
              secondary: Colours.slateGray,
            ),
            scaffoldBackgroundColor: Colours.spaceCadet,
            canvasColor: Colours.spaceCadet,
            textTheme: Colours.mintCreamText),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Generate a new keypair'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
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
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline),
                      color: Colours.slateGray,
                    ),
                    /*const Text(
                        "RSA key size: (2048 for lower end devices; 4096 for highest security; 3072 for somewhere inbetween)"),*/
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

  void _confirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text(
              "Are you sure you want to delete all your identities?"),
          content: const Text("This action CANNOT be undone"),
          actions: [
            TextButton(
                onPressed: () {
                  setState(() {});

                  Identities().rmAll();
                  Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Colours.raisinBlack,
            secondary: Colours.slateGray,
          ),
          scaffoldBackgroundColor: Colours.spaceCadet,
          canvasColor: Colours.spaceCadet,
          textTheme: Colours.mintCreamText),
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
                    _confirmation(context);
                  },
                  child: const Text("Delete all my identities"))
            ],
          ),
        ),
      ),
    );
  }
}
