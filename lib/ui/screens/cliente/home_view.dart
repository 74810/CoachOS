import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/ui/screens/cliente/chatCliente.dart';
import 'package:coach_os_app/ui/screens/cliente/entreno_view.dart';
import 'package:coach_os_app/ui/screens/cliente/revision_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/ajustes_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dieta_view.dart';
import '../../../config/theme.dart';
import 'principal_view.dart';

class HomeViewCliente extends StatefulWidget {
  const HomeViewCliente({super.key});

  // permite cambiar de tab desde cualquier pantalla hija
  static _HomeViewClienteState of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeViewClienteState>()!;
  }

  @override
  State<HomeViewCliente> createState() => _HomeViewClienteState();
}

class _HomeViewClienteState extends State<HomeViewCliente> {
  int _selectedIndex = 0;

  // dieta, entreno y revisiones se bloquean si la cuota está vencida
  static const _tabsBloqueadasSinCuota = {1, 2, 3};

  final List<Widget> _views = [
    const PrincipalView(),
    const DietaCliente(),
    const EntrenoCliente(),
    const RevisionCliente(),
    const ChatCliente(),
    const AjustesView(rol: 'cliente'),
  ];

  void cambiarTab(int index) {
    setState(() => _selectedIndex = index);
  }

  // devuelve true si el cliente debe ser bloqueado por cuota vencida
  bool _cuotaVencida(Map<String, dynamic> data) {
    final cuotaPagada = data['cuota_pagada'] ?? true;
    if (cuotaPagada == true) return false;

    // clientes sin campo de fecha → sin bloqueo para compatibilidad retroactiva
    final fechaData = data['fecha_ultimo_pago'];
    if (fechaData == null) return false;

    DateTime fechaPago;
    if (fechaData is Timestamp) {
      fechaPago = fechaData.toDate();
    } else {
      return false;
    }

    final diasDesdePago = DateTime.now().difference(fechaPago).inDays;
    final diasGracia = (data['dias_gracia'] ?? 3) as int;
    return diasDesdePago > (30 + diasGracia);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final cuotaVencida = _cuotaVencida(data);
        final tabBloqueada = cuotaVencida && _tabsBloqueadasSinCuota.contains(_selectedIndex);

        return Scaffold(
          backgroundColor: AppTheme.lightBlue,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Stack(
              children: [
                IndexedStack(index: _selectedIndex, children: _views),
                // overlay de bloqueo por cuota vencida
                if (tabBloqueada)
                  _VistaCuotaVencida(
                    onIrAlChat: () => setState(() => _selectedIndex = 4),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: cambiarTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            showUnselectedLabels: true,
            items: [
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
              _buildNavItem(CupertinoIcons.doc_text_fill, 'Dieta',
                  cuotaVencida && _tabsBloqueadasSinCuota.contains(1)),
              _buildNavItem(CupertinoIcons.flame_fill, 'Entreno',
                  cuotaVencida && _tabsBloqueadasSinCuota.contains(2)),
              _buildNavItem(CupertinoIcons.doc_chart_fill, 'Revisiones',
                  cuotaVencida && _tabsBloqueadasSinCuota.contains(3)),
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2_fill), label: 'Chat'),
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings_solid), label: 'Ajustes'),
            ],
          ),
        );
      },
    );
  }

  // item de navegación con candado si la tab está bloqueada
  BottomNavigationBarItem _buildNavItem(IconData icono, String label, bool bloqueado) {
    return BottomNavigationBarItem(
      label: label,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icono),
          if (bloqueado)
            const Positioned(
              top: -2, right: -4,
              child: Icon(CupertinoIcons.lock_fill, size: 10, color: AppTheme.danger),
            ),
        ],
      ),
    );
  }
}

// pantalla de bloqueo cuando la cuota del cliente está vencida
class _VistaCuotaVencida extends StatelessWidget {
  final VoidCallback onIrAlChat;
  const _VistaCuotaVencida({required this.onIrAlChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.lightBlue,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.creditcard_fill, color: AppTheme.warning, size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cuota pendiente',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu periodo de gracia ha finalizado. Para acceder a tu dieta, entrenamiento y progreso, contacta con tu entrenador para regularizar el pago.',
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onIrAlChat,
                  child: const Text(
                    'Hablar con mi entrenador',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
