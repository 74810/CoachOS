import 'package:cloud_firestore/cloud_firestore.dart';

// --- 1. MODELO DE LA PLANTILLA (Lo que el Coach configura en Ajustes) ---
class PlantillaRevision {
  final String id;
  final String titulo;
  // Aquí guardamos los nombres exactos de lo que queremos medir.
  // Ej: ["Peso (kg)", "Cintura (cm)", "Calidad del Sueño (1-10)"]
  final List<String> parametros; 

  PlantillaRevision({
    required this.id, 
    required this.titulo, 
    required this.parametros
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

// --- 2. MODELO DE LA REVISIÓN (Lo que rellena el Cliente y contesta el Coach) ---
class Revision {
  final String id;
  final DateTime fecha;
  
  // Usamos un Map para emparejar el parámetro con el valor real que puso el cliente
  // Ej: {"Peso (kg)": 80.5, "Cintura (cm)": 90.0} -> Perfecto para gráficas futuras
  final Map<String, dynamic> valoresParametros; 
  
  final List<String> fotosUrl; 
  final String sensacionesCliente; 
  final String respuestaCoach; 
  final String estado; // Puede ser: 'pendiente' o 'revisada'

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