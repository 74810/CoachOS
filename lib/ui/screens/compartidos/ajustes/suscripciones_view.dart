import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../../../../config/theme.dart';
import '../../../../models/tarifa_model.dart';
import '../../../../services/paypal_service.dart';

class SuscripcionesView extends StatefulWidget {
  final String rol;
  const SuscripcionesView({super.key, required this.rol});

  @override
  State<SuscripcionesView> createState() => _SuscripcionesViewState();
}

class _SuscripcionesViewState extends State<SuscripcionesView> {
  String? _planProcesando;
  Timer? _pollingTimer;
  String? _ordenPolling;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _configurarDeepLink();
  }

  void _configurarDeepLink() {
    _linkSub = AppLinks().uriLinkStream.listen((uri) {
      if (uri.scheme == 'coachos' && uri.host == 'paypal-success') {
        _manejarRetornoPaypal();
      }
    });
  }

  // deep link coachos://paypal-success devuelve el control aquí
  Future<void> _manejarRetornoPaypal() async {
    if (_ordenPolling == null || _planProcesando == null) return;

    _pollingTimer?.cancel();
    final orderId = _ordenPolling!;
    final planId = _planProcesando!;
    final plan = _planesCoach.firstWhere(
      (p) => p['id'] == planId,
      orElse: () => {},
    );
    if (plan.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    setState(() => _planProcesando = planId);

    final capturado = await PaypalService().capturarOrden(orderId);
    if (!mounted) return;

    _ordenPolling = null;

    if (capturado) {
      final bool esCambioPeriodo = plan.containsKey('_esCambioPeriodo') && plan['_esCambioPeriodo'] == true;
      await _guardarPlanEnFirestore(user.uid, planId, false, esCambioPeriodo: esCambioPeriodo);
      setState(() => _planProcesando = null);
      if (mounted) _mostrarDialogoExito(plan);
    } else {
      setState(() => _planProcesando = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo confirmar el pago. El polling continúa..."),
          backgroundColor: Colors.orange,
        ),
      );
      // polling como fallback si el deep link llega tarde
      _iniciarPolling(orderId, planId, plan, user.uid);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  final List<Map<String, dynamic>> _planesCoach = [
    {
      'id': 'cantera',
      'nombre': 'Cantera',
      'precio': '0€',
      'importe': '0.00',
      'limite': '3 clientes',
      'color': Colors.grey,
      'gratis': true,
    },
    {
      'id': 'rookie',
      'nombre': 'Rookie',
      'precio': '19.99€/mes',
      'importe': '19.99',
      'limite': '15 clientes',
      'color': Colors.blue,
      'gratis': false,
    },
    {
      'id': 'all-star',
      'nombre': 'All-Star',
      'precio': '39.99€/mes',
      'importe': '39.99',
      'limite': '30 clientes',
      'color': AppTheme.secondaryOrange,
      'gratis': false,
    },
    {
      'id': 'hall of fame',
      'nombre': 'Hall of Fame',
      'precio': '79.99€/mes',
      'importe': '79.99',
      'limite': 'Ilimitado',
      'color': Colors.purple,
      'gratis': false,
    },
  ];

  // esCambioPeriodo mantiene las fechas del período actual (upgrade/downgrade)
  Future<void> _guardarPlanEnFirestore(
    String uid,
    String planId,
    bool esGratis, {
    bool esCambioPeriodo = false,
  }) async {
    final Map<String, dynamic> datos = {
      'plan_suscripcion': planId,
      'subscripcion_activa': true,
    };

    if (!esCambioPeriodo) {
      final ahora = DateTime.now();
      datos['fecha_inicio_plan'] = FieldValue.serverTimestamp();
      datos['fecha_fin_plan'] = esGratis ? null : Timestamp.fromDate(ahora.add(const Duration(days: 30)));
    }
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(datos);
  }

  // activación directa del plan gratuito
  Future<void> _activarPlanGratis(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _planProcesando = planId);
    try {
      await _guardarPlanEnFirestore(user.uid, planId, true, esCambioPeriodo: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Plan ${planId.toUpperCase()} activado"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _planProcesando = null);
    }
  }

  // abre Safari con la orden PayPal y detecta el retorno automáticamente
  Future<void> _iniciarPagoPaypal(
    Map<String, dynamic> plan, {
    String? importeOverride,
    bool esCambioPeriodo = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final planId = plan['id'] as String;

    final planConFlag = {...plan, '_esCambioPeriodo': esCambioPeriodo};

    setState(() => _planProcesando = planId);

    final importe = importeOverride ?? plan['importe'] as String;

    // crear la orden en PayPal
    final orden = await PaypalService().crearOrden(
      importe: importe,
      descripcion: 'CoachOS — Plan ${plan['nombre']}',
    );

    if (!mounted) return;

    if (orden == null) {
      setState(() => _planProcesando = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo conectar con PayPal. Comprueba las credenciales sandbox."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // abrir Safari con la URL de aprobación de PayPal
    final uri = Uri.parse(orden.approvalUrl);
    bool abierto = false;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        abierto = await launchUrl(uri);
      } catch (_) {}
    }

    if (!mounted) return;

    if (!abierto) {
      setState(() => _planProcesando = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir Safari."), backgroundColor: Colors.red),
      );
      return;
    }

    // snackbar persistente mientras el usuario paga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            CupertinoActivityIndicator(),
            SizedBox(width: 12),
            Text('Esperando confirmación de PayPal...'),
          ],
        ),
        duration: const Duration(minutes: 10),
        backgroundColor: Colors.blue.shade700,
      ),
    );

    // polling automático como fallback al deep link
    _iniciarPolling(orden.orderId, planId, planConFlag, user.uid);
  }

  // polling cada 3 s hasta que la orden esté APPROVED
  void _iniciarPolling(String orderId, String planId, Map<String, dynamic> plan, String uid) {
    _pollingTimer?.cancel();
    _ordenPolling = orderId;
    int intentos = 0;
    const maxIntentos = 200;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || intentos >= maxIntentos) {
        timer.cancel();
        _ordenPolling = null;
        if (mounted) {
          setState(() => _planProcesando = null);
          ScaffoldMessenger.of(context).clearSnackBars();
          if (intentos >= maxIntentos) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Tiempo de espera agotado. Si pagaste, contacta con soporte."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        return;
      }
      intentos++;

      final estado = await PaypalService().consultarEstadoOrden(orderId);
      if (!mounted) { timer.cancel(); return; }

      if (estado == 'APPROVED' || estado == 'COMPLETED') {
        timer.cancel();
        _ordenPolling = null;
        ScaffoldMessenger.of(context).clearSnackBars();

        final capturado = await PaypalService().capturarOrden(orderId);
        if (!mounted) return;
        setState(() => _planProcesando = null);

        if (capturado) {
          final bool esCambioPeriodo = plan.containsKey('_esCambioPeriodo') && plan['_esCambioPeriodo'] == true;
          await _guardarPlanEnFirestore(uid, planId, false, esCambioPeriodo: esCambioPeriodo);
          if (mounted) _mostrarDialogoExito(plan);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Pago recibido pero no se pudo capturar. Contacta con soporte."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  // modal selección de plan
  void _mostrarModalPlan(
    Map<String, dynamic> plan,
    String planActual,
    Map<String, dynamic> planActualInfo,
    int diasRestantes,
  ) {
    final bool esElActual = planActual == plan['id'];
    final bool esGratis = plan['gratis'] as bool;
    final bool planActualEsGratis = planActualInfo['gratis'] as bool;
    final Color color = plan['color'] as Color;
    final bool hayPolling = _ordenPolling != null;

    // cálculo de prorrateo para cambios en período activo
    double? diferenciaProrrata;
    bool esCambioPeriodo = false;

    if (!esElActual && !esGratis && !planActualEsGratis && diasRestantes > 0 && diasRestantes <= 30) {
      final double precioActual = double.tryParse(planActualInfo['importe'] as String) ?? 0.0;
      final double precioNuevo = double.tryParse(plan['importe'] as String) ?? 0.0;
      final double porcentaje = diasRestantes / 30.0;
      diferenciaProrrata = double.parse(((precioNuevo - precioActual) * porcentaje).toStringAsFixed(2));
      esCambioPeriodo = true;
    }

    // texto e importe del botón principal
    final String importeAPayar = diferenciaProrrata != null && diferenciaProrrata > 0
        ? diferenciaProrrata.toStringAsFixed(2)
        : (plan['importe'] as String);

    final String textoBoton = esGratis
        ? 'Activar gratis'
        : diferenciaProrrata == null
            ? 'Pagar con PayPal'
            : diferenciaProrrata <= 0
                ? 'Cambiar plan (sin coste adicional)'
                : 'Pagar ${diferenciaProrrata.toStringAsFixed(2)}€ con PayPal';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            // Cabecera del plan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan['nombre'],
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                        const SizedBox(height: 2),
                        Text(plan['precio'],
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(plan['limite'],
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),

            // Info de prorrateo si aplica
            if (esCambioPeriodo) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: diferenciaProrrata! > 0 ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: diferenciaProrrata > 0 ? Colors.blue.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      diferenciaProrrata > 0
                          ? CupertinoIcons.info_circle_fill
                          : CupertinoIcons.checkmark_circle_fill,
                      size: 16,
                      color: diferenciaProrrata > 0 ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diferenciaProrrata > 0
                            ? 'Tienes $diasRestantes días restantes. Solo pagas la diferencia prorrata: ${diferenciaProrrata.toStringAsFixed(2)}€'
                            : 'Cambio sin coste: tu nuevo plan entra en vigor y mantiene tu fecha de vencimiento actual.',
                        style: TextStyle(
                          fontSize: 12,
                          color: diferenciaProrrata > 0 ? Colors.blue.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Botón de acción
            if (esElActual) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text('Este es tu plan actual',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
            ] else if (hayPolling) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 10),
                    Text('Pago en curso...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (esGratis) {
                      _activarPlanGratis(plan['id'] as String);
                    } else if (diferenciaProrrata != null && diferenciaProrrata <= 0) {
                      // Downgrade sin coste: solo actualizar plan manteniendo fechas
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        _guardarPlanEnFirestore(user.uid, plan['id'] as String, false, esCambioPeriodo: true);
                      }
                    } else {
                      _iniciarPagoPaypal(
                        plan,
                        importeOverride: diferenciaProrrata != null ? importeAPayar : null,
                        esCambioPeriodo: esCambioPeriodo,
                      );
                    }
                  },
                  child: Text(
                    textoBoton,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoExito(Map<String, dynamic> plan) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("¡Pago completado!"),
        content: Text(
          "El plan ${plan['nombre']} está ahora activo.\n\n"
          "Importe cobrado: ${plan['precio']}",
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Perfecto"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esEntrenador = widget.rol == 'entrenador';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: Text(esEntrenador ? "Planes de Suscripción" : "Mi Tarifa"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final planActual = data['plan_suscripcion'] ?? 'cantera';

          if (!esEntrenador) return _VistaClienteTarifa(clienteData: data);

          final planInfo = _planesCoach.firstWhere(
            (p) => p['id'] == planActual,
            orElse: () => _planesCoach.first,
          );
          final bool esGratisActual = planInfo['gratis'] as bool;

          DateTime? fechaInicio;
          final fi = data['fecha_inicio_plan'];
          if (fi is Timestamp) fechaInicio = fi.toDate();

          DateTime? fechaVencimiento;
          final ff = data['fecha_fin_plan'];
          if (ff is Timestamp) fechaVencimiento = ff.toDate();

          final int diasRestantes = fechaVencimiento != null
              ? fechaVencimiento.difference(DateTime.now()).inDays
              : 999;

          final List<Widget> items = [];
          for (int i = 0; i < _planesCoach.length; i++) {
            final plan = _planesCoach[i];
            final bool esElActual = planActual == plan['id'];
            final bool estaProcesando = _planProcesando == plan['id'];
            final Color color = plan['color'] as Color;

            items.add(Expanded(
              child: GestureDetector(
                onTap: () => _mostrarModalPlan(plan, planActual, planInfo, diasRestantes),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: esElActual
                        ? Border.all(color: color, width: 2)
                        : Border.all(color: Colors.transparent, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // cabecera tarjeta plan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plan['nombre'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                            ),
                            if (esElActual)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                                child: const Text("ACTUAL", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              )
                            else
                              Icon(CupertinoIcons.chevron_right, size: 14, color: color.withOpacity(0.5)),
                          ],
                        ),
                      ),
                      // cuerpo tarjeta plan
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan['precio'],
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(plan['limite'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                  if (estaProcesando)
                                    CupertinoActivityIndicator(color: color),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ));

            if (i < _planesCoach.length - 1) items.add(const SizedBox(height: 8));
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                // estado de suscripción del coach
                _EstadoSuscripcion(
                  planInfo: planInfo,
                  fechaInicio: fechaInicio,
                  fechaVencimiento: fechaVencimiento,
                  diasRestantes: diasRestantes,
                  esGratis: esGratisActual,
                  planProcesando: _planProcesando,
                  onRenovar: () => _iniciarPagoPaypal(planInfo, esCambioPeriodo: false),
                ),
                const SizedBox(height: 12),
                // lista de planes
                Expanded(child: Column(children: items)),
              ],
            ),
          );
        },
      ),
    );
  }

}

