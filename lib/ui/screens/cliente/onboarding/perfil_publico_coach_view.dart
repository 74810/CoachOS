import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/models/tarifa_model.dart';
import 'package:coach_os_app/services/database_service.dart';
import 'package:coach_os_app/ui/screens/compartidos/chats/chat_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PerfilPublicoCoachView extends StatefulWidget {
  final String coachId;
  final bool mostrarBackButton;

  const PerfilPublicoCoachView({
    super.key,
    required this.coachId,
    this.mostrarBackButton = true,
  });

  @override
  State<PerfilPublicoCoachView> createState() => _PerfilPublicoCoachViewState();
}

class _PerfilPublicoCoachViewState extends State<PerfilPublicoCoachView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _datosCoach;
  bool _cargandoCoach = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarCoach();
  }

  Future<void> _cargarCoach() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.coachId)
        .get();
    if (!mounted) return;
    setState(() {
      _datosCoach = doc.data();
      _cargandoCoach = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoCoach) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final nombre = _datosCoach?['nombre'] ?? 'Entrenador';
    final descripcion = _datosCoach?['descripcion'] ?? '';
    final horarioInicio = _datosCoach?['horarioInicio'] ?? '';
    final horarioFin = _datosCoach?['horarioFin'] ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Column(
      children: [
        // Header del coach
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              if (widget.mostrarBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),

              const SizedBox(height: 8),

              Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: Text(
                      inicial,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        if (descripcion.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                        if (horarioInicio.isNotEmpty && horarioFin.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.clock, size: 12, color: AppTheme.mediumBlue),
                              const SizedBox(width: 4),
                              Text(
                                '$horarioInicio - $horarioFin',
                                style: const TextStyle(color: AppTheme.mediumBlue, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryBlue,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Chat'),
                  Tab(text: 'Tarifas'),
                ],
              ),
            ],
          ),
        ),

        // Contenido de los tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab Chat
              ChatView(
                receptorId: widget.coachId,
                nombreReceptor: nombre,
                esPantallaCompleta: false,
              ),

              // Tab Tarifas
              _TabTarifas(coachId: widget.coachId, nombreCoach: nombre),
            ],
          ),
        ),
      ],
    );
  }
}

// tab tarifas
class _TabTarifas extends StatelessWidget {
  final String coachId;
  final String nombreCoach;

  const _TabTarifas({required this.coachId, required this.nombreCoach});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tarifa>>(
      stream: DatabaseService().getTarifasVisiblesDeCoach(coachId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final tarifas = snapshot.data ?? [];

        if (tarifas.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.tag, size: 50, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Sin tarifas publicadas aún',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tarifas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tarifa = tarifas[index];
            return _TarjetaTarifa(
              tarifa: tarifa,
              coachId: coachId,
              nombreCoach: nombreCoach,
            );
          },
        );
      },
    );
  }
}

// tarjeta tarifa
class _TarjetaTarifa extends StatelessWidget {
  final Tarifa tarifa;
  final String coachId;
  final String nombreCoach;

  const _TarjetaTarifa({
    required this.tarifa,
    required this.coachId,
    required this.nombreCoach,
  });

  void _mostrarModalContratacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalContratacion(
        tarifa: tarifa,
        coachId: coachId,
        nombreCoach: nombreCoach,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tarifa.nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tarifa.precio}€/mes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (tarifa.descripcion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              tarifa.descripcion,
              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
          ],
          if (tarifa.diasGracia > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.gift, size: 14, color: AppTheme.secondaryOrange),
                const SizedBox(width: 6),
                Text(
                  '${tarifa.diasGracia} días de periodo de gracia',
                  style: const TextStyle(color: AppTheme.secondaryOrange, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppTheme.secondaryOrange,
              borderRadius: BorderRadius.circular(14),
              onPressed: () => _mostrarModalContratacion(context),
              child: const Text(
                'Contratar este plan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// modal de contratación de tarifa
class _ModalContratacion extends StatefulWidget {
  final Tarifa tarifa;
  final String coachId;
  final String nombreCoach;

  const _ModalContratacion({
    required this.tarifa,
    required this.coachId,
    required this.nombreCoach,
  });

  @override
  State<_ModalContratacion> createState() => _ModalContratacionState();
}

class _ModalContratacionState extends State<_ModalContratacion> {
  bool _procesando = false;

  Future<void> _confirmar() async {
    setState(() => _procesando = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await DatabaseService().activarClienteConTarifa(
        clienteId: uid,
        coachId: widget.coachId,
        nombreTarifa: widget.tarifa.nombre,
        precioTarifa: widget.tarifa.precio,
        diasGracia: widget.tarifa.diasGracia,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido! Tu plan ha sido activado.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al activar el plan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pill
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Icon(CupertinoIcons.checkmark_seal_fill, color: AppTheme.primaryBlue, size: 50),
          const SizedBox(height: 14),

          Text(
            'Contratar "${widget.tarifa.nombre}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Con ${widget.nombreCoach}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 20),

          // Resumen del plan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _FilaResumen('Plan', widget.tarifa.nombre),
                const SizedBox(height: 8),
                _FilaResumen('Precio', '${widget.tarifa.precio}€ / mes'),
                if (widget.tarifa.diasGracia > 0) ...[
                  const SizedBox(height: 8),
                  _FilaResumen('Periodo de gracia', '${widget.tarifa.diasGracia} días'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.info_circle, color: AppTheme.warning, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'El pago se acordará directamente con tu entrenador. Al confirmar, activarás tu acceso completo a la app.',
                    style: TextStyle(color: Color(0xFF7D5C00), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: AppTheme.secondaryOrange,
              borderRadius: BorderRadius.circular(16),
              onPressed: _procesando ? null : _confirmar,
              child: _procesando
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text(
                      'Confirmar contratación',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaResumen(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          valor,
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
