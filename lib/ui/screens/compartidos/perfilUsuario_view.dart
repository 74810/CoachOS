import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart'; 

class PerfilUsuarioView extends StatelessWidget {
  final String uid;

  const PerfilUsuarioView({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: const Text("Información", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Usuario no encontrado"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final String rol = data['rol']?.toString().toLowerCase() ?? '';
          final bool esCoach = rol == 'entrenador' || rol == 'coach';

          final biografia = data['descripcion'] ?? '';
          final horario = data['horario'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(CupertinoIcons.person_fill, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              Text(
                esCoach ? "Entrenador / Coach" : "Cliente",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),
              
              // INFORMACIÓN DE CONTACTO
              const Text("CONTACTO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 10),
              _buildCajaInfo("Email", data['email'] ?? "No disponible", CupertinoIcons.mail),
              _buildCajaInfo("Teléfono", data['telefono'] ?? "No disponible", CupertinoIcons.phone),
              
              const SizedBox(height: 20),

              if (esCoach) ...[
                const Text("DETALLES PROFESIONALES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 10),
                
                _buildCajaInfo(
                  "Biografía", 
                  biografia.toString().isEmpty ? "El coach aún no ha escrito su biografía." : biografia, 
                  CupertinoIcons.doc_text
                ),
                
                _buildCajaInfo(
                  "Horario de atención", 
                  horario.toString().isEmpty ? "No especificado." : horario, 
                  CupertinoIcons.clock
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCajaInfo(String titulo, String valor, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppTheme.mediumBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(valor, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }
}