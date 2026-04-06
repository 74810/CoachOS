import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../config/theme.dart';

class PrincipalTab extends StatelessWidget {
  const PrincipalTab({super.key});
  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool pagada = data['cuota_pagada'] ?? false;

        return Scaffold(
          backgroundColor: AppTheme.lightBlue,
          appBar: AppBar(
            title: const Text("¿QUÉ TOCA HOY?", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ESTADO DE CUOTA
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: pagada ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: pagada ? Colors.green : Colors.red, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(pagada ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.exclamationmark_triangle_fill, 
                         color: pagada ? Colors.green : Colors.red),
                    const SizedBox(width: 12),
                    Text(pagada ? "Suscripción Activa" : "Pago Pendiente", 
                         style: TextStyle(fontWeight: FontWeight.bold, color: pagada ? Colors.green[800] : Colors.red[800])),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              
              const Text("¿QUÉ TOCA HOY?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
              const SizedBox(height: 15),
              
              _buildTaskCard("Entrenamiento", "Pecho y Tríceps", CupertinoIcons.flame, AppTheme.secondaryOrange),
              const SizedBox(height: 12),
              _buildTaskCard("Nutrición", "Déficit Calórico - 2100 kcal", CupertinoIcons.drop, AppTheme.mediumBlue),
              
              const SizedBox(height: 30),
              const Text("ULTIMA REVISIÓN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
              const SizedBox(height: 15),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${data['peso'] ?? '--'} kg", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    const Icon(CupertinoIcons.graph_square, color: AppTheme.mediumBlue),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }
}