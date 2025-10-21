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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores de los campos del formulario
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController enfermedadesController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController lugarNacimientoController = TextEditingController();
  final TextEditingController padecimientosController = TextEditingController();

  bool _loading = false;
  // _loading es un interruptor visual:
  // /true -> muestra un "Cargando..." y bloquea la UI.
  // /false -> muestra la pantalla normal.

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  // Aquí creamos la clase que cargará los datos del usuario al iniciar.

  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nombreController.text = data['nombre'] ?? '';
      telefonoController.text = data['telefono'] ?? '';
      // Compatibilidad: el campo pudo haberse llamado 'enfermedades', 'padecimientos' o 'historial'
      enfermedadesController.text = data['enfermedades'] ?? data['padecimientos'] ?? data['historial'] ?? '';
      // Campos nuevos: edad, lugar de nacimiento y padecimientos
      edadController.text = (data['edad'] ?? data['age'] ?? '').toString();
      lugarNacimientoController.text = data['lugarNacimiento'] ?? data['birthplace'] ?? '';
      padecimientosController.text = data['padecimientos'] ?? data['enfermedades'] ?? data['historial'] ?? '';
    }
  }

  // Guardar datos del usuario en Firestore
  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    // Validación simple
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
      return;
    }

    setState(() => _loading = true);
    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': nombreController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'enfermedades': enfermedadesController.text.trim(),
        'edad': edadController.text.trim(),
        'lugarNacimiento': lugarNacimientoController.text.trim(),
        'padecimientos': padecimientosController.text.trim(),
        'email': user.email,
        'uid': user.uid,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Información guardada exitosamente")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Mostrar formulario para registrar un paciente (sin requerir autenticación)
  Future<void> _showPatientRegistrationForm() async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController pName = TextEditingController();
    final TextEditingController pPhone = TextEditingController();
    final TextEditingController pAge = TextEditingController();
    final TextEditingController pSymptoms = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Paciente'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: pName,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
                  ),
                  TextFormField(
                    controller: pPhone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: pAge,
                    decoration: const InputDecoration(labelText: 'Edad'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: pSymptoms,
                    decoration: const InputDecoration(labelText: 'Síntomas / Padecimientos'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop(); // cerrar diálogo mientras se guarda
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
        );
      },
    );
  }

  // Intentar registrar paciente en la colección 'pacientes'
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paciente registrado correctamente')));
      print('[profile_page] Paciente registrado: ${docRef.id}');
    } catch (e) {
      print('[profile_page] Error al registrar paciente: $e');
      if (!mounted) return;
      // Si la causa es permisos, explicarlo al usuario
      final err = e.toString();
      if (err.toLowerCase().contains('permission') || err.toLowerCase().contains('permission_denied') || err.toLowerCase().contains('permission-denied') || err.toLowerCase().contains('permis')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo registrar el paciente: permisos insuficientes. Revisa las reglas de Firestore.')));
        // Mostrar diálogo con instrucciones
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permisos insuficientes'),
            content: const Text('La escritura fue denegada por las reglas de Firestore. Para permitir registros sin autenticación, ajusta las reglas o crea un endpoint seguro en servidor.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
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
      appBar: AppBar(title: const Text("Perfil")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Correo: ${user?.email ?? 'No disponible'}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    // Botón para registrar paciente (aparece al inicio)
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _showPatientRegistrationForm,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Registrar Paciente'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                    const SizedBox(height: 12),
                    // Text
                    const SizedBox(height: 8),

                    // FORMULARIO
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: "Nombre completo"),
                    ), // TextField
                    const SizedBox(height: 10),

                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: "Teléfono"),
                      keyboardType: TextInputType.phone,
                    ), // TextField
                    const SizedBox(height: 10),

                    // Edad
                    TextField(
                      controller: edadController,
                      decoration: const InputDecoration(labelText: "Edad"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),

                    // Lugar de nacimiento
                    TextField(
                      controller: lugarNacimientoController,
                      decoration: const InputDecoration(labelText: "Lugar de nacimiento"),
                    ),
                    const SizedBox(height: 10),

                    // Padecimientos / enfermedades
                    TextField(
                      controller: padecimientosController, // sincronizado con Firestore
                      decoration: const InputDecoration(labelText: "Padecimientos / Enfermedades"),
                      maxLines: 3,
                    ), // TextField
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _loading ? null : _saveUserData,
                      child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Guardar información"),
                    ), // ElevatedButton
                    const SizedBox(height: 30),

                    // ♦ Botón para volver al menú principal
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Volver al Menú Principal"),
                    ), // ElevatedButton

                    const SizedBox(height: 20),

                    // ♦ Botón para cerrar sesión
                    ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                        // Comprobamos que el widget sigue "montado" antes de usar el BuildContext
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, Routes.login);
                      },
                      child: const Text("Cerrar sesión"),
                    ), // ElevatedButton
                  ],
                ), // Column
              ), // SingleChildScrollView
            ), // Padding
    ); // Scaffold
  }
}