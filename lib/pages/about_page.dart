import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre nosotros')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Información sobre la aplicación y el equipo...'),
      ),
    );
  }
}