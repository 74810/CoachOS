import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart'; 

class PerfilUsuarioView extends StatelessWidget {
  final String uid;

  const PerfilUsuarioView({super.key, required this.uid});

  // Función para calcular la edad automáticamente a partir de la fecha de nacimiento
  String _calcularEdad(Timestamp? timestamp) {
    if (timestamp == null) return "No especificada";
    final birthDate = timestamp.toDate();
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return "$age años";
  }

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
          
          // Detectar el rol
          final String rol = data['rol']?.toString().toLowerCase() ?? '';
          final bool esEntrenador = rol == 'entrenador';

          // Datos comunes
          final telefono = data['telefono']?.toString() ?? '';

          // Datos de Entrenador
          final biografia = data['descripcion']?.toString() ?? '';
          final horario = data['horario']?.toString() ?? '';

          // Datos de Cliente (La Anamnesis)
          final altura = data['altura']?.toString() ?? '';
          final lesiones = data['lesiones']?.toString() ?? '';
          final alergias = data['alergias']?.toString() ?? '';
          final edad = _calcularEdad(data['fecha_nacimiento'] as Timestamp?);

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
                esEntrenador ? "Entrenador" : "Cliente",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),
              
              const Text("CONTACTO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 10),
              _buildCajaInfo("Email", data['email'] ?? "No disponible", CupertinoIcons.mail),
              _buildCajaInfo("Teléfono", telefono.isEmpty ? "No especificado" : telefono, CupertinoIcons.phone),
              
              const SizedBox(height: 20),

              if (esEntrenador) ...[
                const Text("DETALLES PROFESIONALES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 10),
                _buildCajaInfo(
                  "Biografía", 
                  biografia.isEmpty ? "El entrenador aún no ha escrito su biografía." : biografia, 
                  CupertinoIcons.doc_text
                ),
                _buildCajaInfo(
                  "Horario de atención", 
                  horario.isEmpty ? "No especificado." : horario, 
                  CupertinoIcons.clock
                ),
              ] else ...[
                // SI ES CLIENTE: MOSTRAMOS SU FICHA CLÍNICA
                const Text("DATOS CLÍNICOS Y FÍSICOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildCajaInfo("Edad", edad, CupertinoIcons.calendar)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCajaInfo("Altura", altura.isEmpty ? "No esp." : "$altura cm", CupertinoIcons.arrow_up_down)),
                  ],
                ),
                _buildCajaInfo("Lesiones / Patologías", lesiones.isEmpty ? "Ninguna registrada." : lesiones, CupertinoIcons.bandage),
                _buildCajaInfo("Alergias / Intolerancias", alergias.isEmpty ? "Ninguna registrada." : alergias, CupertinoIcons.exclamationmark_triangle),
              ]
            ],
          );
        },
      ),
    );
  }

  // Widget visual para mostrar cada dato
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