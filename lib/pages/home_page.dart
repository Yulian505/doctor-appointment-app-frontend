import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'dashboard_page.dart';   // 🔹 IMPORTANTE: agregado

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  bool _isRefreshing = false;
  late List<String> _specialistsList;

  String _fallbackDisplayName(User? user) {
    if (user == null) return 'Usuario';
    if (user.displayName != null && user.displayName!.isNotEmpty) return user.displayName!;
    if (user.email != null && user.email!.isNotEmpty) return user.email!.split('@').first;
    return 'Usuario';
  }

  void _onTapNav(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, Routes.messages);
    } else if (index == 2) {
      Navigator.pushNamed(context, Routes.settings);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        await _firestore.collection('usuarios').doc(user.uid).get();
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al refrescar los datos'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _specialistsList = [
      'Cardiólogo',
      'Pediatra',
      'Dermatólogo',
      'Ortopedista',
      'Ginecólogo'
    ];
  }

  void _showSpecialistOptions(String name) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name),
        content: Text('Opciones para $name'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushNamed(context, Routes.citas);
            },
            child: const Text('Agendar cita'),
          ),
        ],
      ),
    );
  }

  IconData _iconForSpecialist(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cardio')) return Icons.favorite;
    if (lower.contains('pedia')) return Icons.child_care;
    if (lower.contains('derm')) return Icons.medical_services;
    if (lower.contains('ortho')) return Icons.accessibility;
    if (lower.contains('gine')) return Icons.healing;
    return Icons.person;
  }

  Future<void> _showPatientRegistrationForm() async {
    final _formKey = GlobalKey<FormState>();
    final pName = TextEditingController();
    final pPhone = TextEditingController();
    final pAge = TextEditingController();
    final pSymptoms = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Paciente'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pName,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                  controller: pPhone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone),
              TextFormField(
                  controller: pAge,
                  decoration: const InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number),
              TextFormField(
                  controller: pSymptoms,
                  decoration: const InputDecoration(labelText: 'Síntomas'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              await _registerPatient(
                nombre: pName.text.trim(),
                telefono: pPhone.text.trim(),
                edad: pAge.text.trim(),
                sintomas: pSymptoms.text.trim(),
              );
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerPatient(
      {required String nombre,
      String? telefono,
      String? edad,
      String? sintomas}) async {
    if (nombre.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es obligatorio')));
      return;
    }
    setState(() => _loading = true);
    try {
      final docRef = await _firestore.collection('pacientes').add({
        'nombre': nombre,
        'telefono': telefono ?? '',
        'edad': edad ?? '',
        'sintomas': sintomas ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Paciente registrado')));
    } catch (e) {
      final err = e.toString();
      if (err.toLowerCase().contains('permission')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permisos insuficientes en Firestore')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: RefreshIndicator(
        displacement: 50.0,
        strokeWidth: 4.0,
        color: Colors.blue.shade700,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _auth.currentUser == null
                          ? null
                          : _firestore
                              .collection('usuarios')
                              .doc(_auth.currentUser!.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final user = _auth.currentUser;
                        String name = _fallbackDisplayName(user);
                        if (snapshot.hasData &&
                            snapshot.data!.exists &&
                            snapshot.data!.data() != null) {
                          final data = snapshot.data!.data();
                          if (data!['nombre'] != null &&
                              data['nombre'].toString().trim().isNotEmpty) {
                            name = data['nombre'];
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Hola, $name',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : _showPatientRegistrationForm,
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Registrar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Bienvenido a tu panel de salud',
                                style:
                                    TextStyle(color: Colors.black54)),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 🔹🔹🔹 AQUI AGREGO EL DASHBOARD MÉDICO 🔹🔹🔹
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.blue.shade50,
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(
                                  context, Routes.citas),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.calendar_today,
                                        size: 36,
                                        color: Color(0xFF0D47A1)),
                                    SizedBox(height: 8),
                                    Text('Agendar una Cita',
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 🔸 TARJETA NUEVA: Dashboard Médico
                        Expanded(
                          child: Card(
                            color: Colors.orange.shade50,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DashboardPage(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.dashboard,
                                        size: 36,
                                        color: Color(0xFFEF6C00)),
                                    SizedBox(height: 8),
                                    Text('Dashboard Médico',
                                        textAlign: TextAlign.center),
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
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Consejos médicos (no implementado)'))),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.health_and_safety,
                                        size: 36,
                                        color: Color(0xFF0D47A1)),
                                    SizedBox(height: 8),
                                    Text('Consejos médicos',
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text('Especialistas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      elevation: 2,
                      child: Column(
                        children: _specialistsList.map((s) {
                          return Column(
                            children: [
                              Dismissible(
                                key: ValueKey(s),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (direction) {
                                  setState(() {
                                    _specialistsList.remove(s);
                                  });
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text('$s eliminado')));
                                },
                                child: ListTile(
                                  title: Text(s),
                                  leading: Icon(_iconForSpecialist(s),
                                      color: Colors.blue.shade700),
                                  onTap: () => _showSpecialistOptions(s),
                                ),
                              ),
                              if (_specialistsList.last != s)
                                const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text('Recomendaciones',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          Card(
                              child: SizedBox(
                                  width: 160,
                                  child: Center(
                                      child: Text('Consulta rápida')))),
                          Card(
                              child: SizedBox(
                                  width: 160,
                                  child: Center(
                                      child: Text('Chequeo preventivo')))),
                          Card(
                              child: SizedBox(
                                  width: 160,
                                  child: Center(child: Text('Vacunas')))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTapNav,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}
