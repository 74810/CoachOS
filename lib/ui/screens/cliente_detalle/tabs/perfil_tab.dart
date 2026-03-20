import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/cliente_model.dart';
import '../../../../config/theme.dart';

class PerfilTab extends StatelessWidget {
  final Cliente cliente;

  const PerfilTab({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. BLOQUE DE INFORMACIÓN MÉDICA / PERSONAL
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("DATOS DEL CLIENTE", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              _FilaDato(titulo: "Edad / Sexo", valor: "${cliente.edad} años • ${cliente.sexo}"),
              const Divider(color: AppTheme.lightBlue),
              _FilaDato(titulo: "Lesiones", valor: cliente.lesionesPrevias.isEmpty ? "Ninguna" : cliente.lesionesPrevias),
              const Divider(color: AppTheme.lightBlue),
              _FilaDato(titulo: "Patologías", valor: cliente.patologias.isEmpty ? "Ninguna" : cliente.patologias),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. GRÁFICA DE EVOLUCIÓN DE PESO
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text("EVOLUCIÓN DE PESO", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        Container(
          height: 250,
          padding: const EdgeInsets.only(top: 30, bottom: 10, left: 10, right: 20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
                      Widget text;
                      switch (value.toInt()) {
                        case 0: text = const Text('Sem 1', style: style); break;
                        case 1: text = const Text('Sem 2', style: style); break;
                        case 2: text = const Text('Sem 3', style: style); break;
                        case 3: text = const Text('Sem 4', style: style); break;
                        default: text = const Text(''); break;
                      }
                      return SideTitleWidget(meta: meta, child: text);
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  // Datos simulados de peso (ej: empezó en 82kg y bajó a 79kg)
                  spots: const [FlSpot(0, 82.5), FlSpot(1, 81.2), FlSpot(2, 80.5), FlSpot(3, 79.1)],
                  isCurved: true,
                  color: AppTheme.primaryBlue,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.15)),
                ),
              ],
              minY: 75,
              maxY: 85,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3. BLOQUE DE MEDIDAS (GRID)
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text("MEDIDAS ACTUALES", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        const Row(
          children: [
            Expanded(child: _TarjetaMedida(titulo: "Peso", valor: "79.1 kg", tendencia: "-3.4 kg", esPositivo: true)),
            SizedBox(width: 12),
            Expanded(child: _TarjetaMedida(titulo: "Cintura", valor: "84 cm", tendencia: "-2 cm", esPositivo: true)),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _TarjetaMedida(titulo: "Grasa", valor: "18 %", tendencia: "-1.5 %", esPositivo: true)),
            SizedBox(width: 12),
            Expanded(child: _TarjetaMedida(titulo: "Cadera", valor: "98 cm", tendencia: "=", esPositivo: false)),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _FilaDato extends StatelessWidget {
  final String titulo;
  final String valor;
  const _FilaDato({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
        Expanded(child: Text(valor, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }
}

class _TarjetaMedida extends StatelessWidget {
  final String titulo, valor, tendencia;
  final bool esPositivo;
  
  const _TarjetaMedida({
    required this.titulo, 
    required this.valor, 
    required this.tendencia, 
    required this.esPositivo
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: esPositivo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(4)
            ),
            child: Text(
              tendencia, 
              style: TextStyle(
                color: esPositivo ? Colors.green : Colors.grey, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )
            ),
          )
        ],
      ),
    );
  }
}