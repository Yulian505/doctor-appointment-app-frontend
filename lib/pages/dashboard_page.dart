import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // <CHANGE> Stream que devuelve datos en tiempo real por motivo
  Stream<List<PieChartSectionData>> _getPieChartDataByMotivo() {
    return _firestore.collection('citas').snapshots().map((snapshot) {
      // Contar citas por motivo
      final Map<String, int> motivoCount = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final motivo = data['motivo'] ?? 'Sin especificar';
        motivoCount[motivo] = (motivoCount[motivo] ?? 0) + 1;
      }

      // Colores para cada sección
      final colors = [
        Colors.blue,
        Colors.orange,
        Colors.green,
        Colors.red,
        Colors.purple,
        Colors.yellow,
        Colors.cyan,
        Colors.pink,
        Colors.teal,
        Colors.brown,
      ];

      // Convertir a PieChartSectionData
      int colorIndex = 0;
      return motivoCount.entries.map((entry) {
        final section = PieChartSectionData(
          value: entry.value.toDouble(),
          color: colors[colorIndex % colors.length],
          title: '${entry.value}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
        colorIndex++;
        return section;
      }).toList();
    });
  }

  // <CHANGE> Stream que devuelve gráfica de barras por mes
  Stream<BarChartData> _getBarChartDataByMonth() {
    return _firestore.collection('citas').snapshots().map((snapshot) {
      // Contar citas por mes
      final Map<int, int> monthCount = {
        1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0,
        7: 0, 8: 0, 9: 0, 10: 0, 11: 0, 12: 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final fechaHora = data['fechaHora'] as Timestamp?;
        if (fechaHora != null) {
          final date = fechaHora.toDate();
          monthCount[date.month] = (monthCount[date.month] ?? 0) + 1;
        }
      }

      // Convertir a BarChartGroupData
      final barGroups = monthCount.entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: Colors.blue,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList();

      return BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (monthCount.values.isNotEmpty ? monthCount.values.reduce((a, b) => a > b ? a : b) + 2 : 5).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                final index = value.toInt() - 1;
                return index >= 0 && index < months.length
                    ? Text(months[index], style: const TextStyle(fontSize: 10))
                    : const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        barGroups: barGroups,
      );
    });
  }

  // Helper para tarjetas
  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 28,
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Médico'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Usuario no encontrado'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... existing code ...
                  Card(
                    color: Colors.blue.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email ?? 'Usuario',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // <CHANGE> Tarjeta de total de citas con datos en tiempo real
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('citas').snapshots(),
                    builder: (context, snapshot) {
                      int totalCitas = snapshot.data?.docs.length ?? 0;
                      return _buildDashboardCard(
                        icon: Icons.calendar_today,
                        title: 'Total de Citas',
                        value: totalCitas.toString(),
                        color: Colors.blue,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // <CHANGE> Tarjeta de pacientes registrados
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('pacientes').snapshots(),
                    builder: (context, snapshot) {
                      int totalPacientes = snapshot.data?.docs.length ?? 0;
                      return _buildDashboardCard(
                        icon: Icons.people,
                        title: 'Total de Pacientes',
                        value: totalPacientes.toString(),
                        color: Colors.green,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // <CHANGE> GRÁFICA DE PASTEL POR MOTIVO
                  const Text(
                    'Citas por Tipo de Motivo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<List<PieChartSectionData>>(
                    stream: _getPieChartDataByMotivo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(
                          height: 300,
                          child: Center(child: Text('No hay citas creadas')),
                        );
                      }

                      return SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: snapshot.data!,
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // <CHANGE> GRÁFICA DE BARRAS POR MES
                  const Text(
                    'Citas por Mes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<BarChartData>(
                    stream: _getBarChartDataByMonth(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 280,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 280,
                          child: Center(child: Text('No hay datos disponibles')),
                        );
                      }

                      return SizedBox(
                        height: 280,
                        child: BarChart(snapshot.data!),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // <CHANGE> ÚLTIMAS CITAS
                  const Text(
                    'Últimas Citas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('citas')
                        .orderBy('fechaHora', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final citas = snapshot.data?.docs ?? [];

                      if (citas.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay citas registradas'),
                          ),
                        );
                      }

                      return Column(
                        children: citas.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final motivo = data['motivo'] ?? 'Sin motivo';
                          final nombreUsuario = data['nombreUsuario'] ?? 'Sin nombre';
                          final fechaHora = data['fechaHora'] as Timestamp?;
                          final fechaFormato = fechaHora?.toDate().toString().split('.')[0] ?? 'Sin fecha';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_today,
                                color: Colors.blue,
                              ),
                              title: Text(motivo),
                              subtitle: Text('$nombreUsuario • $fechaFormato'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ... existing code ...
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _auth.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, Routes.login);
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}