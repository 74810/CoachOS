import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/models/cliente_model.dart';
import 'package:coach_os_app/services/database_service.dart';
import 'package:coach_os_app/ui/screens/coach/clienteDetalle/clienteDetalle_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminHomeView extends StatefulWidget {
  const AdminHomeView({super.key});

  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  int _tabIndex = 0;
  String _busquedaCoach = '';
  String _busquedaCliente = '';
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Panel Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.primaryBlue,
            child: Row(
              children: [
                _TabBtn(label: 'Entrenadores', icon: CupertinoIcons.person_2_fill, selected: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                _TabBtn(label: 'Clientes', icon: CupertinoIcons.person_3_fill, selected: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
              ],
            ),
          ),
        ),
      ),
      body: _tabIndex == 0 ? _VistaEntrenadores(db: _db, busqueda: _busquedaCoach, onBusqueda: (v) => setState(() => _busquedaCoach = v))
                           : _VistaClientes(db: _db, busqueda: _busquedaCliente, onBusqueda: (v) => setState(() => _busquedaCliente = v)),
    );
  }
}

// botón de tab
class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? Colors.white : Colors.transparent, width: 3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.white54, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// vista entrenadores
class _VistaEntrenadores extends StatelessWidget {
  final DatabaseService db;
  final String busqueda;
  final ValueChanged<String> onBusqueda;
  const _VistaEntrenadores({required this.db, required this.busqueda, required this.onBusqueda});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: CupertinoSearchTextField(
            placeholder: 'Buscar entrenador...',
            backgroundColor: Colors.white,
            onChanged: onBusqueda,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.adminGetEntrenadores(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CupertinoActivityIndicator());
              final lista = snap.data!.where((c) {
                final nombre = (c['nombre'] ?? '').toString().toLowerCase();
                final email = (c['email'] ?? '').toString().toLowerCase();
                return nombre.contains(busqueda.toLowerCase()) || email.contains(busqueda.toLowerCase());
              }).toList();

              if (lista.isEmpty) return const Center(child: Text('No hay entrenadores.'));

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: lista.length,
                itemBuilder: (ctx, i) => _TarjetaCoach(data: lista[i], db: db),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaCoach extends StatelessWidget {
  final Map<String, dynamic> data;
  final DatabaseService db;
  const _TarjetaCoach({required this.data, required this.db});

  @override
  Widget build(BuildContext context) {
    final nombre = data['nombre'] ?? 'Sin nombre';
    final email = data['email'] ?? '';
    final plan = (data['plan_suscripcion'] ?? 'cantera').toString().toUpperCase();
    final activa = data['subscripcion_activa'] ?? false;
    final fechaFin = data['fecha_fin_plan'];
    String fechaFinStr = 'Sin fecha';
    if (fechaFin is Timestamp) {
      final dt = fechaFin.toDate();
      fechaFinStr = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: activa ? AppTheme.primaryBlue : Colors.grey,
              child: const Icon(CupertinoIcons.person_fill, color: Colors.white),
            ),
            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$email\nPlan: $plan · Vence: $fechaFinStr'),
            isThreeLine: true,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activa ? AppTheme.success.withOpacity(0.15) : AppTheme.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(activa ? 'ACTIVA' : 'INACTIVA',
                  style: TextStyle(color: activa ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(CupertinoIcons.pencil, size: 14),
                    label: const Text('Gestionar'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                    onPressed: () => _modalGestionCoach(context, data, db),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(CupertinoIcons.person_2, size: 14),
                    label: const Text('Sus clientes'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                    onPressed: () => _verClientesDeCoach(context, data['id'], nombre),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _verClientesDeCoach(BuildContext context, String coachId, String nombreCoach) {
    Navigator.push(context, CupertinoPageRoute(builder: (_) => _ClientesDeCoachView(coachId: coachId, nombreCoach: nombreCoach, db: db)));
  }

  void _modalGestionCoach(BuildContext context, Map<String, dynamic> data, DatabaseService db) {
    final planes = ['cantera', 'rookie', 'all-star', 'hall of fame'];
    String planSeleccionado = data['plan_suscripcion'] ?? 'cantera';
    bool activaSeleccionada = data['subscripcion_activa'] ?? false;
    DateTime fechaFin = (data['fecha_fin_plan'] is Timestamp)
        ? (data['fecha_fin_plan'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestionar: ${data['nombre']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Suscripción activa', style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoSwitch(
                    value: activaSeleccionada,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => setModalState(() => activaSeleccionada = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Plan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: DropdownButton<String>(
                  value: planSeleccionado,
                  isExpanded: true,
                  items: planes.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (v) => setModalState(() => planSeleccionado = v!),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Vence: ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Cambiar fecha'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fechaFin,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 1825)),
                      );
                      if (picked != null) setModalState(() => fechaFin = picked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    try {
                      await db.adminActualizarSuscripcionCoach(
                        coachId: data['id'],
                        activa: activaSeleccionada,
                        plan: planSeleccionado,
                        fechaFin: fechaFin,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suscripción actualizada'), backgroundColor: AppTheme.success));
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                    }
                  },
                  child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// clientes de un coach específico
class _ClientesDeCoachView extends StatelessWidget {
  final String coachId;
  final String nombreCoach;
  final DatabaseService db;
  const _ClientesDeCoachView({required this.coachId, required this.nombreCoach, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: Text('Clientes de $nombreCoach', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('entrenador_id', isEqualTo: coachId)
            .where('rol', isEqualTo: 'cliente')
            .snapshots()
            .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CupertinoActivityIndicator());
          if (snap.data!.isEmpty) return const Center(child: Text('Este coach no tiene clientes.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snap.data!.length,
            itemBuilder: (ctx, i) => _TarjetaClienteAdmin(data: snap.data![i], db: db),
          );
        },
      ),
    );
  }
}

// vista clientes
class _VistaClientes extends StatelessWidget {
  final DatabaseService db;
  final String busqueda;
  final ValueChanged<String> onBusqueda;
  const _VistaClientes({required this.db, required this.busqueda, required this.onBusqueda});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: CupertinoSearchTextField(
            placeholder: 'Buscar cliente...',
            backgroundColor: Colors.white,
            onChanged: onBusqueda,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.adminGetClientes(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CupertinoActivityIndicator());
              final lista = snap.data!.where((c) {
                final nombre = (c['nombre'] ?? '').toString().toLowerCase();
                final email = (c['email'] ?? '').toString().toLowerCase();
                return nombre.contains(busqueda.toLowerCase()) || email.contains(busqueda.toLowerCase());
              }).toList();

              if (lista.isEmpty) return const Center(child: Text('No hay clientes.'));

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: lista.length,
                itemBuilder: (ctx, i) => _TarjetaClienteAdmin(data: lista[i], db: db),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaClienteAdmin extends StatelessWidget {
  final Map<String, dynamic> data;
  final DatabaseService db;
  const _TarjetaClienteAdmin({required this.data, required this.db});

  @override
  Widget build(BuildContext context) {
    final nombre = '${data['nombre'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
    final email = data['email'] ?? '';
    final cuotaPagada = data['cuota_pagada'] ?? false;
    final onboarding = data['estado_onboarding'] ?? 'activo';
    final tarifa = data['tipo_tarifa'] ?? 'Sin tarifa';
    final isLead = onboarding == 'lead';

    Color colorEstado = cuotaPagada ? AppTheme.success : AppTheme.danger;
    if (isLead) colorEstado = AppTheme.warning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorEstado.withOpacity(0.2),
              child: Icon(CupertinoIcons.person_fill, color: colorEstado),
            ),
            title: Text(nombre.isEmpty ? 'Sin nombre' : nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$email\nTarifa: $tarifa'),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: colorEstado.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    isLead ? 'LEAD' : (cuotaPagada ? 'AL DÍA' : 'IMPAGO'),
                    style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(CupertinoIcons.pencil, size: 14),
                    label: const Text('Gestionar'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                    onPressed: () => _modalGestionCliente(context, data, db),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(CupertinoIcons.eye, size: 14),
                    label: const Text('Ver detalle'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                    onPressed: () {
                      final cliente = Cliente.fromFirestore(
                        Map<String, dynamic>.from(data)..remove('id'),
                        data['id'],
                      );
                      Navigator.push(context, CupertinoPageRoute(builder: (_) => ClienteDetalleView(cliente: cliente)));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _modalGestionCliente(BuildContext context, Map<String, dynamic> data, DatabaseService db) {
    bool cuotaPagada = data['cuota_pagada'] ?? false;
    String estadoOnboarding = data['estado_onboarding'] ?? 'activo';
    final entrenadorCtrl = TextEditingController(text: data['entrenador_id'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestionar: ${data['nombre'] ?? 'cliente'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cuota pagada', style: TextStyle(fontWeight: FontWeight.w600)),
                  CupertinoSwitch(
                    value: cuotaPagada,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => setModalState(() => cuotaPagada = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Estado onboarding', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CupertinoSegmentedControl<String>(
                  groupValue: estadoOnboarding,
                  selectedColor: AppTheme.primaryBlue,
                  borderColor: AppTheme.primaryBlue,
                  unselectedColor: Colors.white,
                  children: const {
                    'lead': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Lead')),
                    'activo': Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Activo')),
                  },
                  onValueChanged: (v) => setModalState(() => estadoOnboarding = v),
                ),
              ),
              const SizedBox(height: 16),

              const Text('ID Entrenador asignado', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: entrenadorCtrl,
                placeholder: 'UID del entrenador',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    try {
                      await db.adminActualizarPagoCliente(clienteId: data['id'], cuotaPagada: cuotaPagada);
                      await db.adminActualizarCampos(data['id'], {
                        'estado_onboarding': estadoOnboarding,
                        'entrenador_id': entrenadorCtrl.text.trim(),
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente actualizado'), backgroundColor: AppTheme.success));
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
                    }
                  },
                  child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
