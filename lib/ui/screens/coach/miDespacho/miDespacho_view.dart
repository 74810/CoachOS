import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/coach/miDespacho/tarifas_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/database_service.dart';
import '../../../../models/cliente_model.dart';

class DespachoView extends StatelessWidget {
  const DespachoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text('Mi Despacho', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ),
        
        Expanded(
          child: StreamBuilder<List<Cliente>>(
            stream: DatabaseService().getClientes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final clientes = snapshot.data ?? [];
              
              int totalClientes = clientes.length;
              double mrrTotal = 0.0;
              
              // MAGIA: Agrupamos clientes dinámicamente por el nombre de su tarifa
              Map<String, int> conteoTarifas = {};

              for (var c in clientes) {
                mrrTotal += c.precioTarifaDouble;
                String tarifaNombre = c.tipoTarifa.isEmpty ? 'Sin Tarifa' : c.tipoTarifa;
                conteoTarifas[tarifaNombre] = (conteoTarifas[tarifaNombre] ?? 0) + 1;
              }

              double arpu = totalClientes > 0 ? (mrrTotal / totalClientes) : 0.0;

              // Paleta de colores para las diferentes tarifas
              List<Color> coloresGrafica = [
                AppTheme.secondaryOrange, 
                AppTheme.mediumBlue, 
                AppTheme.primaryBlue, 
                Colors.purple, 
                Colors.teal,
                Colors.green,
                Colors.amber
              ];

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  //DASHBOARD FINANCIERO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.mediumBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("MRR (Ingresos Mensuales)", style: TextStyle(color: AppTheme.lightBlue, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text("${mrrTotal.toStringAsFixed(2)} €", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatInfo("Activos", "$totalClientes", CupertinoIcons.group_solid),
                              _StatInfo("ARPU (Ticket Medio)", "${arpu.toStringAsFixed(0)}€", CupertinoIcons.chart_pie_fill),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("HERRAMIENTAS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Tarifa: 100% del ancho
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (context) => const TarifasView()),
                            );
                          },
                          child: _BotonHerramientaAncho(
                            icono: CupertinoIcons.tag_fill, 
                            color: AppTheme.secondaryOrange, 
                            titulo: 'Mis Tarifas', 
                            subtitulo: 'Gestionar planes y precios'
                          ),
                        ),
                        const SizedBox(height: 12),
                        // QR y Leads: 50% cada uno
                        Row(
                          children: [
                            Expanded(
                              child: _BotonHerramientaMitad(
                                icono: CupertinoIcons.qrcode, 
                                color: AppTheme.primaryBlue, 
                                titulo: 'Captar (QR)'
                              )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _BotonHerramientaMitad(
                                icono: CupertinoIcons.person_3_fill, 
                                color: AppTheme.mediumBlue, 
                                titulo: 'Interesados'
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DISTRIBUCIÓN DE PLANES
                  if (totalClientes > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("DISTRIBUCIÓN DE PLANES", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 100, width: 100,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2, centerSpaceRadius: 30,
                                sections: conteoTarifas.entries.toList().asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var mapEntry = entry.value;
                                  double pct = (mapEntry.value / totalClientes) * 100;
                                  return PieChartSectionData(
                                    color: coloresGrafica[index % coloresGrafica.length],
                                    value: pct,
                                    radius: 20,
                                    showTitle: false,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: conteoTarifas.entries.toList().asMap().entries.map((entry) {
                                int index = entry.key;
                                var mapEntry = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _Leyenda(
                                    coloresGrafica[index % coloresGrafica.length], 
                                    mapEntry.key,
                                    "${mapEntry.value} clientes"
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatInfo extends StatelessWidget {
  final String titulo, valor;
  final IconData icono;
  const _StatInfo(this.titulo, this.valor, this.icono);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icono, color: AppTheme.lightBlue, size: 16), 
          const SizedBox(width: 6), 
          Text(titulo, style: const TextStyle(color: AppTheme.lightBlue, fontSize: 12))
        ]),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }
}

class _BotonHerramientaAncho extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;

  const _BotonHerramientaAncho({required this.icono, required this.color, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

class _BotonHerramientaMitad extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;

  const _BotonHerramientaMitad({required this.icono, required this.color, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String titulo, subtitulo;
  const _Leyenda(this.color, this.titulo, this.subtitulo);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
          Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ])
      ],
    );
  }
}