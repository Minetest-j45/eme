import 'package:flutter/material.dart';
import 'contacts.dart';

class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});


  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
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
            Padding(
              padding: EdgeInsets.all(width),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: _nameIsEmpty,
                  labelText: 'Enter the desired username for this identity *',
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}