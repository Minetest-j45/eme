import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'contacts.dart';
import 'encrypt.dart';
import 'identities.dart';
import 'ids.dart';
import 'newcontact.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.currIdentity});

  String currIdentity = "";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _decryptErr = "";

  Future<Widget> _contactList() async {
    List<Contact> conts = await Contacts().read();
    List<String> usernames = await Contacts().nameArr();
    List<Contact> filtered = [];
    if (widget.currIdentity != "") {
      for (var cont in conts) {
        if (cont.linkedIdentity == widget.currIdentity) {
          filtered.add(cont);
        }
      }
    } else {
      filtered = conts;
    }

    List<String> hashedArr = [];
    for (var cont in filtered) {
      hashedArr.add((await RSA.hash(cont.pub, Hash.SHA256)).substring(0, 7));
    }

    return ListView.builder(
      itemCount: filtered.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
          title: RichText(
            text: TextSpan(
                style: const TextStyle(
                    color: Colours.mintCream, fontWeight: FontWeight.normal),
                children: [
                  TextSpan(
                    text: filtered[index].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.currIdentity == "") ...[
                    TextSpan(text: " - ${filtered[index].linkedIdentity}"),
                  ]
                ]),
          ),
          subtitle: Text(hashedArr[index],
              style: const TextStyle(fontFamily: "monospace")),
          trailing: PopupMenuButton<int>(
            color: Colours.slateGray,
            onSelected: (value) {
              if (value == 1) {
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return MaterialApp(
                      home: AlertDialog(
                        title: Text(
                            "Are you sure you want to remove ${filtered[index].name}?"),
                        content: const Text("This action can not be undone"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  Contacts().rm(filtered[index]);
                                });
                                Navigator.of(ctx).pop();
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
              } else if (value == 2) {
                final renameForm = GlobalKey<FormState>();
                final TextEditingController renameField =
                    TextEditingController(text: "");

                showDialog(
                  context: context,
                  builder: (ctx) {
                    return MaterialApp(
                      home: AlertDialog(
                        title: Text('Rename ${filtered[index].name}:'),
                        content: Form(
                          key: renameForm,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: TextFormField(
                            validator: (str) {
                              if (str == '') {
                                return 'Please enter the new name for ${filtered[index].name}';
                              }

                              for (var i in usernames) {
                                if (i == str) {
                                  return 'This name already exists';
                                }
                              }

                              return null;
                            },
                            controller: renameField,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter the new name for ${filtered[index].name}',
                            ),
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Ok'),
                            onPressed: () async {
                              if (renameForm.currentState!.validate()) {
                                renameForm.currentState!.save();
                              } else {
                                return;
                              }

                              setState(() {
                                Contacts().rename(
                                    filtered[index].name, renameField.text);
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colours.mintCream),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Remove",
                      style: TextStyle(color: Colours.mintCream),
                    )
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.drive_file_rename_outline_rounded,
                        color: Colours.mintCream),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Rename",
                      style: TextStyle(color: Colours.mintCream),
                    )
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EncryptPage(
                        currContact: filtered[index].name,
                        currIdentity: widget.currIdentity,
                      )),
            );
          },
        );
      },
    );
  }

  Future<Widget> _identitiesList() async {
    List<Identity> identitiesArr = await Identities().read();

    List<Widget> textButtonList = [];

    for (var id in identitiesArr) {
      textButtonList.add(
        TextButton(
          onPressed: () {
            setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(
                          currIdentity: id.name,
                        )),
              );
            });
          },
          child: Text.rich(
            TextSpan(
              text: id.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colours.mintCream),
              children: <TextSpan>[
                TextSpan(
                    text:
                        "\n${(await RSA.hash(id.pub, Hash.SHA256)).substring(0, 7)}",
                    style: const TextStyle(fontFamily: "monospace"))
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: textButtonList,
    );
  }

  Future<List<String>> _idNameArr() async {
    return await Identities().nameArr();
  }

  final _rawController = TextEditingController();
  final _decryptedController = TextEditingController();
  String _selectedIdentity = "";
  final _dropDownFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: Colours.theme,
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
              appBar: AppBar(
                  title: const Text('EME'),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colours.slateGray,
                      ),
                      onPressed: () {
                        setState(() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          );
                        });
                      },
                    ),
                  ],
                  bottom: const TabBar(tabs: [
                    Tab(
                      text: "Encrypt",
                    ),
                    Tab(
                      text: "Decrypt",
                    ),
                  ])),
              drawer: Drawer(
                  child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      color: Colours.raisinBlack,
                      child: const DrawerHeader(
                        child: Center(
                          child: Text(
                            'My Identities',
                            style: TextStyle(
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        children: <Widget>[
                          TextButton(
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colours.slateGray)),
                            child: const Text(
                              'All identities',
                              style: TextStyle(color: Colours.mintCream),
                            ),
                            onPressed: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomePage(
                                            currIdentity: "",
                                          )),
                                );
                              });
                            },
                          ),
                          TextButton(
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colours.slateGray)),
                            child: const Text(
                              'Manage identities',
                              style: TextStyle(color: Colours.mintCream),
                            ),
                            onPressed: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageIdentitiesPage()),
                                );
                              });
                            },
                          ),
                          TextButton(
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colours.slateGray)),
                            child: const Text(
                              'Add new identity',
                              style: TextStyle(color: Colours.mintCream),
                            ),
                            onPressed: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NewIdentityPage()),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
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
                  ],
                ),
              )),
              body: TabBarView(children: [
                Scaffold(
                  body: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Filters:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                                margin: const EdgeInsets.all(5.0),
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 2, color: Colours.slateGray),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Text("Identity:"),
                                    const SizedBox(width: 10),
                                    FutureBuilder(
                                      future: _idNameArr(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          List<DropdownMenuItem<String>>
                                              filterIdsList = [
                                            const DropdownMenuItem<String>(
                                              value: "",
                                              child: Text(
                                                "All",
                                                style: TextStyle(
                                                    color: Colours.slateGray),
                                              ),
                                            ),
                                          ];

                                          snapshot.data!
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: const TextStyle(
                                                    color: Colours.mintCream),
                                              ),
                                            );
                                          }).forEach((element) {
                                            filterIdsList.add(element);
                                          });

                                          return DropdownButton(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            value: widget.currIdentity,
                                            dropdownColor: Colours.jet,
                                            iconEnabledColor: Colours.slateGray,
                                            items: filterIdsList,
                                            underline: Container(
                                              height: 1,
                                              color: Colours.raisinBlack,
                                            ),
                                            onChanged: (String? value) {
                                              setState(() {
                                                if (value != null) {
                                                  widget.currIdentity = value;
                                                }
                                              });
                                            },
                                          );
                                        } else if (snapshot.hasError) {
                                          return Text("${snapshot.error}");
                                        }

                                        return const CircularProgressIndicator();
                                      },
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        FutureBuilder(
                          future: _contactList(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return snapshot.data!;
                            } else if (snapshot.hasError) {
                              return Text("${snapshot.error}");
                            }

                            return const CircularProgressIndicator();
                          },
                        ),
                      ],
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    child: const Icon(Icons.person_add_alt_1),
                    onPressed: () {
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NewContactPage(
                                    newContactName: "",
                                    newContactLinked: "",
                                  )),
                        );
                      });
                    },
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(children: <Widget>[
                    FutureBuilder(
                      future: _idNameArr(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _dropDownFormKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: DropdownButtonFormField(
                                iconEnabledColor: Colours.slateGray,
                                dropdownColor: Colours.jet,
                                borderRadius: BorderRadius.circular(10),
                                value: _selectedIdentity == ""
                                    ? null
                                    : _selectedIdentity,
                                validator: (value) => value == null
                                    ? "Please select the identity you want to use for decryption"
                                    : null,
                                hint: const Text(
                                  "Identity to use for decryption",
                                  style: TextStyle(color: Colours.mintCream),
                                ),
                                items: snapshot.data!
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                          color: Colours.mintCream),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedIdentity = value!;
                                  });
                                },
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}");
                        }

                        return const CircularProgressIndicator();
                      },
                    ),
                    TextFormField(
                      controller: _rawController,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colours.jet,
                          border: const OutlineInputBorder(),
                          hintText:
                              "Paste the encrypted message here, then press 'Decrypt'",
                          hintStyle: const TextStyle(
                              color: Colours.mintCream,
                              overflow: TextOverflow.visible),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.paste,
                              color: Colours.slateGray,
                            ),
                            onPressed: () {
                              FlutterClipboard.paste()
                                  .then((value) => setState(() {
                                        _rawController.text = value;
                                      }));
                            },
                          )),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                    Text(
                      _decryptErr,
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colours.slateGray)),
                        onPressed: () async {
                          if (_dropDownFormKey.currentState!.validate()) {
                            _dropDownFormKey.currentState!.save();
                          } else {
                            return;
                          }

                          Identity? id =
                              await Identities().get(_selectedIdentity);

                          if (id == null) {
                            return;
                          }

                          _decryptedController.text = "Loading...";

                          try {
                            String decrypted = await RSA.decryptOAEP(
                                _rawController.text, "", Hash.SHA256, id.priv);

                            setState(() {
                              _decryptedController.text = decrypted;
                            });
                          } on RSAException {
                            setState(() {
                              _decryptErr = "Error decrypting message";
                            });
                            return;
                          }
                        },
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.lock_open,
                                color: Colours.mintCream,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Decrypt',
                                style: TextStyle(color: Colours.mintCream),
                              ),
                            ])),
                    TextFormField(
                      controller: _decryptedController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colours.jet,
                        border: const OutlineInputBorder(),
                        hintText:
                            "This is the message the sender wanted you to read",
                        hintStyle: const TextStyle(
                            color: Colours.mintCream,
                            overflow: TextOverflow.visible),
                        suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colours.slateGray,
                            ),
                            onPressed: () {
                              FlutterClipboard.copy(_decryptedController.text);
                            }),
                      ),
                      maxLines: null,
                      readOnly: true,
                    ),
                  ]),
                ),
              ])),
        ));
  }
}
