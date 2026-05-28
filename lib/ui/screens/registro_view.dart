import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../config/theme.dart';

class RegistroEntrenadorView extends StatefulWidget {
  const RegistroEntrenadorView({super.key});

  @override
  State<RegistroEntrenadorView> createState() => _RegistroEntrenadorViewState();
}

class _RegistroEntrenadorViewState extends State<RegistroEntrenadorView> {
  final _nombreController         = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirm  = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre          = _nombreController.text.trim();
    final email           = _emailController.text.trim();
    final password        = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _mostrarError("Por favor, rellena todos los campos");
      return;
    }
    if (password != confirmPassword) {
      _mostrarError("Las contraseñas no coinciden");
      return;
    }
    if (password.length < 6) {
      _mostrarError("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'nombre': nombre,
        'email': email,
        'rol': 'coach',
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Cuenta creada! Inicia sesión ahora."),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Error al registrarse";
      if (e.code == 'email-already-in-use') msg = "Este correo ya está registrado.";
      if (e.code == 'invalid-email') msg = "El correo no tiene un formato válido.";
      _mostrarError(msg);
    } catch (_) {
      _mostrarError("Ocurrió un error inesperado.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Stack(
        children: [
          // fondo degradado
          Container(
            height: size.height * 0.32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A3D7A), AppTheme.primaryBlue, AppTheme.mediumBlue],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // sección hero
                SizedBox(
                  height: size.height * 0.25,
                  child: Stack(
                    children: [
                      // Botón atrás
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.arrow_left,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/CoachOSIcon.png',
                              width: 108,
                              height: 108,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Únete a CoachOS',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Crea tu cuenta de Entrenador',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // tarjeta formulario
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rellena los datos para registrarte',
                            style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                          ),
                          const SizedBox(height: 22),

                          _buildCampo(
                            controller: _nombreController,
                            hint: 'Nombre completo',
                            icono: CupertinoIcons.person,
                          ),
                          const SizedBox(height: 12),
                          _buildCampo(
                            controller: _emailController,
                            hint: 'Correo electrónico',
                            icono: CupertinoIcons.mail,
                            tipo: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _buildCampo(
                            controller: _passwordController,
                            hint: 'Contraseña',
                            icono: CupertinoIcons.lock,
                            esPassword: true,
                            mostrar: _mostrarPassword,
                            onToggle: () => setState(() => _mostrarPassword = !_mostrarPassword),
                          ),
                          const SizedBox(height: 12),
                          _buildCampo(
                            controller: _confirmPasswordController,
                            hint: 'Repetir contraseña',
                            icono: CupertinoIcons.lock_rotation,
                            esPassword: true,
                            mostrar: _mostrarConfirm,
                            onToggle: () => setState(() => _mostrarConfirm = !_mostrarConfirm),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            height: 52,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: AppTheme.secondaryOrange,
                              borderRadius: BorderRadius.circular(16),
                              onPressed: _isLoading ? null : _registrar,
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(color: Colors.white)
                                  : const Text(
                                      'CREAR CUENTA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Ya tienes cuenta? ',
                                style: TextStyle(color: Color(0xFF718096), fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Inicia sesión',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    TextInputType tipo = TextInputType.text,
    bool esPassword = false,
    bool mostrar = false,
    VoidCallback? onToggle,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: hint,
      keyboardType: tipo,
      obscureText: esPassword && !mostrar,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
      ),
      placeholderStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 15),
      style: const TextStyle(fontSize: 15, color: Color(0xFF2D3748)),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Icon(icono, size: 18, color: AppTheme.mediumBlue),
      ),
      suffix: esPassword && onToggle != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  mostrar ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 18,
                  color: AppTheme.mediumBlue,
                ),
              ),
            )
          : null,
    );
  }
}
