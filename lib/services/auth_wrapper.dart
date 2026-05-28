import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../ui/screens/admin/admin_home_view.dart';
import '../ui/screens/coach/home_view.dart';
import '../ui/screens/login_view.dart';
import '../ui/screens/cliente/home_view.dart';
import '../ui/screens/cliente/onboarding/home_view_lead.dart';
import '../ui/screens/cliente/onboarding/registro_cliente_view.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription? _linkSub;
  String? _entrenadorIdPendiente;

  // timer de seguridad: si el documento no existe en 10 s, cierra sesión
  Timer? _timerDocumento;
  bool _forzarCierreSesion = false;

  @override
  void initState() {
    super.initState();
    _iniciarDeepLinks();
  }

  void _iniciarDeepLinks() async {
    final appLinks = AppLinks();
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) _procesarUri(uri);
    } catch (_) {}
    // escucha deep links mientras la app está en primer plano
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _procesarUri(uri);
    });
  }

  void _procesarUri(Uri uri) {
    if (uri.scheme == 'coachos' && uri.host == 'registro') {
      final entrenadorId = uri.queryParameters['entrenador_id'];
      if (entrenadorId != null && entrenadorId.isNotEmpty) {
        setState(() => _entrenadorIdPendiente = entrenadorId);
      }
    }
  }

  void _iniciarTimerDocumento() {
    _timerDocumento?.cancel();
    _forzarCierreSesion = false;
    _timerDocumento = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _forzarCierreSesion = true);
    });
  }

  void _cancelarTimerDocumento() {
    _timerDocumento?.cancel();
    _timerDocumento = null;
    _forzarCierreSesion = false;
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _timerDocumento?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
        }

        // usuario no autenticado
        if (!authSnapshot.hasData) {
          if (_entrenadorIdPendiente != null) {
            return RegistroClienteView(entrenadorId: _entrenadorIdPendiente);
          }
          return const LoginView();
        }

        // usuario autenticado: leer documento para conocer el rol
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, userDoc) {
            if (userDoc.connectionState == ConnectionState.waiting && !userDoc.hasData) {
              return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
            }

            if (userDoc.hasData && userDoc.data!.exists) {
              _cancelarTimerDocumento();
              final data = userDoc.data!.data() as Map<String, dynamic>;
              final String rol = data['rol']?.toString().trim().toLowerCase() ?? 'cliente';
              final String estadoOnboarding = data['estado_onboarding'] ?? 'activo';

              if (rol == 'entrenador') return const HomeView();
              if (rol == 'admin') return const AdminHomeView();

              // cliente en proceso de registro
              if (estadoOnboarding == 'lead') {
                final String? entrenadorId = data['entrenador_id'] as String?;
                return HomeViewLead(entrenadorId: entrenadorId);
              }

              return const HomeViewCliente();
            }

            // race condition: el documento aún no existe tras el registro
            if (_forzarCierreSesion) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await FirebaseAuth.instance.signOut();
              });
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.red, size: 50),
                      SizedBox(height: 16),
                      Text("Error: Tu perfil no está registrado en la base de datos.", textAlign: TextAlign.center),
                      Text("Cerrando sesión...", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            // inicia el timer solo una vez mientras el documento se crea
            if (_timerDocumento == null) _iniciarTimerDocumento();
            return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
          },
        );
      },
    );
  }
}
