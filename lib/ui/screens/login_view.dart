import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/services/auth_service.dart';
import 'package:coach_os_app/ui/screens/cliente/onboarding/registro_cliente_view.dart';
import 'package:coach_os_app/ui/screens/registro_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _cargando = false;
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _mostrarError("Por favor, rellena todos los campos");
      return;
    }

    setState(() => _cargando = true);
    final user = await _authService.signIn(email, password);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (user == null) _mostrarError("Correo o contraseña incorrectos");
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
          // fondo azul superior
          Container(
            height: size.height * 0.38,
            color: AppTheme.primaryBlue,
          ),
          SafeArea(
            child: Column(
              children: [
                // sección hero con logo y nombre
                SizedBox(
                  height: size.height * 0.30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/CoachOSIcon.png', width: 135, height: 135),
                      const SizedBox(height: 16),
                      const Text(
                        'CoachOS',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plataforma para entrenadores',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // tarjeta blanca con el formulario
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bienvenido',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Inicia sesión en tu cuenta',
                            style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                          ),
                          const SizedBox(height: 28),
                          // campo email
                          _buildCampo(
                            controller: _emailController,
                            hint: 'Correo electrónico',
                            icono: CupertinoIcons.mail,
                            tipo: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          // campo contraseña
                          _buildCampo(
                            controller: _passwordController,
                            hint: 'Contraseña',
                            icono: CupertinoIcons.lock,
                            esPassword: true,
                          ),
                          const SizedBox(height: 28),
                          // botón iniciar sesión
                          SizedBox(
                            height: 52,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(16),
                              onPressed: _cargando ? null : _iniciarSesion,
                              child: _cargando
                                  ? const CupertinoActivityIndicator(color: Colors.white)
                                  : const Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // enlace para registro de entrenador
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Eres entrenador? ',
                                style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  CupertinoPageRoute(builder: (_) => const RegistroEntrenadorView()),
                                ),
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(
                                    color: AppTheme.secondaryOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('o', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // acceso para cliente nuevo
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (_) => const RegistroClienteView()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.person_fill, size: 16, color: AppTheme.primaryBlue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Soy cliente nuevo',
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: hint,
      keyboardType: tipo,
      obscureText: esPassword && !_mostrarPassword,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      suffix: esPassword
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _mostrarPassword = !_mostrarPassword),
                child: Icon(
                  _mostrarPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 18,
                  color: AppTheme.mediumBlue,
                ),
              ),
            )
          : null,
    );
  }
}
