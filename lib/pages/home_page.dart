import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  String _displayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Usuario';
    if (user.displayName != null && user.displayName!.isNotEmpty) return user.displayName!;
    if (user.email != null && user.email!.isNotEmpty) return user.email!.split('@').first;
    return 'Usuario';
  }

  void _onTapNav(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      Navigator.pushNamed(context, Routes.messages);
    } else if (index == 2) {
      Navigator.pushNamed(context, Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${_displayName()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Bienvenido a tu panel de salud', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agendar una cita (no implementado)')));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.calendar_today, size: 36, color: Color(0xFF0D47A1)),
                            SizedBox(height: 8),
                            Text('Agendar una Cita', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consejos médicos (no implementado)')));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.health_and_safety, size: 36, color: Color(0xFF0D47A1)),
                            SizedBox(height: 8),
                            Text('Consejos médicos', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Especialistas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: const [
                  ListTile(title: Text('Cardiólogo'), leading: Icon(Icons.favorite)),
                  Divider(),
                  ListTile(title: Text('Pediatra'), leading: Icon(Icons.child_care)),
                  Divider(),
                  ListTile(title: Text('Dermatólogo'), leading: Icon(Icons.medical_services)),
                  Divider(),
                  ListTile(title: Text('Ortopedista'), leading: Icon(Icons.accessibility)),
                  Divider(),
                  ListTile(title: Text('Ginecólogo'), leading: Icon(Icons.healing)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('Recomendaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Card(child: SizedBox(width: 160, child: Center(child: Text('Consulta rápida')))),
                  Card(child: SizedBox(width: 160, child: Center(child: Text('Chequeo preventivo')))),
                  Card(child: SizedBox(width: 160, child: Center(child: Text('Vacunas')))),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTapNav,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}