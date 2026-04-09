import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/rutina_model.dart'; 
import '../../../config/theme.dart';      

class EntrenoCliente extends StatelessWidget {
  const EntrenoCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Error: No hay usuario logueado")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Mi Entrenamiento", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('rutinas')
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator(radius: 15));
          }

          // PANTALLA VACÍA PREMIUM
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_run_rounded, size: 60, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(height: 24),
                  const Text("¡Día de descanso!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 10),
                  const Text("Tu entrenador aún no te ha\nasignado nuevas rutinas.", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4)
                  ),
                ],
              ),
            );
          }

          final rutinas = snapshot.data!.docs.map((doc) => Rutina.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40),
            itemCount: rutinas.length,
            itemBuilder: (context, index) {
              return _buildCardRutinaCliente(rutinas[index]);
            },
          );
        },
      ),
    );
  }

  //TARJETA PRINCIPAL DE LA RUTINA
  Widget _buildCardRutinaCliente(Rutina rutina) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightBlue.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          iconColor: AppTheme.secondaryOrange,
          collapsedIconColor: AppTheme.primaryBlue,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.secondaryOrange, size: 24),
          ),
          title: Text(rutina.titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryBlue)),
          subtitle: Text("${rutina.ejercicios.length} ejercicios asignados", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13)),
          children: [
            // NOTA GENERAL DEL ENTRENADOR
            if (rutina.notas.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1))
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, color: AppTheme.primaryBlue, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rutina.notas, 
                        style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)
                      )
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 8),
            // LISTA DE EJERCICIOS
            ...rutina.ejercicios.map((ej) => _buildFilaEjercicioCliente(ej)).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  //TARJETA DE CADA EJERCICIO INDIVIDUAL
  Widget _buildFilaEjercicioCliente(EjercicioAsignado ej) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ICONITO DE PESA BLANCO CON SOMBRA
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]
                ),
                child: const Icon(Icons.fitness_center_rounded, size: 18, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              
              // NOMBRE DEL EJERCICIO
              Expanded(
                child: Text(
                  ej.nombre, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                )
              ),
              
              //SERIES Y REPETICIONES
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue, 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                ),
                child: Text(
                  "${ej.series} x ${ej.repeticiones}", 
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13, letterSpacing: 0.5)
                ),
              ),
            ],
          ),
          
          // NOTA ESPECÍFICA DEL EJERCICIO
          if (ej.notaEjercicio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14, left: 46),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.secondaryOrange.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ej.notaEjercicio, 
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4, fontWeight: FontWeight.w500)
                    )
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}