import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final edadController = TextEditingController();
  final lugarNacimientoController = TextEditingController();
  final padecimientosController = TextEditingController();

  bool _loading = false;
  String selectedRole = 'paciente';
  bool isUpdatingRole = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserRole();
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    edadController.dispose();
    lugarNacimientoController.dispose();
    padecimientosController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        nombreController.text = data['nombre'] ?? '';
        telefonoController.text = data['telefono'] ?? '';
        edadController.text = (data['edad'] ?? '').toString();
        lugarNacimientoController.text = data['lugarNacimiento'] ?? '';
        padecimientosController.text = data['padecimientos'] ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        String role = doc['role'] ?? 'paciente';
        if (role != 'paciente' && role != 'medico') {
          role = 'paciente';
        }
        setState(() => selectedRole = role);
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': 'paciente',
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => selectedRole = 'paciente');
      }
    } catch (e) {
      print('Error loading role: $e');
    }
  }

  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para guardar')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': nombreController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'edad': edadController.text.trim(),
        'lugarNacimiento': lugarNacimientoController.text.trim(),
        'padecimientos': padecimientosController.text.trim(),
        'email': user.email ?? '',
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateRole(String newRole) async {
    setState(() => isUpdatingRole = true);
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set(
        {'role': newRole, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      setState(() => selectedRole = newRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado a ${newRole == 'medico' ? 'Médico' : 'Paciente'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isUpdatingRole = false);
    }
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: pName, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
            TextFormField(controller: pPhone, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
            TextFormField(controller: pAge, decoration: const InputDecoration(labelText: 'Edad'), keyboardType: TextInputType.number),
            TextFormField(controller: pSymptoms, decoration: const InputDecoration(labelText: 'Síntomas'), maxLines: 3),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              await _registerPatient(nombre: pName.text.trim(), telefono: pPhone.text.trim(), edad: pAge.text.trim(), sintomas: pSymptoms.text.trim());
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerPatient({required String nombre, String? telefono, String? edad, String? sintomas}) async {
    if (nombre.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre es obligatorio')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paciente registrado')));
      print('[profile_page] Paciente registrado: ${docRef.id}');
    } catch (e) {
      print('[profile_page] Error al registrar paciente: $e');
      if (!mounted) return;
      final err = e.toString();
      if (err.toLowerCase().contains('permission') || err.toLowerCase().contains('permission_denied') || err.toLowerCase().contains('permis')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permisos insuficientes en Firestore')));
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permisos insuficientes'),
            content: const Text('La escritura fue denegada por las reglas de Firestore. Ajusta las reglas o crea un endpoint seguro en servidor.'),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), backgroundColor: Colors.teal.shade700),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.local_hospital, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(child: Text('Correo: ${user?.email ?? 'No disponible'}')),
            ]),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rol actual:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                        DropdownMenuItem(value: 'medico', child: Text('Médico')),
                      ],
                      onChanged: isUpdatingRole
                          ? null
                          : (value) {
                              if (value != null) {
                                _updateRole(value);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _loading ? null : _showPatientRegistrationForm, icon: const Icon(Icons.person_add), label: const Text('Registrar Paciente'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal)),
            const SizedBox(height: 12),
            const Text('Últimos pacientes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('pacientes').orderBy('createdAt', descending: true).limit(20).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Text('No hay pacientes');
                return Column(children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final sintomas = data['sintomas'] ?? data['padecimientos'] ?? '';
                  return Dismissible(
                    key: Key(d.id),
                    direction: DismissDirection.endToStart,
                    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                    confirmDismiss: (direction) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: const Text('¿Eliminar este paciente? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                          ],
                        ),
                      );
                      return confirm == true;
                    },
                    onDismissed: (_) async {
                      try {
                        await _firestore.collection('pacientes').doc(d.id).delete();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paciente eliminado')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
                      }
                    },
                    child: Card(child: ListTile(title: Text(data['nombre'] ?? 'Sin nombre'), subtitle: Text(sintomas), onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(data['nombre'] ?? ''), content: Text(sintomas), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar'))])))),
                  );
                }).toList());
              },
            ),
            const SizedBox(height: 18),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
              TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre completo')),
              const SizedBox(height: 8),
              TextField(controller: telefonoController, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: edadController, decoration: const InputDecoration(labelText: 'Edad'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: lugarNacimientoController, decoration: const InputDecoration(labelText: 'Lugar de nacimiento')),
              const SizedBox(height: 8),
              TextField(controller: padecimientosController, decoration: const InputDecoration(labelText: 'Padecimientos'), maxLines: 3),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loading ? null : _saveUserData, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar información'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700)),
            ]))),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al Menú Principal')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async { await _auth.signOut(); if (!mounted) return; Navigator.pushReplacementNamed(context, Routes.login); }, child: const Text('Cerrar sesión')),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}
