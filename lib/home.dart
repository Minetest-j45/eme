import 'package:adler32/adler32.dart';
import 'package:flutter/material.dart';

import 'contacts.dart';
import 'identities.dart';
import 'newcontact.dart';
import 'pairgen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.currIdentity});

  final String currIdentity;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
            onLongPress: () {
              //some sort of confirmation dialog
              setState(() {
                Contacts().rm(filtered[index]);
                setState(() {});
              });
            }
            //onTap: encrypt to
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
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
          title: const Text('All Identities'),
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
      ])),
      body: Center(
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
    );
  }
}
