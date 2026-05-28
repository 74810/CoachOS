import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String emisorId;
  final String texto;
  final Timestamp fecha;

  Mensaje({required this.emisorId, required this.texto, required this.fecha});

  factory Mensaje.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Mensaje(
      emisorId: data['emisor_id'] ?? '',
      texto: data['texto'] ?? '',
      fecha: data['fecha'] ?? Timestamp.now(),
    );
  }
}
