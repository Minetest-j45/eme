import 'package:flutter/material.dart';

import 'home.dart';

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
        primarySwatch:
            Colors.purple, //todo: make all colours from colour scheme
      ),
      home: const HomePage(
        currIdentity: "",
      ),
    );
  }
}
