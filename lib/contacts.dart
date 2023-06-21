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

  Future<List<String>> nameArr() async {
    List<Contact> contactsArr = await read();
    List<String> contactsStrs = [];
    for (Contact contact in contactsArr) {
      contactsStrs.add(contact.name);
    }

    return contactsStrs;
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
    List<Contact> contacts = await read();
    contacts.add(contact);
    _write(contacts);
  }

  Future<void> rm(Contact contact) async {
    List<Contact> contacts = await read();
    for (Contact cont in contacts) {
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
    List<Contact> contacts = await read();
    for (Contact cont in contacts) {
      if (cont.name == name) {
        return cont;
      }
    }

    return null;
  }

  void rename(String oldName, newName) async {
    Contact? oldContact = await get(oldName);
    if (oldContact == null) {
      return;
    }

    await rm(oldContact);

    add(Contact(
        name: newName,
        pub: oldContact.pub,
        linkedIdentity: oldContact.linkedIdentity));
  }

  void rmAll() {
    _write([]);
  }
}
