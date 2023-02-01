import 'package:flutter/material.dart';
import 'package:is_first_run/is_first_run.dart';

import 'pairgen.dart';
//import 'home.dart';
import 'newcontact.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EME',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const NewContactPage(),
      //home: const HomePage(),
    );
  }
}

