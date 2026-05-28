import 'package:cloud_firestore/cloud_firestore.dart';

class Rutina {
  final String id;
  final String titulo;
  final String notas;
  final List<EjercicioAsignado> ejercicios;

  Rutina({
    required this.id,
    required this.titulo,
    required this.notas,
    required this.ejercicios,
  });

  factory Rutina.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Rutina(
      id: doc.id,
      titulo: data['titulo'] ?? 'Sin título',
      notas: data['notas'] ?? '',
      ejercicios: (data['ejercicios'] as List? ?? [])
          .map((e) => EjercicioAsignado.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ejercicio embebido dentro del array de la rutina
class EjercicioAsignado {
  String nombre;
  String series;
  String repeticiones;
  String notaEjercicio;

  EjercicioAsignado({
    required this.nombre,
    required this.series,
    required this.repeticiones,
    required this.notaEjercicio,
  });

  factory EjercicioAsignado.fromMap(Map<String, dynamic> data) {
    return EjercicioAsignado(
      nombre: data['nombre'] ?? '',
      series: data['series'] ?? '',
      repeticiones: data['repeticiones'] ?? '',
      notaEjercicio: data['nota_ejercicio'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'series': series,
    'repeticiones': repeticiones,
    'nota_ejercicio': notaEjercicio,
  };
}
