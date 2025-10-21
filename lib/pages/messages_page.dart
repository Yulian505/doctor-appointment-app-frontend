import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: const Center(
        child: Text('Pantalla de mensajes (placeholder)\nNo funcional por ahora', textAlign: TextAlign.center),
      ),
    );
  }
}
