import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/ajustes_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/chats/listaChats_view.dart';
import 'package:coach_os_app/ui/screens/coach/miDespacho/miDespacho_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:coach_os_app/ui/screens/coach/clientes_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // static para sobrevivir a reconstrucciones del AuthWrapper
  static int _indiceSeleccionado = 0;

  // tabs bloqueadas cuando la suscripción expira
  static const _tabsBloqueadasSinSuscripcion = {2};

  final List<Widget> _pantallas = [
    const ClientesView(),
    const DespachoView(),
    const ChatsView(),
    const AjustesView(rol: 'entrenador'),
  ];

  bool _suscripcionActiva(Map<String, dynamic> data) {
    final activa = data['subscripcion_activa'] ?? true;
    if (activa == false) return false;
    final fechaFin = data['fecha_fin_plan'];
    if (fechaFin == null) return true;
    if (fechaFin is Timestamp) {
      return fechaFin.toDate().isAfter(DateTime.now());
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final suscripcionOk = _suscripcionActiva(data);
        final tabBloqueada = !suscripcionOk &&
            _tabsBloqueadasSinSuscripcion.contains(_indiceSeleccionado);

        return Scaffold(
          backgroundColor: AppTheme.lightBlue,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _indiceSeleccionado,
            onTap: (index) => setState(() => _indiceSeleccionado = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            showUnselectedLabels: true,
            items: [
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.group_solid), label: 'Clientes'),
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.briefcase_fill), label: 'Despacho'),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(CupertinoIcons.chat_bubble_2_fill),
                    // candado si la suscripción está caducada
                    if (!suscripcionOk)
                      const Positioned(
                        top: -2, right: -4,
                        child: Icon(CupertinoIcons.lock_fill, size: 10, color: AppTheme.danger),
                      ),
                  ],
                ),
                label: 'Chats',
              ),
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings_solid), label: 'Ajustes'),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                IndexedStack(
                  index: _indiceSeleccionado,
                  children: _pantallas,
                ),
                // overlay de bloqueo sobre la tab de chats
                if (tabBloqueada)
                  _VistaSuscripcionRequerida(
                    onRenovar: () => setState(() => _indiceSeleccionado = 3),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// pantalla de bloqueo cuando la suscripción del coach expira
class _VistaSuscripcionRequerida extends StatelessWidget {
  final VoidCallback onRenovar;
  const _VistaSuscripcionRequerida({required this.onRenovar});

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
                  color: AppTheme.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.lock_shield_fill,
                    color: AppTheme.danger, size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'Suscripción requerida',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu suscripción ha vencido. Renueva tu plan para acceder a los chats con tus clientes.',
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
                  onPressed: onRenovar,
                  child: const Text(
                    'Ir a Ajustes → Mi Plan',
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
