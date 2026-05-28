import 'dart:convert';
import 'package:http/http.dart' as http;

class ResultadoAlimento {
  final String nombre;
  final String marca;
  final String? imagenUrl;
  final double? calorias;
  final double? proteinas;
  final double? carbohidratos;
  final double? grasas;

  ResultadoAlimento({
    required this.nombre,
    required this.marca,
    this.imagenUrl,
    this.calorias,
    this.proteinas,
    this.carbohidratos,
    this.grasas,
  });
}

// error diferenciado para mostrar feedback distinto en la UI
enum ErrorBusqueda { red, sinResultados }

class ResultadoBusqueda {
  final List<ResultadoAlimento> productos;
  final ErrorBusqueda? error;

  const ResultadoBusqueda.ok(this.productos) : error = null;
  const ResultadoBusqueda.error(this.error) : productos = const [];

  bool get tieneResultados => productos.isNotEmpty;
  bool get hayError => error != null;
}

class ApiNutricionService {
  // world.openfoodfacts.org tiene más productos que el subdominio regional es.
  static const String _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  Future<ResultadoBusqueda> buscarAlimentos(
    String termino, {
    int pageSize = 10,
    String? categoriaTag,
  }) async {
    if (termino.trim().isEmpty) return const ResultadoBusqueda.ok([]);

    final buffer = StringBuffer();
    buffer.write('$_baseUrl?search_terms=${Uri.encodeComponent(termino)}');
    buffer.write('&search_simple=1&action=process&json=1');
    buffer.write('&page_size=$pageSize');
    // preferir resultados en español
    buffer.write('&lc=es&cc=es');

    if (categoriaTag != null && categoriaTag.isNotEmpty) {
      buffer.write('&tagtype_0=categories');
      buffer.write('&tag_contains_0=contains');
      buffer.write('&tag_0=${Uri.encodeComponent(categoriaTag)}');
    }

    try {
      final respuesta = await http
          .get(Uri.parse(buffer.toString()))
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode != 200) {
        return const ResultadoBusqueda.error(ErrorBusqueda.red);
      }

      final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final productos = json['products'] as List?;

      if (productos == null || productos.isEmpty) {
        return const ResultadoBusqueda.error(ErrorBusqueda.sinResultados);
      }

      final lista = productos
          .whereType<Map<String, dynamic>>()
          .map(_parsearProducto)
          .toList();

      if (lista.isEmpty) {
        return const ResultadoBusqueda.error(ErrorBusqueda.sinResultados);
      }

      return ResultadoBusqueda.ok(lista);
    } on Exception {
      return const ResultadoBusqueda.error(ErrorBusqueda.red);
    }
  }

  static ResultadoAlimento _parsearProducto(Map<String, dynamic> p) {
    final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    // prioridad de nombre: es > genérico es > internacional > genérico
    final nombre = [
      p['product_name_es'],
      p['generic_name_es'],
      p['product_name'],
      p['generic_name'],
    ].firstWhere(
      (n) => n != null && (n as String).trim().isNotEmpty,
      orElse: () => '',
    )?.toString().trim() ?? '';

    return ResultadoAlimento(
      nombre: nombre,
      marca: (p['brands'] ?? '').toString().trim(),
      imagenUrl: p['image_front_small_url']?.toString(),
      calorias: toDouble(nutriments['energy-kcal_100g']),
      proteinas: toDouble(nutriments['proteins_100g']),
      carbohidratos: toDouble(nutriments['carbohydrates_100g']),
      grasas: toDouble(nutriments['fat_100g']),
    );
  }
}
