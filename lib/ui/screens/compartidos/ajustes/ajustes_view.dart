import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/services/auth_wrapper.dart';
import 'package:coach_os_app/ui/screens/coach/bibliotecaRevisiones_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/perfilEdit_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/suscripciones_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/soporte_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/aviso_legal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../coach/bibliotecaRutinas_view.dart';
import '../../coach/bibliotecaDietas_view.dart';

class AjustesView extends StatelessWidget {
  final String rol;
  const AjustesView({super.key, required this.rol});

  Future<String?> _pedirContrasena(BuildContext context, String accion) async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Autenticación", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18)),
          content: CupertinoTextField(obscureText: true, placeholder: "Contraseña actual", onChanged: (val) => password = val),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(onPressed: () => Navigator.pop(context, password), child: const Text("Confirmar")),
          ],
        );
      }
    );
    return password;
  }

  Future<void> _cambiarContrasena(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    final oldPassword = await _pedirContrasena(context, "cambiar tu contraseña");
    if (oldPassword == null || oldPassword.isEmpty) return;
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(cred);
      if (!context.mounted) return;
      String? newPassword;
      await showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text("Nueva Contraseña"),
          content: CupertinoTextField(obscureText: true, placeholder: "Mínimo 6 caracteres", onChanged: (val) => newPassword = val),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")), TextButton(onPressed: () => Navigator.pop(context, newPassword), child: const Text("Actualizar"))],
      ));
      if (newPassword != null && newPassword!.length >= 6) {
        await user.updatePassword(newPassword!);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Éxito"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error"), backgroundColor: Colors.red));
    }
  }

  Future<void> _eliminarCuenta(BuildContext context, bool esEntrenador) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    final password = await _pedirContrasena(context, "eliminar tu cuenta");
    if (password == null || password.isEmpty) return;
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CupertinoActivityIndicator()));
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      if (esEntrenador) {
        final query = await FirebaseFirestore.instance.collection('usuarios').where('entrenador_id', isEqualTo: user.uid).get();
        final batch = FirebaseFirestore.instance.batch();
          for (var doc in query.docs) batch.update(doc.reference, {'entrenador_id': ""});
        await batch.commit();
      }
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).delete();
      await user.delete();
      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthWrapper()), (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esEntrenador = rol == 'entrenador';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(esEntrenador ? 'Gestión' : 'Mi Cuenta', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCard(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: AppTheme.mediumBlue, child: Icon(CupertinoIcons.person_fill, color: Colors.white, size: 20)),
                  title: Text(esEntrenador ? "Perfil Profesional" : "Editar ficha"),
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PerfilEditView(rol: rol))),
                ),
              ),
              const SizedBox(height: 20),

              if (esEntrenador) ...[
                _buildCard(
                  child: Column(
                    children: [
                      ListTile(leading: _buildIconoColor(Icons.fitness_center, AppTheme.primaryBlue), title: const Text("Rutinas"), onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const BibliotecaRutinasView()))),
                      const Divider(height: 1, indent: 60),
                      ListTile(leading: _buildIconoColor(Icons.restaurant_menu, Colors.green), title: const Text("Dietas"), onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const BibliotecaDietasView()))),
                      const Divider(height: 1, indent: 60),
                      ListTile(leading: _buildIconoColor(CupertinoIcons.doc_chart_fill, Colors.purple), title: const Text("Revisiones"), onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const BibliotecaRevisionesView()))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildCard(
                child: ListTile(
                  leading: const Icon(CupertinoIcons.creditcard_fill, color: Colors.orange),
                  title: Text(esEntrenador ? "Mi Plan" : "Mi Tarifa"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SuscripcionesView(rol: rol))),
                ),
              ),

              const SizedBox(height: 30),

              _buildCard(
                child: Column(
                  children: [
                    ListTile(leading: const Icon(CupertinoIcons.lock_fill, color: Colors.grey), title: const Text("Contraseña"), onTap: () => _cambiarContrasena(context)),
                    const Divider(height: 1, indent: 60),
                    ListTile(
                      leading: const Icon(CupertinoIcons.power, color: Colors.grey),
                      title: const Text("Cerrar Sesión"),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          // resetea el árbol de navegación al cerrar sesión
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // soporte y ayuda
              _buildSectionHeader('Soporte y Ayuda'),
              const SizedBox(height: 8),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildIconoColor(CupertinoIcons.question_circle_fill, AppTheme.mediumBlue),
                      title: const Text("Preguntas frecuentes"),
                      subtitle: const Text("Resuelve tus dudas rápidamente", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => SoporteView(rol: rol))),
                    ),
                    const Divider(height: 1, indent: 60),
                    ListTile(
                      leading: _buildIconoColor(CupertinoIcons.chat_bubble_text_fill, AppTheme.secondaryOrange),
                      title: const Text("Contactar con soporte"),
                      subtitle: const Text("soporte@coachos.app", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => SoporteView(rol: rol))),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // legal
              _buildSectionHeader('Legal'),
              const SizedBox(height: 8),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildIconoColor(CupertinoIcons.doc_text_fill, const Color(0xFF546E7A)),
                      title: const Text("Aviso Legal"),
                      subtitle: const Text("Términos, privacidad y cookies", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AvisoLegalView())),
                    ),
                    const Divider(height: 1, indent: 60),
                    ListTile(
                      leading: _buildIconoColor(CupertinoIcons.shield_fill, const Color(0xFF37474F)),
                      title: const Text("Política de Privacidad"),
                      subtitle: const Text("Cómo protegemos tus datos", style: TextStyle(fontSize: 12)),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AvisoLegalView())),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Center(child: TextButton.icon(onPressed: () => _eliminarCuenta(context, esEntrenador), icon: const Icon(CupertinoIcons.delete_solid, color: Colors.red, size: 18), label: const Text("Eliminar cuenta", style: TextStyle(color: Colors.red)))),

              // versión de la app
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'CoachOS v1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: child);
  }

  Widget _buildIconoColor(IconData icono, Color color) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icono, color: color, size: 22));
  }

  Widget _buildSectionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.8),
      ),
    );
  }
}