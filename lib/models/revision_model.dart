import 'package:cloud_firestore/cloud_firestore.dart';

// plantilla que el coach configura en su biblioteca
class PlantillaRevision {
  final String id;
  final String titulo;
  // nombres de los parámetros a medir, ej: ["Peso (kg)", "Cintura (cm)"]
  final List<String> parametros;

  PlantillaRevision({
    required this.id,
    required this.titulo,
    required this.parametros,
  });

  factory PlantillaRevision.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PlantillaRevision(
      id: doc.id,
      titulo: data['titulo'] ?? 'Plantilla Base',
      parametros: List<String>.from(data['parametros'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'parametros': parametros,
      'fecha_creacion': FieldValue.serverTimestamp(),
    };
  }
}

// revisión rellenada por el cliente y respondida por el coach
class Revision {
  final String id;
  final DateTime fecha;
  // mapa parámetro → valor, ej: {"Peso (kg)": 80.5}
  final Map<String, dynamic> valoresParametros;
  final List<String> fotosUrl;
  final String sensacionesCliente;
  final String respuestaCoach;
  // pendiente | revisada
  final String estado;

  Revision({
    required this.id,
    required this.fecha,
    required this.valoresParametros,
    required this.fotosUrl,
    required this.sensacionesCliente,
    required this.respuestaCoach,
    required this.estado,
  });

  factory Revision.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Revision(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      valoresParametros: Map<String, dynamic>.from(data['valores_parametros'] ?? {}),
      fotosUrl: List<String>.from(data['fotos_url'] ?? []),
      sensacionesCliente: data['sensaciones_cliente'] ?? '',
      respuestaCoach: data['respuesta_coach'] ?? '',
      estado: data['estado'] ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'valores_parametros': valoresParametros,
      'fotos_url': fotosUrl,
      'sensaciones_cliente': sensacionesCliente,
      'respuesta_coach': respuestaCoach,
      'estado': estado,
    };
  }
}
