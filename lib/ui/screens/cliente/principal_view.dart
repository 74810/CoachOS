import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/theme.dart';
import '../../widgets/buscador_alimentos_widget.dart';
import '../../widgets/estadisticas_cliente_widget.dart';
import 'home_view.dart';

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrincipalViewState();
}

class _PrincipalViewState extends State<PrincipalView> {
  bool _tarifaExpandida = true;
  bool _revisionExpandida = true;

  void _mostrarPopupPago(BuildContext context, String uid, Map<String, dynamic> data) {
    final int precio = data['precio_tarifa'] ?? 0;
    final String tipo = data['tipo_tarifa'] ?? 'Mensual';
    final String nombreCoach = data['nombre_entrenador'] ?? 'tu entrenador';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalSimulacionPago(
        uid: uid,
        precio: precio,
        tipo: tipo,
        nombreCoach: nombreCoach,
      ),
    );
  }

  DateTime _calcularUltimaRevision(Map<String, dynamic> data, int frecuencia) {
    if (data['fecha_ultima_revision'] != null) {
      return (data['fecha_ultima_revision'] as Timestamp).toDate();
    } else if (data.containsKey('fecha_ultima_revision')) {
      return DateTime.now();
    } else {
      int diasRestar = frecuencia == 0 ? 1 : frecuencia + 1;
      return DateTime.now().subtract(Duration(days: diasRestar));
    }
  }

  // cabecera plegable de tarjeta
  Widget _buildCabeceraPlegable({
    required String titulo,
    required IconData icono,
    required Color color,
    required bool expandido,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              ),
            ),
            AnimatedRotation(
              turns: expandido ? 0 : -0.25,
              duration: const Duration(milliseconds: 220),
              child: Icon(CupertinoIcons.chevron_down, size: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Error"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;

        DateTime fechaPago = DateTime.now().subtract(const Duration(days: 31));
        if (data['fecha_ultimo_pago'] != null) {
          fechaPago = (data['fecha_ultimo_pago'] as Timestamp).toDate();
        }
        final int diasDesdePago = DateTime.now().difference(fechaPago).inDays;
        final bool tocaPagar = diasDesdePago >= 30;

        final int frecuencia = data['frecuencia_revisiones'] ?? 15;
        final bool esLibre = frecuencia == 0;
        final DateTime ultimaRev = _calcularUltimaRevision(data, frecuencia);
        final DateTime fechaObjetivo = ultimaRev.add(Duration(days: frecuencia));

        final Color colorTarifa = tocaPagar ? Colors.red : Colors.green;
        final String tituloTarifa = tocaPagar ? 'Tarifa — Pago pendiente' : 'Tarifa — Al día';
        final IconData iconoTarifa = tocaPagar
            ? CupertinoIcons.creditcard_fill
            : CupertinoIcons.checkmark_seal_fill;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // saludo personalizado
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 28),
                child: Text(
                  "¡Hola, ${data['nombre'] ?? 'Atleta'}!",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),

              // tarjeta tarifa
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: tocaPagar ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tocaPagar ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: _buildCabeceraPlegable(
                        titulo: tituloTarifa,
                        icono: iconoTarifa,
                        color: colorTarifa,
                        expandido: _tarifaExpandida,
                        onToggle: () => setState(() => _tarifaExpandida = !_tarifaExpandida),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _tarifaExpandida
                          ?                                   Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: tocaPagar
                                      ? _ContenidoTarifaImpagada(
                                          onPagar: () => _mostrarPopupPago(context, user.uid, data),
                                        )
                                      : _ContenidoTarifaPagada(diasRestantes: 30 - diasDesdePago),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // tarjeta revisión con cronómetro en vivo
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, _) {
                  final ahora = DateTime.now();
                  final tocaRevision = esLibre || ahora.isAfter(fechaObjetivo);
                  final diferencia = esLibre ? Duration.zero : fechaObjetivo.difference(ahora);

                  final Color colorRevision = tocaRevision ? Colors.purple : AppTheme.primaryBlue;
                  final String tituloRevision = tocaRevision
                      ? (esLibre ? 'Revisión — Libre' : 'Revisión — ¡Toca revisión!')
                      : 'Revisión — ${diferencia.inDays}d ${diferencia.inHours % 24}h ${diferencia.inMinutes % 60}m';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: tocaRevision ? Colors.purple.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: tocaRevision ? Colors.purple.shade200 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: _buildCabeceraPlegable(
                            titulo: tituloRevision,
                            icono: CupertinoIcons.timer,
                            color: colorRevision,
                            expandido: _revisionExpandida,
                            onToggle: () => setState(() => _revisionExpandida = !_revisionExpandida),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: _revisionExpandida
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _ContenidoRevision(
                                    tocaRevision: tocaRevision,
                                    esLibre: esLibre,
                                    diferencia: diferencia,
                                    onIrRevision: () => HomeViewCliente.of(context).cambiarTab(3),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // estadísticas de progreso
              EstadisticasClienteWidget(clienteId: user.uid),

              const SizedBox(height: 20),

              // buscador de alimentos
              const BuscadorAlimentosWidget(),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// contenido tarifa impagada
class _ContenidoTarifaImpagada extends StatelessWidget {
  final VoidCallback onPagar;
  const _ContenidoTarifaImpagada({required this.onPagar});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(CupertinoIcons.creditcard_fill, color: Colors.red, size: 36),
        const SizedBox(height: 10),
        const Text("¡Tarifa No Pagada!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 6),
        const Text(
          'Tu suscripción ha caducado. Renueva tu cuota para recuperar el acceso completo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: Colors.red,
            onPressed: onPagar,
            child: const Text("PAGAR TARIFA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _ContenidoTarifaPagada extends StatelessWidget {
  final int diasRestantes;
  const _ContenidoTarifaPagada({required this.diasRestantes});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tarifa Pagada", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                "Todo al día. Próximo pago en $diasRestantes días.",
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// modal de simulación de pago de cuota
class _ModalSimulacionPago extends StatefulWidget {
  final String uid;
  final int precio;
  final String tipo;
  final String nombreCoach;

  const _ModalSimulacionPago({
    required this.uid,
    required this.precio,
    required this.tipo,
    required this.nombreCoach,
  });

  @override
  State<_ModalSimulacionPago> createState() => _ModalSimulacionPagoState();
}

class _ModalSimulacionPagoState extends State<_ModalSimulacionPago> {
  bool _procesando = false;

  Future<void> _confirmarPago() async {
    setState(() => _procesando = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      final fechaFin = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.uid).update({
        'cuota_pagada': true,
        'fecha_ultimo_pago': FieldValue.serverTimestamp(),
        'fecha_fin_plan': fechaFin,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Pago completado! Tu suscripción está activa.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.creditcard_fill, color: AppTheme.primaryBlue, size: 34),
          ),
          const SizedBox(height: 16),

          Text(
            widget.nombreCoach,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Plan ${widget.tipo}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.precio}€',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 2),
                Text('cuota mensual', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(14),
              onPressed: _procesando ? null : _confirmarPago,
              child: _procesando
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text('Confirmar pago', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _procesando ? null : () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }
}

// contenido del bloque de revisión
class _ContenidoRevision extends StatelessWidget {
  final bool tocaRevision;
  final bool esLibre;
  final Duration diferencia;
  final VoidCallback onIrRevision;

  const _ContenidoRevision({
    required this.tocaRevision,
    required this.esLibre,
    required this.diferencia,
    required this.onIrRevision,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(CupertinoIcons.timer, color: tocaRevision ? Colors.purple : AppTheme.primaryBlue, size: 36),
        const SizedBox(height: 10),
        Text(
          tocaRevision ? (esLibre ? "REVISIÓN LIBRE" : "¡TOCA REVISIÓN!") : "PRÓXIMA REVISIÓN",
          style: TextStyle(
            color: tocaRevision ? Colors.purple : AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 14),
        if (tocaRevision)
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: onIrRevision,
              child: const Text("IR A MI REVISIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        else ...[
          const Text("Se abrirá en:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            "${diferencia.inDays}d, ${diferencia.inHours % 24}h, ${diferencia.inMinutes % 60}m, ${diferencia.inSeconds % 60}s",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: AppTheme.primaryBlue),
          ),
        ],
      ],
    );
  }
}
