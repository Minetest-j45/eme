import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'colours.dart';
import 'contacts.dart';
import 'encrypt.dart';
import 'identities.dart';
import 'ids.dart';
import 'newcontact.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.currIdentity});

  final String currIdentity;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _decryptErr = "";

  Future<Widget> _contactList() async {
    List<Contact> conts = await Contacts().read();
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
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            filtered[index].name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colours.mintCream),
          ),
          subtitle: Text(hashedArr[index],
              style: const TextStyle(
                  fontWeight: FontWeight.w400, fontFamily: "monospace")),
          trailing: const Icon(
            Icons.more_vert,
            color: Colours.slateGray,
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
          onLongPress: () {
            //some sort of confirmation dialog
            setState(() {
              Contacts().rm(filtered[index]);
              setState(() {});
            });
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w400, fontFamily: "monospace"))
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

  var _selectedIdentity = "";
  Future<Widget> _identitiesDropDown() async {
    List<String> identitiesStrs = await Identities().nameArr();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton(
        dropdownColor: Colours.jet,
        borderRadius: BorderRadius.circular(10),
        value: _selectedIdentity == "" ? null : _selectedIdentity,
        hint: SizedBox(
          width: MediaQuery.of(context).size.width * 0.65,
          child: const Text(
            "Identity to use for decryption",
            style: TextStyle(color: Colours.mintCream),
          ),
        ),
        items: identitiesStrs.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: Colours.mintCream),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          _selectedIdentity = value!;
          setState(() {});
        },
      ),
    );
  }

  final _rawController = TextEditingController();
  final _decryptedController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    String nicename = ": ${widget.currIdentity}";
    if (widget.currIdentity == '') {
      nicename = " all:";
    }
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
                        /*setState(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()),
                );
              });*/
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
                                      builder: (context) => const HomePage(
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
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Contacts for$nicename',
                        style: const TextStyle(
                            fontSize: 26,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            child: const Icon(Icons.person_add_alt_1),
                            onPressed: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NewContactPage()),
                                );
                              });
                            },
                          ),
                          FloatingActionButton(
                            heroTag: "Test",
                            child: const Icon(Icons.textsms_sharp),
                            onPressed: () {
                              setState(() {
                                Contacts().add(Contact(
                                    name: "jeff",
                                    pub: "gbk",
                                    linkedIdentity: "guess"));
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Column(children: <Widget>[
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
                      Identity? id =
                          await Identities().get(_selectedIdentity) ??
                              await Identities().get(widget.currIdentity);

                      if (id == null) {
                        _decryptErr =
                            "*Please select an identity to use for decryption*";
                        setState(() {});
                        return;
                      }

                      try {
                        String decrypted = await RSA.decryptOAEP(
                            _rawController.text, "", Hash.SHA256, id.priv);

                        setState(() {
                          _decryptedController.text = decrypted;
                        });
                      } on RSAException {
                        _decryptErr =
                            "*This doesnt seem to be a valid encrypted message*";
                        setState(() {});
                        return;
                      }
                    },
                    child: const Text(
                      'Decrypt',
                      style: TextStyle(color: Colours.mintCream),
                    ),
                  ),
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
                  TextButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colours.slateGray)),
                    onPressed: () {
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              currIdentity: widget.currIdentity,
                            ),
                          ),
                        );
                      });
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(color: Colours.mintCream),
                    ),
                  )
                ]),
              ])),
        ));
  }
}
