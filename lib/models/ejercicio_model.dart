class Ejercicio {
  final String id;
  final String nombre;
  final String musculo;
  final String material;
  final String tipo;
  final String categoria;

  Ejercicio({
    required this.id, 
    required this.nombre, 
    required this.musculo, 
    required this.material,
    required this.tipo,
    required this.categoria,
  });

  factory Ejercicio.fromFirestore(Map<String, dynamic> data, String id) {
    return Ejercicio(
      id: id,
      nombre: data['nombre'] ?? '',
      musculo: data['musculo'] ?? '',
      material: data['material'] ?? '',
      tipo: data['tipo'] ?? '',
      categoria: data['categoria'] ?? '',
    );
  }
}