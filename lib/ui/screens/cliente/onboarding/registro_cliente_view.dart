import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/services/auth_service.dart';
import 'package:coach_os_app/services/database_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegistroClienteView extends StatefulWidget {
  final String? entrenadorId;

  const RegistroClienteView({super.key, this.entrenadorId});

  @override
  State<RegistroClienteView> createState() => _RegistroClienteViewState();
}

class _RegistroClienteViewState extends State<RegistroClienteView> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _linkController = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  bool _cargando = false;
  bool _mostrarPass = false;
  bool _mostrarConfirm = false;
  bool _mostrarCampoLink = false;
  String? _nombreCoach;
  String? _entrenadorIdDelLink; // entrenador_id extraído manualmente del link

  @override
  void initState() {
    super.initState();
    if (widget.entrenadorId != null) _cargarNombreCoach();
    _linkController.addListener(_parsearLink);
  }

  // Extrae el entrenador_id cuando el usuario pega el link en el campo
  void _parsearLink() {
    final texto = _linkController.text.trim();
    if (texto.isEmpty) {
      setState(() {
        _entrenadorIdDelLink = null;
        _nombreCoach = null;
      });
      return;
    }
    try {
      final uri = Uri.tryParse(texto);
      if (uri != null) {
        final id = uri.queryParameters['entrenador_id'];
        if (id != null && id.isNotEmpty && id != _entrenadorIdDelLink) {
          setState(() => _entrenadorIdDelLink = id);
          _cargarNombreCoachDesdeId(id);
        }
      }
    } catch (_) {}
  }

  Future<void> _cargarNombreCoachDesdeId(String coachId) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(coachId)
        .get();
    if (!mounted) return;
    setState(() {
      _nombreCoach = doc.exists ? (doc.data()?['nombre'] ?? 'tu entrenador') : null;
    });
    if (_nombreCoach == null && coachId == _entrenadorIdDelLink) {
      _mostrarError('Link no válido: el entrenador no existe');
    }
  }

  Future<void> _cargarNombreCoach() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.entrenadorId)
        .get();
    if (!mounted) return;
    if (doc.exists) {
      setState(() => _nombreCoach = doc.data()?['nombre'] ?? 'tu entrenador');
    }
  }

  Future<void> _registrar() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _mostrarError('Por favor, rellena todos los campos');
      return;
    }
    if (password != confirm) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    // Prioridad: deep link automático > link pegado manualmente > sin entrenador
    final entrenadorId = widget.entrenadorId ?? _entrenadorIdDelLink;

    setState(() => _cargando = true);

    final user = await _authService.signUp(email, password);
    if (!mounted) return;

    if (user == null) {
      setState(() => _cargando = false);
      _mostrarError('Error al crear la cuenta. Comprueba que el email no esté en uso.');
      return;
    }

    try {
      await _db.crearDocumentoCliente(
        uid: user.uid,
        nombre: nombre,
        email: email,
        entrenadorId: entrenadorId,
      );
    } catch (e) {
      // Rollback: si falla Firestore, borramos el usuario de Auth para no dejar huérfanos
      await user.delete();
      if (!mounted) return;
      setState(() => _cargando = false);
      _mostrarError('Error al guardar tu perfil. Inténtalo de nuevo.');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Stack(
        children: [
          Container(
            height: size.height * 0.42,
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
                // Header hero
                SizedBox(
                  height: size.height * 0.34,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/CoachOSIcon.png',
                              width: 120,
                              height: 120,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Crea tu cuenta',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (widget.entrenadorId != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.link, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _nombreCoach != null
                                          ? 'Invitado por $_nombreCoach'
                                          : 'Invitado por un entrenador',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                'Accede como cliente',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulario
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
                            mostrar: _mostrarPass,
                            onToggle: () => setState(() => _mostrarPass = !_mostrarPass),
                          ),
                          const SizedBox(height: 12),
                          _buildCampo(
                            controller: _confirmPasswordController,
                            hint: 'Confirmar contraseña',
                            icono: CupertinoIcons.lock_shield,
                            esPassword: true,
                            mostrar: _mostrarConfirm,
                            onToggle: () => setState(() => _mostrarConfirm = !_mostrarConfirm),
                          ),
                          // Campo opcional de link (solo visible si no hay entrenador por deep link)
                          if (widget.entrenadorId == null) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => setState(() => _mostrarCampoLink = !_mostrarCampoLink),
                              child: Row(
                                children: [
                                  Icon(
                                    _mostrarCampoLink
                                        ? CupertinoIcons.chevron_down
                                        : CupertinoIcons.chevron_forward,
                                    size: 13,
                                    color: AppTheme.mediumBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '¿Tienes un enlace de invitación?',
                                    style: TextStyle(
                                      color: AppTheme.mediumBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: _mostrarCampoLink
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        CupertinoTextField(
                                          controller: _linkController,
                                          placeholder: 'Pega aquí el enlace (coachos://...)',
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF4F6F9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          placeholderStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF2D3748)),
                                          prefix: const Padding(
                                            padding: EdgeInsets.only(left: 14),
                                            child: Icon(CupertinoIcons.link, size: 16, color: AppTheme.mediumBlue),
                                          ),
                                        ),
                                        if (_entrenadorIdDelLink != null && _nombreCoach != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.success.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.success, size: 14),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Entrenador encontrado: $_nombreCoach',
                                                  style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],

                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: AppTheme.secondaryOrange,
                              borderRadius: BorderRadius.circular(16),
                              onPressed: _cargando ? null : _registrar,
                              child: _cargando
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
              padding: const EdgeInsets.only(right: 14),
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