// vista de tarifa para el cliente
class _VistaClienteTarifa extends StatefulWidget {
  final Map<String, dynamic> clienteData;
  const _VistaClienteTarifa({required this.clienteData});

  @override
  State<_VistaClienteTarifa> createState() => _VistaClienteTarifaState();
}

class _VistaClienteTarifaState extends State<_VistaClienteTarifa> {
  bool _pagando = false;

  // pago simulado con latencia realista
  Future<void> _procesarPago(Future<void> Function() onExito) async {
    setState(() => _pagando = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    try {
      await onExito();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }

  // registra el pago de la cuota mensual en Firestore
  Future<void> _registrarCuotaMensual(String uid) async {
    final fechaFin = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'cuota_pagada': true,
      'fecha_ultimo_pago': FieldValue.serverTimestamp(),
      'fecha_fin_plan': fechaFin,
      'tipo_tarifa': widget.clienteData['plan_pendiente_nombre'] ?? widget.clienteData['tipo_tarifa'],
      'precio_tarifa': widget.clienteData['plan_pendiente_precio'] ?? widget.clienteData['precio_tarifa'],
      'dias_gracia': widget.clienteData['plan_pendiente_gracia'] ?? widget.clienteData['dias_gracia'],
      'plan_pendiente_nombre': FieldValue.delete(),
      'plan_pendiente_precio': FieldValue.delete(),
      'plan_pendiente_gracia': FieldValue.delete(),
    });
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¡Pago completado!'),
        content: const Text('Tu suscripción está activa durante los próximos 30 días.'),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('Perfecto'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  // upgrade paga diferencia prorratada, downgrade espera al fin del ciclo
  Future<void> _solicitarCambioPlan(String uid, Tarifa nuevaTarifa, int precioActual, DateTime? fechaFinPlan) async {
    final bool esUpgrade = nuevaTarifa.precio > precioActual;
    final bool esDowngrade = nuevaTarifa.precio < precioActual;

    if (esDowngrade) {
      final fechaFinStr = fechaFinPlan != null
          ? '${fechaFinPlan.day}/${fechaFinPlan.month}/${fechaFinPlan.year}'
          : 'tu próxima renovación';
      final confirmar = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Cambio de plan'),
          content: Text(
            'Pasarás al plan "${nuevaTarifa.nombre}" (${nuevaTarifa.precio}€/mes).\n\n'
            'El cambio se aplicará el $fechaFinStr, al final de tu ciclo actual.',
          ),
          actions: [
            CupertinoDialogAction(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
            CupertinoDialogAction(isDefaultAction: true, child: const Text('Programar cambio'), onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );
      if (confirmar != true) return;
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'plan_pendiente_nombre': nuevaTarifa.nombre,
        'plan_pendiente_precio': nuevaTarifa.precio,
        'plan_pendiente_gracia': nuevaTarifa.diasGracia,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cambio a "${nuevaTarifa.nombre}" programado'), backgroundColor: AppTheme.success),
      );
      return;
    }

    if (esUpgrade) {
      final int diasRestantes = fechaFinPlan != null
          ? fechaFinPlan.difference(DateTime.now()).inDays.clamp(0, 30)
          : 0;
      final double diferencia = (nuevaTarifa.precio - precioActual) * (diasRestantes / 30.0);
      final bool sinCoste = diferencia <= 0;
      final String importeDif = diferencia.toStringAsFixed(2);

      final confirmar = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Subir de plan'),
          content: Text(sinCoste
              ? 'Pasarás al plan "${nuevaTarifa.nombre}" (${nuevaTarifa.precio}€/mes) sin coste adicional.'
              : 'Pasarás al plan "${nuevaTarifa.nombre}" (${nuevaTarifa.precio}€/mes).\n\nSe cobrarán ${importeDif}€ correspondientes a los $diasRestantes días restantes del ciclo.'),
          actions: [
            CupertinoDialogAction(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(sinCoste ? 'Confirmar' : 'Pagar ${importeDif}€'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (confirmar != true) return;

      await _procesarPago(() async {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
          'tipo_tarifa': nuevaTarifa.nombre,
          'precio_tarifa': nuevaTarifa.precio,
          'dias_gracia': nuevaTarifa.diasGracia,
        });
        if (!mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('¡Plan actualizado!'),
            content: Text('Ahora estás suscrito al plan "${nuevaTarifa.nombre}".'),
            actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('Perfecto'), onPressed: () => Navigator.pop(context))],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final data = widget.clienteData;
    final entrenadorId = (data['entrenador_id'] as String?) ?? '';
    final tarifaActual = (data['tipo_tarifa'] as String?) ?? 'Sin tarifa';
    final precioActual = (data['precio_tarifa'] ?? 0) as int;
    final diasGracia = (data['dias_gracia'] ?? 3) as int;
    final planPendienteNombre = data['plan_pendiente_nombre'] as String?;
    final planPendientePrecio = data['plan_pendiente_precio'] as int?;

    DateTime? fechaUltimoPago;
    final fpData = data['fecha_ultimo_pago'];
    if (fpData is Timestamp) fechaUltimoPago = fpData.toDate();

    DateTime? fechaFinPlan;
    final ffData = data['fecha_fin_plan'];
    if (ffData is Timestamp) fechaFinPlan = ffData.toDate();
    // Si no hay fecha_fin_plan explícita, calcularla a partir del último pago
    fechaFinPlan ??= fechaUltimoPago?.add(const Duration(days: 30));

    final int diasDesdePago = fechaUltimoPago != null
        ? DateTime.now().difference(fechaUltimoPago).inDays
        : 999;
    final bool alDia = diasDesdePago < 30;
    final bool enGracia = !alDia && diasDesdePago <= 30 + diasGracia;
    final int diasParaVencer = alDia ? (30 - diasDesdePago) : (30 + diasGracia - diasDesdePago);

    final Color colorEstado = alDia ? AppTheme.success : enGracia ? AppTheme.warning : AppTheme.danger;
    final String textoEstado = alDia
        ? 'Al día · vence en $diasParaVencer días'
        : enGracia
            ? 'Periodo de gracia · ${diasParaVencer > 0 ? "$diasParaVencer días restantes" : "vence hoy"}'
            : 'Cuota vencida';

    return StreamBuilder<DocumentSnapshot>(
      stream: entrenadorId.isNotEmpty
          ? FirebaseFirestore.instance.collection('usuarios').doc(entrenadorId).snapshots()
          : const Stream.empty(),
      builder: (ctx, coachSnap) {
        final coachData = (coachSnap.hasData && coachSnap.data!.exists)
            ? coachSnap.data!.data() as Map<String, dynamic>? ?? {}
            : <String, dynamic>{};
        final coachNombre = (coachData['nombre'] as String?) ?? 'tu entrenador';

        return StreamBuilder<QuerySnapshot>(
          stream: entrenadorId.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('tarifas')
                  .where('coachId', isEqualTo: entrenadorId)
                  .where('esVisible', isEqualTo: true)
                  .snapshots()
              : const Stream.empty(),
          builder: (ctx2, tarifasSnap) {
            final tarifas = tarifasSnap.hasData
                ? tarifasSnap.data!.docs
                    .map((d) => Tarifa.fromFirestore(d.data() as Map<String, dynamic>, d.id))
                    .toList()
                : <Tarifa>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // card estado actual
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorEstado.withOpacity(0.4), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Plan actual', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(tarifaActual, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$precioActual€/mes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorEstado.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(textoEstado, style: TextStyle(fontSize: 11, color: colorEstado, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (fechaUltimoPago != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'Último pago: ${fechaUltimoPago.day}/${fechaUltimoPago.month}/${fechaUltimoPago.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // sección de pago de cuota
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🅿', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text('Pago a $coachNombre', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_pagando) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              CupertinoActivityIndicator(),
                              SizedBox(width: 12),
                              Expanded(child: Text('Procesando pago...', style: TextStyle(fontSize: 13, color: Colors.blue))),
                            ],
                          ),
                        ),
                      ] else ...() {
                        final bool planVigente = fechaFinPlan != null && fechaFinPlan.isAfter(DateTime.now());
                        final int diasParaRenovar = planVigente
                            ? fechaFinPlan.difference(DateTime.now()).inDays + 1
                            : 0;

                        return [
                          Text(
                            planVigente
                                ? 'Tu suscripción está activa. Podrás renovar en $diasParaRenovar días.'
                                : alDia
                                    ? 'Renueva tu suscripción con $coachNombre.'
                                    : 'Paga $precioActual€ para mantener tu acceso.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              color: planVigente ? Colors.grey.shade400 : AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(14),
                              onPressed: planVigente
                                  ? null
                                  : () => _procesarPago(() => _registrarCuotaMensual(user.uid)),
                              child: Text(
                                planVigente
                                    ? 'Disponible en $diasParaRenovar días'
                                    : 'Pagar $precioActual€',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ];
                      }(),
                    ],
                  ),
                ),

                // banner plan pendiente de cambio
                if (planPendienteNombre != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.clock_fill, color: AppTheme.warning, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cambio programado a "$planPendienteNombre" (${planPendientePrecio ?? '?'}€/mes). '
                            'Se aplicará en tu próxima renovación.',
                            style: const TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // planes disponibles del coach
                if (tarifas.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'PLANES DISPONIBLES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8),
                    ),
                  ),
                  ...tarifas.map((t) {
                    final bool esActual = t.nombre.toLowerCase() == tarifaActual.toLowerCase();
                    final bool esPendiente = t.nombre == planPendienteNombre;
                    return GestureDetector(
                      onTap: (esActual || _pagando) ? null : () => _solicitarCambioPlan(user.uid, t, precioActual, fechaFinPlan),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: esActual ? AppTheme.primaryBlue : esPendiente ? AppTheme.warning : Colors.transparent,
                            width: (esActual || esPendiente) ? 2 : 0,
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                                      if (esActual) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(8)),
                                          child: const Text('ACTUAL', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ] else if (esPendiente) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.warning, borderRadius: BorderRadius.circular(8)),
                                          child: const Text('PENDIENTE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (t.descripcion.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(t.descripcion, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${t.precio}€/mes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (!esActual && !esPendiente)
                                  Text(
                                    t.precio > precioActual ? 'Subir plan' : 'Cambiar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: t.precio > precioActual ? AppTheme.secondaryOrange : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

// widget estado de suscripción del coach
class _EstadoSuscripcion extends StatelessWidget {
  final Map<String, dynamic> planInfo;
  final DateTime? fechaInicio;
  final DateTime? fechaVencimiento;
  final int diasRestantes;
  final bool esGratis;
  final String? planProcesando;
  final VoidCallback onRenovar;

  const _EstadoSuscripcion({
    required this.planInfo,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.diasRestantes,
    required this.esGratis,
    required this.planProcesando,
    required this.onRenovar,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = planInfo['color'] as Color;
    final String nombrePlan = planInfo['nombre'] as String;
    final String precio = planInfo['precio'] as String;
    final fmt = DateFormat('dd/MM/yyyy');

    // Semáforo de estado
    final bool vencido = !esGratis && diasRestantes < 0;
    final bool aviso = !esGratis && diasRestantes >= 0 && diasRestantes <= 5;
    final Color colorEstado = vencido
        ? Colors.red
        : aviso
            ? Colors.orange
            : Colors.green;
    final String textoEstado = vencido
        ? 'Vencida'
        : aviso
            ? 'Vence pronto'
            : 'Activa';
    final IconData iconoEstado = vencido
        ? CupertinoIcons.xmark_circle_fill
        : aviso
            ? CupertinoIcons.exclamationmark_circle_fill
            : CupertinoIcons.checkmark_seal_fill;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorEstado.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila: plan + badge estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nombrePlan,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Icon(iconoEstado, color: colorEstado, size: 16),
              const SizedBox(width: 4),
              Text(textoEstado, style: TextStyle(fontSize: 12, color: colorEstado, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(precio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),

          const SizedBox(height: 12),

          if (esGratis) ...[
            const Text('Plan gratuito — sin fecha de vencimiento.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ] else ...[
            // Fechas
            Row(
              children: [
                _FechaChip(
                  icono: CupertinoIcons.calendar,
                  etiqueta: 'Inicio',
                  valor: fechaInicio != null ? fmt.format(fechaInicio!) : '—',
                ),
                const SizedBox(width: 10),
                _FechaChip(
                  icono: CupertinoIcons.calendar_badge_minus,
                  etiqueta: 'Vencimiento',
                  valor: fechaVencimiento != null ? fmt.format(fechaVencimiento!) : '—',
                  colorValor: colorEstado,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Barra de progreso del período
            if (fechaInicio != null && fechaVencimiento != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (1 - (diasRestantes / 30)).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                vencido
                    ? 'Suscripción vencida hace ${diasRestantes.abs()} días'
                    : 'Quedan $diasRestantes día${diasRestantes != 1 ? 's' : ''} para la renovación',
                style: TextStyle(fontSize: 11, color: colorEstado, fontWeight: FontWeight.w600),
              ),
            ],

            // Botón renovar si vencido o aviso
            if (vencido || aviso) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: colorEstado,
                  onPressed: planProcesando != null ? null : onRenovar,
                  child: planProcesando != null
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🅿 ', style: TextStyle(fontSize: 12)),
                            Text(
                              vencido ? 'Renovar con PayPal' : 'Renovar ahora con PayPal',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FechaChip extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? colorValor;
  const _FechaChip({required this.icono, required this.etiqueta, required this.valor, this.colorValor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icono, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorValor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

