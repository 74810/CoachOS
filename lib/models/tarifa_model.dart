class Tarifa {
  final String id;
  final String nombre;
  final int precio;
  final String descripcion;
  final int diasGracia;
  final bool esVisible; 

  Tarifa({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.diasGracia,
    this.esVisible = true, 
  });

  //Método para convertir de Firebase a Objeti Tarifa
  factory Tarifa.fromFirestore(Map<String, dynamic> data, String id) {
  return Tarifa(
    id: id,
    nombre: data['nombre'] ?? '',
    precio: (data['precio'] ?? 0).toInt(), 
    descripcion: data['descripcion'] ?? '',
    diasGracia: (data['diasGracia'] ?? 0).toInt(),
    esVisible: data['esVisible'] ?? true,
  );
}

  //Método para convertir de Objeto Dart a Firebase Tarifa
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'diasGracia': diasGracia,
      'esVisible': esVisible, 
    };
  }
}