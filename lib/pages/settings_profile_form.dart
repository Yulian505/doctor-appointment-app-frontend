import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This form mirrors ProfilePage and persists the same fields to Firestore

class SettingsProfileForm extends StatefulWidget {
  const SettingsProfileForm({super.key});

  @override
  State<SettingsProfileForm> createState() => _SettingsProfileFormState();
}

class _SettingsProfileFormState extends State<SettingsProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController birthplaceController = TextEditingController();
  final TextEditingController conditionsController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['nombre'] ?? '';
      ageController.text = (data['edad'] ?? data['age'] ?? '').toString();
      birthplaceController.text = data['lugarNacimiento'] ?? data['birthplace'] ?? '';
      conditionsController.text = data['padecimientos'] ?? data['enfermedades'] ?? data['historial'] ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': nameController.text.trim(),
        'edad': ageController.text.trim(),
        'lugarNacimiento': birthplaceController.text.trim(),
        'padecimientos': conditionsController.text.trim(),
        'email': user.email,
        'uid': user.uid,
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil guardado')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil (editar)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Edad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: birthplaceController,
                decoration: const InputDecoration(labelText: 'Lugar de nacimiento', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: conditionsController,
                decoration: const InputDecoration(labelText: 'Padecimientos', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
