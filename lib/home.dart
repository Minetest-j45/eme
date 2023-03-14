import 'package:adler32/adler32.dart';
import 'package:clipboard/clipboard.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';

import 'contacts.dart';
import 'encrypt.dart';
import 'identities.dart';
import 'newcontact.dart';
import 'pairgen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.currIdentity});

  final String currIdentity;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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

    return ListView.builder(
      itemCount: filtered.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(filtered[index].name),
          subtitle: Text(Adler32.str(filtered[index].pub).toString()),
          trailing: const Icon(Icons.more_vert),
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

    return ListView.builder(
      itemCount: identitiesArr.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(identitiesArr[index].name),
          subtitle: Text(Adler32.str(identitiesArr[index].pub).toString()),
          //todo: manage identities page on long press
          onTap: () {
            setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(
                          currIdentity: identitiesArr[index].name,
                        )),
              );
            });
          },
        );
      },
    );
  }

  var _selectedIdentity = "";
  Future<Widget> _identitiesDropDown() async {
    List<Identity> identitiesArr = await Identities().read();
    List<String> identitiesStrs = [];
    for (var identity in identitiesArr) {
      identitiesStrs.add(identity.name);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton(
        borderRadius: BorderRadius.circular(10),
        value: _selectedIdentity == "" ? null : _selectedIdentity,
        hint: SizedBox(
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
          setState(() {});
        },
      ),
    );
  }

  final _rawController = TextEditingController();
  final _decryptedController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('EME'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
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
              child: ListView(children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
              ),
              child: Text(
                'My Identities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('All identities'),
              onTap: () {
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
            /*ListTile(
          title: const Text('Manage identities'),
          onTap: () {
            setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageIdentitiesPage()),
              );
            });
          },
        ),*/
            ListTile(
              //TODO move to settings (delete all option) or/and manage identities
              title: const Text('Delete all identities'),
              onTap: () {
                setState(() {
                  Identities().rmAll();
                });
              },
            ),
            ListTile(
              title: const Text('Add new identity'),
              onTap: () {
                setState(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewIdentityPage()),
                  );
                });
              },
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
          ])),
          body: TabBarView(children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Welcome to EME'),
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
                  TextButton(
                      child: const Text('Add basic testing contact'),
                      onPressed: () {
                        Contacts().add(Contact(
                            name: 'Mario', pub: '1234', linkedIdentity: 'joe'));
                        setState(() {});
                      }),
                  TextButton(
                    child: const Text('Add new contact'),
                    onPressed: () {
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NewContactPage()),
                        );
                      });
                    },
                  ),
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
                    border: const OutlineInputBorder(),
                    hintText:
                        "Paste the encrypted message here, then press Decrypt",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: () {
                        FlutterClipboard.paste().then((value) => setState(() {
                              _rawController.text = value;
                            }));
                      },
                    )),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              TextButton(
                  child: const Text('Decrypt'),
                  onPressed: () async {
                    Identity? id = await Identities().get(widget.currIdentity);

                    var decrypted = await RSA.decryptOAEP(
                        _rawController.text, "", Hash.SHA256, id!.priv);

                    setState(() {
                      _decryptedController.text = decrypted;
                    });
                  }),
              TextFormField(
                controller: _decryptedController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "This is the message the sender wanted you to read",
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        FlutterClipboard.copy(_decryptedController.text);
                      }),
                ),
                maxLines: null,
                readOnly: true,
              ),
              TextButton(
                child: const Text("Done"),
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
              )
            ]),
          ])),
    ));
  }
}
