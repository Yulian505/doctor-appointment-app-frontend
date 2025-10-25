import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitasPage extends StatefulWidget {
  const CitasPage({super.key});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _motivoController = TextEditingController();

  String? nombreUsuario;
  DateTime? fechaSeleccionada;
  String? _citaEnEdicion; // ID de la cita que estamos editando

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  // Cargar el nombre del usuario desde Firestore
  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          nombreUsuario = doc.data()!['nombre'] ?? 'Usuario sin nombre';
        });
      }
    }
  }

  // Seleccionar fecha y hora
  Future<void> _seleccionarFechaYHora() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      // Verificar si el contexto sigue siendo válido
      if (!mounted) return;
      
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaSeleccionada ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          fechaSeleccionada = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Agregar o actualizar cita
  Future<void> _guardarCita() async {
    if (_motivoController.text.isEmpty || fechaSeleccionada == null) {
      // Verificar si el contexto sigue siendo válido
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final data = {
      'nombreUsuario': nombreUsuario ?? 'Sin nombre',
      'motivo': _motivoController.text.trim(),
      'fechaHora': Timestamp.fromDate(fechaSeleccionada!),
      'creadoEn': FieldValue.serverTimestamp(),
    };

    if (_citaEnEdicion == null) {
      await _firestore.collection('citas').add(data);
      // Verificar si el contexto sigue siendo válido
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cita creada")));
    } else {
      await _firestore.collection('citas').doc(_citaEnEdicion).update(data);
      // Verificar si el contexto sigue siendo válido
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Cita actualizada")));
    }

    _motivoController.clear();
    setState(() {
      fechaSeleccionada = null;
      _citaEnEdicion = null;
    });
  }
//
  // Eliminar cita
  Future<void> _eliminarCita(String id) async {
    await _firestore.collection('citas').doc(id).delete();
    // Verificar si el contexto sigue siendo válido
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Cita eliminada")));
  }

  // Preparar cita para edición
  void _editarCita(String id, Map<String, dynamic> data) {
    setState(() {
      _citaEnEdicion = id;
      _motivoController.text = data['motivo'] ?? '';
      fechaSeleccionada =
          (data['fechaHora'] as Timestamp?)?.toDate() ?? DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Citas")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              nombreUsuario == null
                  ? 'Cargando usuario...'
                  : 'Usuario: $nombreUsuario',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ), // Text
            const SizedBox(height: 10),
            TextField(
              controller: _motivoController,
              decoration: const InputDecoration(labelText: 'Motivo de la cita'),
            ), // TextField
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    fechaSeleccionada == null
                        ? 'No se ha seleccionado fecha y hora'
                        : 'Fecha: ${fechaSeleccionada.toString()}', // Text
                  ), // Expanded
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _seleccionarFechaYHora,
                ), // IconButton
              ],
            ), // Row
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _guardarCita,
              child: Text(
                  _citaEnEdicion == null ? 'Programar cita' : 'Guardar cambios'),
            ), // ElevatedButton
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('citas')
                    .orderBy('fechaHora', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final citas = snapshot.data!.docs;
                  if (citas.isEmpty) {
                    return const Center(child: Text('No hay citas programadas'));
                  }

                  return ListView.builder(
                    itemCount: citas.length,
                    itemBuilder: (context, index) {
                      final cita = citas[index];
                      final data = cita.data() as Map<String, dynamic>;

                      final fecha = (data['fechaHora'] as Timestamp?)?.toDate();

                      return Card(
                        child: ListTile(
                          title: Text(
                              '${data['motivo'] ?? 'Sin motivo'} (${data['nombreUsuario'] ?? 'Desconocido'})'),
                          subtitle: Text(
                              'Fecha: ${fecha != null ? fecha.toString() : 'Sin fecha'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editarCita(cita.id, data),
                              ), // IconButton
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarCita(cita.id),
                              ), // IconButton
                            ],
                          ), // Row
                        ), // ListTile
                      ); // Card
                    },
                  ); // ListView.builder
                },
              ), // StreamBuilder
            ), // Expanded
          ],
        ), // Column
      ), // Padding
    ); // Scaffold
  }
} // _CitasPageState