import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/coach/bibliotecaRevisiones_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/perfilEdit_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/suscripciones_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../services/auth_service.dart';
import '../../coach/bibliotecaRutinas_view.dart'; 
import '../../coach/bibliotecaDietas_view.dart'; 

class AjustesView extends StatelessWidget {
  final String rol; // Recibe el rol: 'entrenador' o 'cliente'
  
  const AjustesView({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final bool esCoach = rol == 'entrenador';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            esCoach ? 'Gestión de Negocio' : 'Mi Cuenta', 
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // --- SECCIÓN PERFIL ---
              _buildSectionTitle(esCoach ? "MI IDENTIDAD" : "DATOS PERSONALES"),
              _buildCard(
                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.mediumBlue,
                    child: Icon(CupertinoIcons.person_fill, color: Colors.white, size: 20),
                  ),
                  title: Text(esCoach ? "Perfil Profesional" : "Editar mis datos"),
                  subtitle: Text(esCoach ? "Foto, horario y descripción" : "Nombre, apellidos y contacto"),
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PerfilEditView(rol: rol)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //SECCIÓN BIBLIOTECA
              if (esCoach) ...[
                _buildSectionTitle("MI CONTENIDO PREDEFINIDO"),
                _buildCard(
                  child: Column(
                    children: [
                      //Biblioteca de Entrenamientos
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fitness_center, color: AppTheme.primaryBlue, size: 22),
                        ),
                        title: const Text("Biblioteca de Entrenamientos"),
                        subtitle: const Text("Gestiona tus plantillas de rutinas"),
                        trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const BibliotecaRutinasView()),
                        ),
                      ),
                      const Divider(height: 1, indent: 60),

                      //Biblioteca de Dietas
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.restaurant_menu, color: Colors.green, size: 22),
                        ),
                        title: const Text("Biblioteca de Dietas"),
                        subtitle: const Text("Gestiona tus plantillas de nutrición"),
                        trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const BibliotecaDietasView()),
                        ),
                      ),
                      const Divider(height: 1, indent: 60),
                      
                      //Biblioteca de Revisiones
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(CupertinoIcons.doc_chart_fill, color: Colors.purple, size: 22),
                        ),
                        title: const Text("Plantillas de Revisión"),
                        subtitle: const Text("Configura qué parámetros medir"),
                        trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const BibliotecaRevisionesView()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              //SECCIÓN SUSCRIPCIÓN 
              _buildSectionTitle("SITUACIÓN ACTUAL"),
              _buildCard(
                child: ListTile(
                  leading: const Icon(CupertinoIcons.creditcard_fill, color: Colors.orange),
                  title: Text(esCoach ? "Mi Plan CoachOS" : "Mi Tarifa Activa"),
                  subtitle: Text(esCoach ? "Gestionar suscripción" : "Ver precio y condiciones"),
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SuscripcionesView(rol: rol)),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              //BOTÓN CERRAR SESIÓN
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text("Cerrar Sesión"),
                        content: const Text("¿Estás seguro de que quieres salir?"),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text("Cancelar"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () async {
                              await authService.signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context, 
                                  '/login', 
                                  (route) => false
                                );
                              }
                            },
                            child: const Text("Cerrar Sesión"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.power, color: Colors.red, size: 20),
                  label: const Text(
                    "Cerrar Sesión", 
                    style: TextStyle(
                      color: Colors.red, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    )
                  ),
                ),
              ),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ],
    );
  }

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
}