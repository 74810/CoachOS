import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/ajustes/perfilEdit_view.dart';
import 'package:coach_os_app/ui/screens/ajustes/suscripciones_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart'; // 1. IMPORTANTE: Importa tu servicio

class AjustesView extends StatefulWidget {
  const AjustesView({super.key});

  @override
  State<AjustesView> createState() => _AjustesViewState();
}

class _AjustesViewState extends State<AjustesView> {
  final AuthService authService = AuthService();
  final DatabaseService databaseService = DatabaseService(); // 2. Instancia del servicio

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'Gestión de Negocio', 
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // --- SECCIÓN PERFIL ---
              _buildSectionTitle("MI IDENTIDAD"),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 25,
                        backgroundColor: AppTheme.mediumBlue,
                        child: Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 20),
                      ),
                      title: const Text("Perfil Profesional", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Foto, horario y descripción"),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                      onTap: () => _abrirEditorPerfil(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- SECCIÓN SUSCRIPCIÓN ---
              _buildSectionTitle("PLAN Y FACTURACIÓN"),
              _buildCard(
                child: ListTile(
                  leading: const Icon(CupertinoIcons.creditcard_fill, color: Colors.orange),
                  title: const Text("Mi Suscripción", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Plan Actual: Premium (Anual)"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Activo", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () => _verSuscripciones(context),
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTÓN CERRAR SESIÓN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(CupertinoIcons.power),
                  label: const Text("Finalizar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40), // Espacio extra para asegurar el scroll
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGETS DE APOYO PARA DISEÑO LIMPIO ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  // --- LÓGICA DE NAVEGACIÓN ---

  void _abrirEditorPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PerfilEditView()),
    );
  }

  void _verSuscripciones(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SuscripcionesView()),
    );
  }
}