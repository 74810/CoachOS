import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_nutricion_service.dart';

// Categorías disponibles con su tag de Open Food Facts
const List<Map<String, String?>> _kCategorias = [
  {'label': 'Todos',      'tag': null},
  {'label': 'Carnes',     'tag': 'en:meats'},
  {'label': 'Pescados',   'tag': 'en:fish-and-seafood'},
  {'label': 'Lácteos',    'tag': 'en:dairy'},
  {'label': 'Huevos',     'tag': 'en:eggs'},
  {'label': 'Cereales',   'tag': 'en:cereals-and-potatoes'},
  {'label': 'Legumbres',  'tag': 'en:legumes'},
  {'label': 'Frutas',     'tag': 'en:fruits'},
  {'label': 'Verduras',   'tag': 'en:vegetables'},
  {'label': 'Bebidas',    'tag': 'en:beverages'},
];

const List<int> _kPageSizes = [5, 10, 20];

class BuscadorAlimentosWidget extends StatefulWidget {
  const BuscadorAlimentosWidget({super.key});

  @override
  State<BuscadorAlimentosWidget> createState() => _BuscadorAlimentosWidgetState();
}

class _BuscadorAlimentosWidgetState extends State<BuscadorAlimentosWidget> {
  final TextEditingController _controller = TextEditingController();
  final ApiNutricionService _servicio = ApiNutricionService();
  final ScrollController _chipsScroll = ScrollController();

  bool _cargando = false;
  List<ResultadoAlimento> _resultados = [];
  ErrorBusqueda? _error;

  int _categoriaIndex = 0; // 0 = Todos
  int _pageSize = 10;

  @override
  void dispose() {
    _controller.dispose();
    _chipsScroll.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final termino = _controller.text.trim();
    if (termino.isEmpty) return;

    setState(() {
      _cargando = true;
      _resultados = [];
      _error = null;
    });

    final categoriaTag = _kCategorias[_categoriaIndex]['tag'];
    final resultado = await _servicio.buscarAlimentos(
      termino,
      pageSize: _pageSize,
      categoriaTag: categoriaTag,
    );

    if (!mounted) return;
    setState(() {
      _cargando = false;
      _resultados = resultado.productos;
      _error = resultado.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cabecera
          Row(
            children: [
              const Icon(CupertinoIcons.search, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Buscador de Alimentos',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Consulta los macros de cualquier alimento (por 100g)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // campo de búsqueda
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _controller,
                  placeholder: 'Ej: pollo, arroz, huevo...',
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => _buscar(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(12),
                onPressed: _cargando ? null : _buscar,
                child: _cargando
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        'Buscar',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // filtro categoría
          const Text(
            'CATEGORÍA',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              controller: _chipsScroll,
              scrollDirection: Axis.horizontal,
              itemCount: _kCategorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final seleccionado = _categoriaIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _categoriaIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: seleccionado ? AppTheme.primaryBlue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionado ? AppTheme.primaryBlue : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      _kCategorias[i]['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                        color: seleccionado ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // filtro número de resultados
          Row(
            children: [
              const Text(
                'RESULTADOS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.8),
              ),
              const Spacer(),
              ..._kPageSizes.map((size) {
                final seleccionado = _pageSize == size;
                return GestureDetector(
                  onTap: () => setState(() => _pageSize = size),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: seleccionado ? AppTheme.secondaryOrange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: seleccionado ? AppTheme.secondaryOrange : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '$size',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                        color: seleccionado ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          // error o sin resultados
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _error == ErrorBusqueda.red ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _error == ErrorBusqueda.red ? Colors.orange.shade300 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _error == ErrorBusqueda.red
                        ? CupertinoIcons.wifi_slash
                        : CupertinoIcons.exclamationmark_circle,
                    color: _error == ErrorBusqueda.red ? Colors.orange.shade700 : Colors.red.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error == ErrorBusqueda.red
                          ? 'Error de conexión. Comprueba tu red e inténtalo de nuevo.'
                          : 'No se encontraron resultados. Prueba otro término o cambia los filtros.',
                      style: TextStyle(
                        color: _error == ErrorBusqueda.red ? Colors.orange.shade800 : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // lista de resultados
          if (_resultados.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${_resultados.length} resultado${_resultados.length != 1 ? 's' : ''} encontrado${_resultados.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ...List.generate(_resultados.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i < _resultados.length - 1 ? 10 : 0),
                child: _TarjetaAlimento(resultado: _resultados[i], indice: i + 1),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// tarjeta resultado de alimento
class _TarjetaAlimento extends StatelessWidget {
  final ResultadoAlimento resultado;
  final int indice;
  const _TarjetaAlimento({required this.resultado, required this.indice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto + nombre + marca
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resultado.imagenUrl != null && resultado.imagenUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    resultado.imagenUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderImagen(indice: indice),
                  ),
                )
              else
                _PlaceholderImagen(indice: indice),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resultado.nombre.isNotEmpty ? resultado.nombre : 'Alimento sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (resultado.marca.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        resultado.marca,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text(
            'por 100g',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          // Chips de macros
          Row(
            children: [
              _MacroChip(etiqueta: 'Kcal',     valor: resultado.calorias,      color: Colors.orange.shade400),
              const SizedBox(width: 6),
              _MacroChip(etiqueta: 'Proteína', valor: resultado.proteinas,     unidad: 'g', color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              _MacroChip(etiqueta: 'Carbos',   valor: resultado.carbohidratos, unidad: 'g', color: Colors.green.shade500),
              const SizedBox(width: 6),
              _MacroChip(etiqueta: 'Grasas',   valor: resultado.grasas,        unidad: 'g', color: Colors.red.shade400),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImagen extends StatelessWidget {
  final int indice;
  const _PlaceholderImagen({required this.indice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(CupertinoIcons.photo, color: Colors.grey, size: 24),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String etiqueta;
  final double? valor;
  final String unidad;
  final Color color;

  const _MacroChip({
    required this.etiqueta,
    required this.valor,
    this.unidad = '',
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final texto = valor != null ? '${valor!.toStringAsFixed(1)}$unidad' : '—';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(texto, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
            const SizedBox(height: 2),
            Text(etiqueta, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
