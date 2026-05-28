import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/coach/miDespacho/interesados_view.dart';
import 'package:coach_os_app/ui/screens/coach/miDespacho/tarifas_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
          padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text('Mi Despacho', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ),

        Expanded(
          child: StreamBuilder<List<Cliente>>(
            stream: DatabaseService().getClientes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final clientes = snapshot.data ?? [];

              // excluye leads, solo clientes con plan activo
              final clientesActivos = clientes.where((c) => c.estadoOnboarding != 'lead').toList();

              int totalClientes = clientesActivos.length;
              double mrrTotal = 0.0;

              Map<String, int> conteoTarifas = {};

              for (var c in clientesActivos) {
                mrrTotal += c.precioTarifaDouble;
                String tarifaNombre = c.tipoTarifa.isEmpty ? 'Sin Tarifa' : c.tipoTarifa;
                conteoTarifas[tarifaNombre] = (conteoTarifas[tarifaNombre] ?? 0) + 1;
              }

              double arpu = totalClientes > 0 ? (mrrTotal / totalClientes) : 0.0;

              List<Color> coloresGrafica = [
                AppTheme.secondaryOrange,
                AppTheme.mediumBlue,
                AppTheme.primaryBlue,
                Colors.purple,
                Colors.teal,
                Colors.green,
                Colors.amber,
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // dashboard financiero
                  Expanded(
                    flex: 30,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("MRR (Ingresos Mensuales)", style: TextStyle(color: AppTheme.lightBlue, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text("${mrrTotal.toStringAsFixed(2)} €", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _StatInfo("Activos", "$totalClientes", CupertinoIcons.group_solid),
                                _StatInfo("ARPU (Ticket Medio)", "${arpu.toStringAsFixed(0)}€", CupertinoIcons.chart_pie_fill),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("HERRAMIENTAS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 6),

                  // botón mis tarifas
                  Expanded(
                    flex: 15,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const TarifasView())),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppTheme.secondaryOrange.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(CupertinoIcons.tag_fill, color: AppTheme.secondaryOrange, size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mis Tarifas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  Text('Gestionar planes y precios', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // QR e interesados
                  Expanded(
                    flex: 15,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _mostrarModalQR(context),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.qrcode, color: AppTheme.primaryBlue, size: 28),
                                    SizedBox(height: 8),
                                    Text('Captar (QR)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const InteresadosView())),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.person_3_fill, color: AppTheme.mediumBlue, size: 28),
                                    SizedBox(height: 8),
                                    Text('Interesados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // distribución de planes (gráfica)
                  if (totalClientes > 0) ...[
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("DISTRIBUCIÓN DE PLANES", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      flex: 40,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 160,
                              width: 160,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 44,
                                  sections: conteoTarifas.entries.toList().asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var mapEntry = entry.value;
                                    double pct = (mapEntry.value / totalClientes) * 100;
                                    return PieChartSectionData(
                                      color: coloresGrafica[index % coloresGrafica.length],
                                      value: pct,
                                      radius: 36,
                                      showTitle: false,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: conteoTarifas.entries.toList().asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var mapEntry = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _Leyenda(
                                      coloresGrafica[index % coloresGrafica.length],
                                      mapEntry.key,
                                      "${mapEntry.value} clientes",
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
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

// modal QR de captación
void _mostrarModalQR(BuildContext context) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final link = 'coachos://registro?entrenador_id=$uid';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ModalQR(link: link),
  );
}

class _ModalQR extends StatefulWidget {
  final String link;
  const _ModalQR({required this.link});

  @override
  State<_ModalQR> createState() => _ModalQRState();
}

class _ModalQRState extends State<_ModalQR> {
  bool _copiado = false;

  Future<void> _copiarEnlace() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (!mounted) return;
    setState(() => _copiado = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copiado = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Comparte tu enlace',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tus clientes escanean el QR o reciben el enlace\ny se registran directamente contigo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 24),

          // QR code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: widget.link,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.primaryBlue,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // enlace copiable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.link, size: 16, color: AppTheme.mediumBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.link,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _copiado ? null : _copiarEnlace,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _copiado ? AppTheme.success : AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_copiado) const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 12),
                        if (_copiado) const SizedBox(width: 4),
                        Text(
                          _copiado ? '¡Copiado!' : 'Copiar',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // instrucciones para el coach
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.success.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle, color: AppTheme.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cuando tu cliente descargue la app y use este enlace, aparecerá automáticamente en tu sección de Interesados.',
                    style: TextStyle(color: Color(0xFF2D7A4F), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}