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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String tarifa = data['tipo_tarifa'] ?? "Sin Tarifa";
        final int precio = data['precio_tarifa'] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.checkmark_seal_fill, size: 100, color: Colors.green),
              const SizedBox(height: 30),
              const Text("Estás suscrito al plan:", style: TextStyle(color: Colors.grey)),
              Text(tarifa.toUpperCase(), 
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
              const SizedBox(height: 10),
              Text("$precio€ / mes", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text(
                "Cualquier cambio en tu facturación o plan de entrenamiento debe ser gestionado directamente con tu Coach a través del chat.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- VISTA PARA EL COACH (Tu diseño original) ---
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