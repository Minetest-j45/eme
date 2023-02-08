import 'package:adler32/adler32.dart';
import 'package:flutter/material.dart';

import 'contacts.dart';
import 'newcontact.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Widget> _contactList() async {
    List<Contact> conts = await Contacts().read();
    return ListView.builder(
      itemCount: conts.length,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
            title: Text(conts[index].name),
            //do subtitle hash of key in future
            subtitle: Text(Adler32.str(conts[index].pub).toString()),
            trailing: Icon(Icons.more_vert),
            onLongPress: () {
              //some sort of confirmation dialog
              setState(() {
                conts.removeAt(index);
                Contacts().write(conts);
                setState(() {});
              });
            }
            //onTap: encrypt to
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EME'),
      ),
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
                  Contacts().add(Contact(name: 'Bob', pub: '123'));
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
