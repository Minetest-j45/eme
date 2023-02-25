//reused code from contacts.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage.dart';

class Identity {
  String name;
  String pub;
  String priv;

  Identity({required this.name, required this.pub, required this.priv});
}

class Identities {
  final FlutterSecureStorage _securestorage = const FlutterSecureStorage();

  //format: name|
  Future<List<Identity>> read() async {
    //Storage().write('identities', '');//used to clear identities
    var raw = await Storage().read('identities');

    if (raw == '') {
      return [];
    }

    List<String> identitiesString = raw.split('|');

    List<Identity> identities = [];

    for (var identity in identitiesString) {
      if (identity == '') {
        continue;
      }

      String public = await _securestorage.read(key: "${identity}_pub") ?? '';
      String private = await _securestorage.read(key: "${identity}_priv") ?? '';
      identities.add(Identity(name: identity, pub: public, priv: private));
    }

    return identities;
  }

  void write(List<Identity> identities) async {
    var string = '';
    for (var identity in identities) {
      string += '${identity.name}|';
    }

    await Storage().write('identities', string);
  }

  void add(Identity identity) async {
    var identities = await read();
    identities.add(identity);
    write(identities);
    await _securestorage.write(
        key: '${identity.name}_pub', value: identity.pub);
    await _securestorage.write(
        key: '${identity.name}_priv', value: identity.priv);
  }

  void rm(Identity identity) async {
    var identities = await read();
    identities.remove(identity);
    write(identities);
    await _securestorage.delete(key: '${identity.name}_pub');
    await _securestorage.delete(key: '${identity.name}_priv');
  }

  void rmAll() async {
    var identities = await read();
    for (var identity in identities) {
      await _securestorage.delete(key: '${identity.name}_pub');
      await _securestorage.delete(key: '${identity.name}_priv');
    }
    await Storage().write('identities', '');
  }
}
