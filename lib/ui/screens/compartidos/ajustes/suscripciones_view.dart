import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../config/theme.dart';

class SuscripcionesView extends StatefulWidget {
  final String rol;
  const SuscripcionesView({super.key, required this.rol});

  @override
  State<SuscripcionesView> createState() => _SuscripcionesViewState();
}

class _SuscripcionesViewState extends State<SuscripcionesView> {
  bool _actualizando = false;

  // Definición de los planes para el Entrenador
  final List<Map<String, dynamic>> _planesCoach = [
    {
      'id': 'cantera',
      'nombre': 'Cantera',
      'precio': '0€',
      'limite': '3 clientes',
      'color': Colors.grey,
      'ventajas': ['Gestión básica', 'Revisiones ilimitadas', 'Chat con clientes'],
    },
    {
      'id': 'rookie',
      'nombre': 'Rookie',
      'precio': '19.99€/mes',
      'limite': '15 clientes',
      'color': Colors.blue,
      'ventajas': ['Soporte prioritario', 'Estadísticas avanzadas', 'Hasta 15 atletas'],
    },
    {
      'id': 'all-star',
      'nombre': 'All-Star',
      'precio': '39.99€/mes',
      'limite': '30 clientes',
      'color': AppTheme.secondaryOrange,
      'ventajas': ['Personalización total', 'Exportación de datos', 'Hasta 30 atletas'],
    },
    {
      'id': 'hall of fame',
      'nombre': 'Hall of Fame',
      'precio': '79.99€/mes',
      'limite': 'Ilimitado',
      'color': Colors.purple,
      'ventajas': ['Sin límites', 'Acceso anticipado', 'Marketing incluido'],
    },
  ];

  Future<void> _cambiarPlan(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _actualizando = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'plan_suscripcion': planId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Plan actualizado a ${planId.toUpperCase()}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esEntrenador = widget.rol == 'entrenador';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: Text(esEntrenador ? "Planes de Suscripción" : "Mi Tarifa"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final planActual = data['plan_suscripcion'] ?? 'cantera';

          if (!esEntrenador) {
            return _buildVistaCliente(data);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _planesCoach.length,
            itemBuilder: (context, index) {
              final plan = _planesCoach[index];
              final bool esElActual = planActual == plan['id'];

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: esElActual ? Border.all(color: plan['color'], width: 2) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    // Cabecera del plan
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: plan['color'].withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(plan['nombre'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: plan['color'])),
                          if (esElActual)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: plan['color'], borderRadius: BorderRadius.circular(10)),
                              child: const Text("ACTUAL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plan['precio'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              Text(plan['limite'], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const Divider(height: 30),
                          ...List.generate(plan['ventajas'].length, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: plan['color'], size: 18),
                                const SizedBox(width: 10),
                                Text(plan['ventajas'][i], style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          )),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: esElActual ? Colors.grey.shade300 : plan['color'],
                              onPressed: (esElActual || _actualizando) ? null : () => _cambiarPlan(plan['id']),
                              child: _actualizando && !esElActual 
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : Text(esElActual ? "Plan Activo" : "Seleccionar Plan", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Vista simplificada para el Cliente
  Widget _buildVistaCliente(Map<String, dynamic> data) {
    final int precio = data['precio_tarifa'] ?? 0;
    final String tipo = data['tipo_tarifa'] ?? 'Mensual';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.creditcard, size: 50, color: AppTheme.primaryBlue),
            const SizedBox(height: 20),
            const Text("Tu suscripción actual", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text("$precio€", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            Text("Tarifa $tipo", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 30),
            const Text("Los pagos se gestionan directamente con tu entrenador.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}