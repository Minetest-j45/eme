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
    if (string.isEmpty) {
      string = '{"contacts":[]}';
    }
    final json = jsonDecode(string);

    List<Contact> contacts = [];
    for (var cont in json['contacts']) {
      contacts.add(Contact(name: cont['name'], pub: cont['pub']));
    }

    return contacts;
  }

  void _write(List<Contact> contacts) async {
    final json = jsonEncode({
      'contacts': contacts
          .map((contact) => {
                'name': contact.name,
                'pub': contact.pub,
              })
          .toList(),
    });

    await Storage().write('contacts', json);
  }

  void add(Contact contact) async {
    var contacts = await read();
    contacts.add(contact);
    _write(contacts);
  }

  void rm(Contact contact) async {
    var contacts = await read();
    for (var cont in contacts) {
      if ((cont.name == contact.name) &&
          (cont.pub == contact.pub) &&
          (cont.linked_identity == contact.linked_identity)) {
        contacts.remove(cont);
        _write(contacts);
        break;
      }
    }
  }
}
