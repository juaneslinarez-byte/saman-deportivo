import 'package:flutter/material.dart';

void main() {
  runApp(const SamanDeportivoApp());
}

class SamanDeportivoApp extends StatelessWidget {
  const SamanDeportivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Samán Deportivo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Samán Deportivo'))),
    );
  }
}
