import 'dart:convert';

import 'storage.dart';

class Contact {
  String name;
  String pub;

  Contact({required this.name, required this.pub});
}

class Contacts {
  Future<List<Contact>> read() async {
    var string = await Storage().read('contacts');

    final json = jsonDecode(string);

    List<Contact> contacts = [];
    for (var cont in json['contacts']) {
      contacts.add(Contact(name: cont['name'], pub: cont['pub']));
    }

    return contacts;
  }

  void write(List<Contact> contacts) async {  
    final json = jsonEncode({
      'contacts': contacts.map((contact) => {
        'name': contact.name,
        'pub': contact.pub,
      }).toList(),
    });

    await Storage().write('contacts', json);
  }

  void add(Contact contact) async {
    var contacts = await read();
    contacts.add(contact);
    write(contacts);
  }

  void rm(Contact contact) async {
    var contacts = await read();
    contacts.remove(contact);
    write(contacts);
  }
}
