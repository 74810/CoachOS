import 'package:cloud_firestore/cloud_firestore.dart';

class Dieta {
  final String id;
  final String titulo;
  final String tipo;
  final String notasGenerales;

  // --- CAMPOS PARA TIPO 'MACROS' ---
  final int? kcal;
  final int? proteina;
  final int? carbos;
  final int? grasas;

  // --- CAMPOS PARA TIPO 'CERRADA' o 'PORCIONES' ---
  final List<Comida>? comidas;

  Dieta({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.notasGenerales,
    this.kcal,
    this.proteina,
    this.carbos,
    this.grasas,
    this.comidas,
  });

  // Convertir de Firebase a la App
  factory Dieta.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Dieta(
      id: doc.id,
      titulo: data['titulo'] ?? 'Sin título',
      tipo: data['tipo'] ?? 'cerrada',
      notasGenerales: data['notas_generales'] ?? '',
      kcal: data['kcal'],
      proteina: data['proteina'],
      carbos: data['carbos'],
      grasas: data['grasas'],
      comidas: data['comidas'] != null 
          ? (data['comidas'] as List).map((c) => Comida.fromMap(c as Map<String, dynamic>)).toList()
          : null,
    );
  }

  // Convertir de la App a Firebase
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'tipo': tipo,
      'notas_generales': notasGenerales,
      'kcal': kcal,
      'proteina': proteina,
      'carbos': carbos,
      'grasas': grasas,
      'comidas': comidas?.map((c) => c.toMap()).toList(),
    };
  }
}

class Comida {
  String nombre; 
  List<String> elementos;

  Comida({
    required this.nombre,
    required this.elementos,
  });

  factory Comida.fromMap(Map<String, dynamic> data) {
    return Comida(
      nombre: data['nombre'] ?? 'Comida',
      elementos: List<String>.from(data['elementos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'elementos': elementos,
    };
  }
}