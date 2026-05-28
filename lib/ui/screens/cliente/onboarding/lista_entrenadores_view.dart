import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/services/database_service.dart';
import 'package:coach_os_app/ui/screens/cliente/onboarding/perfil_publico_coach_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListaEntrenadoresView extends StatelessWidget {
  const ListaEntrenadoresView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner informativo
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.mediumBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.person_2_fill, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encuentra tu entrenador',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Habla con ellos, conoce sus tarifas y empieza tu transformación.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'ENTRENADORES DISPONIBLES',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: DatabaseService().getEntrenadoresActivos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final entrenadores = snapshot.data ?? [];

              if (entrenadores.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.person_crop_circle_badge_xmark, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay entrenadores disponibles',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: entrenadores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final coach = entrenadores[index];
                  return _TarjetaEntrenador(
                    coach: coach,
                    onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => Scaffold(
                          body: PerfilPublicoCoachView(
                            coachId: coach['id'],
                            mostrarBackButton: true,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaEntrenador extends StatelessWidget {
  final Map<String, dynamic> coach;
  final VoidCallback onTap;

  const _TarjetaEntrenador({required this.coach, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre = coach['nombre'] ?? 'Sin nombre';
    final descripcion = coach['descripcion'] ?? 'Entrenador personal';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                inicial,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ver perfil',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
