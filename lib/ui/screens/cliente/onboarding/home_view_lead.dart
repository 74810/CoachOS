import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/services/auth_service.dart';
import 'package:coach_os_app/ui/screens/cliente/onboarding/lista_entrenadores_view.dart';
import 'package:coach_os_app/ui/screens/cliente/onboarding/perfil_publico_coach_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// pantalla de leads: redirige al perfil del coach asignado o al listado de entrenadores
class HomeViewLead extends StatelessWidget {
  final String? entrenadorId;

  const HomeViewLead({super.key, this.entrenadorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/CoachOSIcon.png', height: 26),
            const SizedBox(width: 8),
            const Text(
              'CoachOS',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right, color: AppTheme.primaryBlue),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false, // El AppBar ya maneja la parte superior
        bottom: true,
        child: entrenadorId != null
            ? PerfilPublicoCoachView(coachId: entrenadorId!, mostrarBackButton: false)
            : const ListaEntrenadoresView(),
      ),
    );
  }
}
