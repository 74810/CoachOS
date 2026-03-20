import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String texto;
  final bool esEntrenador;
  final DateTime fecha;

  Mensaje({
    required this.id,
    required this.texto,
    required this.esEntrenador,
    required this.fecha,
  });

  factory Mensaje.fromFirestore(Map<String, dynamic> data, String id) {
    return Mensaje(
      id: id,
      texto: data['texto'] ?? '',
      esEntrenador: data['esEntrenador'] ?? true,
      // Manejamos la fecha que viene de Firebase
      fecha: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}