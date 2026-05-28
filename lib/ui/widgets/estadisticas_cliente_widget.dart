import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/revision_model.dart';

// widget compartido entre coach y cliente para mostrar estadísticas y gráficas
class EstadisticasClienteWidget extends StatelessWidget {
  final String clienteId;

  const EstadisticasClienteWidget({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(clienteId).snapshots(),
      builder: (context, snapCliente) {
        final data = snapCliente.data?.data() as Map<String, dynamic>? ?? {};
        final List<String> parametros = List<String>.from(data['parametros_revision'] ?? []);
        final String nombrePlantilla = data['nombre_plantilla_activa'] ?? '';

        if (parametros.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(clienteId)
              .collection('revisiones')
              .orderBy('fecha', descending: false)
              .snapshots(),
          builder: (context, snapRevisiones) {
            final List<Revision> revisiones = snapRevisiones.data?.docs
                    .map((doc) => Revision.fromFirestore(doc))
                    .toList() ??
                [];

            if (revisiones.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // cabecera sección
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.chart_bar_alt_fill, color: AppTheme.primaryBlue, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'MI PROGRESO',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      if (nombrePlantilla.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· $nombrePlantilla',
                          style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),

                // tarjetas valores actuales
                _buildTarjetasValoresActuales(revisiones, parametros),
                const SizedBox(height: 24),

                // gráficas por parámetro
                ..._buildGraficasPorParametro(revisiones, parametros),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTarjetasValoresActuales(List<Revision> revisiones, List<String> parametros) {
    final Revision ultima = revisiones.last;
    final Revision? penultima = revisiones.length >= 2 ? revisiones[revisiones.length - 2] : null;

    final List<Widget> tarjetas = [];
    final List<Widget> fila = [];

    for (final param in parametros) {
      final valorActual = ultima.valoresParametros[param];
      if (valorActual == null) continue;

      final double? numActual = double.tryParse(valorActual.toString());
      String tendencia = '—';
      bool? esMejora;

      if (numActual != null && penultima != null) {
        final valorAnterior = penultima.valoresParametros[param];
        final double? numAnterior = double.tryParse(valorAnterior?.toString() ?? '');
        if (numAnterior != null) {
          final diff = numActual - numAnterior;
          tendencia = diff == 0 ? '=' : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}';
          esMejora = diff < 0;
        }
      }

      fila.add(Expanded(
        child: _TarjetaMedida(
          titulo: param,
          valor: numActual != null ? numActual.toStringAsFixed(1) : valorActual.toString(),
          tendencia: tendencia,
          esMejora: esMejora,
        ),
      ));

      if (fila.length == 2) {
        tarjetas.add(Row(children: [fila[0], const SizedBox(width: 10), fila[1]]));
        tarjetas.add(const SizedBox(height: 12));
        fila.clear();
      } else if (fila.length == 1 &&
          param == parametros.lastWhere((p) => ultima.valoresParametros[p] != null, orElse: () => '')) {
        tarjetas.add(Row(children: [...fila, const SizedBox(width: 10), const Expanded(child: SizedBox())]));
        tarjetas.add(const SizedBox(height: 12));
        fila.clear();
      }
    }

    if (fila.isNotEmpty) {
      if (fila.length == 1) fila.addAll([const SizedBox(width: 10), const Expanded(child: SizedBox())]);
      tarjetas.add(Row(children: List.from(fila)));
    }

    if (tarjetas.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: tarjetas);
  }

  List<Widget> _buildGraficasPorParametro(List<Revision> revisiones, List<String> parametros) {
    final List<Widget> graficas = [];

    for (final param in parametros) {
      final List<(int, double, DateTime)> puntos = [];
      for (int i = 0; i < revisiones.length; i++) {
        final valorRaw = revisiones[i].valoresParametros[param];
        final double? num = double.tryParse(valorRaw?.toString() ?? '');
        if (num != null) puntos.add((i, num, revisiones[i].fecha));
      }
      if (puntos.length < 2) continue;

      final List<FlSpot> spots = puntos.map((p) => FlSpot(p.$1.toDouble(), p.$2)).toList();
      final double minVal = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      final double maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      final double margen = (maxVal - minVal) == 0 ? 2 : (maxVal - minVal) * 0.15;

      graficas.add(Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          'EVOLUCIÓN · $param'.toUpperCase(),
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ));

      graficas.add(Container(
        height: 220,
        padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: LineChart(LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 9)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: (puntos.length <= 6) ? 1 : (puntos.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= puntos.length) return const SizedBox.shrink();
                  final fecha = puntos[idx].$3;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${fecha.day}/${fecha.month}',
                        style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primaryBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppTheme.primaryBlue,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue.withOpacity(0.18), AppTheme.primaryBlue.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: minVal - margen,
          maxY: maxVal + margen,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primaryBlue,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final fecha = puntos[spot.spotIndex].$3;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}\n${fecha.day}/${fecha.month}/${fecha.year}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList(),
            ),
          ),
        )),
      ));

      graficas.add(const SizedBox(height: 28));
    }

    return graficas;
  }
}

// tarjeta de medida individual
class _TarjetaMedida extends StatelessWidget {
  final String titulo;
  final String valor;
  final String tendencia;
  final bool? esMejora;

  const _TarjetaMedida({required this.titulo, required this.valor, required this.tendencia, this.esMejora});

  @override
  Widget build(BuildContext context) {
    final Color chipColor;
    final Color chipBg;
    if (esMejora == null || tendencia == '=' || tendencia == '—') {
      chipColor = Colors.grey; chipBg = Colors.grey.withOpacity(0.1);
    } else if (esMejora!) {
      chipColor = Colors.green; chipBg = Colors.green.withOpacity(0.1);
    } else {
      chipColor = Colors.red; chipBg = Colors.red.withOpacity(0.08);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
          const SizedBox(height: 6),
          Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
            child: Text(tendencia, style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
