import 'dart:convert';

import 'storage.dart';

class Contact {
  String name;
  String pub;
  String linkedIdentity;

  Contact(
      {required this.name, required this.pub, required this.linkedIdentity});
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
      contacts.add(Contact(
          name: cont['name'],
          pub: cont['pub'],
          linkedIdentity: cont['linked_identity']));
    }

    return contacts;
  }

  void _write(List<Contact> contacts) async {
    final json = jsonEncode({
      'contacts': contacts
          .map((contact) => {
                'name': contact.name,
                'pub': contact.pub,
                'linked_identity': contact.linkedIdentity,
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
          (cont.linkedIdentity == contact.linkedIdentity)) {
        contacts.remove(cont);
        _write(contacts);
        break;
      }
    }
  }

  Future<Contact?> get(String name) async {
    var contacts = await read();
    for (var cont in contacts) {
      if (cont.name == name) {
        return cont;
      }
    }

    return null;
  }
}
