import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_os_app/config/theme.dart';

class SuscripcionesView extends StatelessWidget {
  final String rol;
  const SuscripcionesView({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final bool esCoach = rol == 'entrenador';

    return Scaffold(
      appBar: AppBar(
        title: Text(esCoach ? "Planes de Negocio" : "Mi Tarifa Activa"),
      ),
      body: esCoach ? _buildCoachView(context) : _buildClienteView(),
    );
  }

  // --- VISTA PARA EL CLIENTE ---
  Widget _buildClienteView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Error de sesión"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
      builder: (context, snapshotUsuario) {
        if (!snapshotUsuario.hasData) return const Center(child: CupertinoActivityIndicator());
        
        final data = snapshotUsuario.data?.data() as Map<String, dynamic>? ?? {};
        
        // Extracción 100% segura para evitar el cuelgue rojo
        final String tarifaActual = data['tipo_tarifa']?.toString() ?? "Sin Tarifa";
        final dynamic precioRaw = data['precio_tarifa'];
        final String precioActual = precioRaw != null ? precioRaw.toString() : "0";
        final String entrenadorId = data['entrenador_id']?.toString() ?? "";

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // MI TARIFA ACTUAL
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.mediumBlue],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 10)]
              ),
              child: Column(
                children: [
                  const Text("MI PLAN ACTUAL", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(tarifaActual.toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("$precioActual€ / mes", style: const TextStyle(fontSize: 20, color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text("PLANES DISPONIBLES DE MI COACH", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),

            // LISTA DE TARIFAS DEL COACH
            if (entrenadorId.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Aún no tienes un entrenador asignado para ver sus planes.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ))
            else
              StreamBuilder<QuerySnapshot>(
                // Traemos todas las tarifas visibles (quitamos el filtro estricto de Firebase para no liarla con los nombres)
                stream: FirebaseFirestore.instance.collection('tarifas')
                    .where('esVisible', isEqualTo: true) 
                    .snapshots(),
                builder: (context, snapshotTarifas) {
                  if (snapshotTarifas.connectionState == ConnectionState.waiting) return const CupertinoActivityIndicator();
                  
                  // FILTRO INTELIGENTE: Busca si el ID coincide en 'coachId' O en 'entrenador_id'
                  final tarifas = snapshotTarifas.data?.docs.where((doc) {
                    final t = doc.data() as Map<String, dynamic>;
                    final idCoachTarifa = t['coachId'] ?? t['entrenador_id'] ?? '';
                    return idCoachTarifa == entrenadorId;
                  }).toList() ?? [];
                  
                  if (tarifas.isEmpty) return const Text("Tu entrenador no ha publicado planes de suscripción todavía.");

                  return Column(
                    children: tarifas.map((doc) {
                      final t = doc.data() as Map<String, dynamic>;
                      bool esLaMia = t['nombre'] == tarifaActual;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: esLaMia ? Border.all(color: AppTheme.secondaryOrange, width: 2) : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t['nombre'] ?? 'Plan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                                Text("${t['precio'] ?? 0}€", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.secondaryOrange)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(t['descripcion'] ?? 'Sin descripción', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 16),
                            if (!esLaMia)
                              SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  color: AppTheme.lightBlue,
                                  child: const Text("Seleccionar este plan", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                                  onPressed: () async {
                                    // Actualizar tarifa en Firebase
                                    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
                                      'tipo_tarifa': t['nombre'],
                                      'precio_tarifa': t['precio'],
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan actualizado. Avisa a tu Coach por el chat."), backgroundColor: Colors.green));
                                    }
                                  },
                                ),
                              )
                            else
                              const Center(child: Text("Este es tu plan actual", style: TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 13))),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              )
          ],
        );
      },
    );
  }

  // --- VISTA PARA EL COACH ---
  Widget _buildCoachView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Elige el nivel de tu academia", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        _buildPlanCard(context, title: "CANTERA", price: "GRATIS", limit: "3 alumnos", desc: "Primeros pasos.", color: Colors.grey, isCurrent: true),
        _buildPlanCard(context, title: "DRAFT", price: "14,90€", limit: "15 alumnos", desc: "Gestión total.", color: AppTheme.mediumBlue, isCurrent: false),
        _buildPlanCard(context, title: "PRO", price: "29,90€", limit: "Ilimitados", desc: "Sin límites.", color: AppTheme.secondaryOrange, isCurrent: false),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, {required String title, required String price, required String limit, required String desc, required Color color, required bool isCurrent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              if (isCurrent) const Badge(label: Text("ACTUAL"), backgroundColor: Colors.green),
            ],
          ),
          Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(limit, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}