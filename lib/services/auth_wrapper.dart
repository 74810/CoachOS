import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../ui/screens/coach/home_view.dart';
import '../ui/screens/login_view.dart';
import '../ui/screens/cliente/home_view.dart'; 

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Esperando a ver si hay alguien logueado
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
        }

        // 2. Si no hay sesión, al Login
        if (!authSnapshot.hasData) {
          return const LoginView();
        }

        // 3. Si hay sesión, buscamos su documento EXACTO en Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, userDoc) {
            if (userDoc.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
            }

            // 4. SI EL DOCUMENTO EXISTE: Le damos paso a su pantalla
            if (userDoc.hasData && userDoc.data!.exists) {
              final data = userDoc.data!.data() as Map<String, dynamic>;
              final String rol = data['rol']?.toString().trim().toLowerCase() ?? 'cliente';

              if (rol == 'entrenador') return const HomeView();
              if (rol == 'admin') return const Scaffold(body: Center(child: Text("Admin")));
              return const HomeViewCliente();
            }

            // 5. SI EL DOCUMENTO NO EXISTE: Lo expulsamos inmediatamente
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut(); // Cerramos la sesión
            });

            // Pantalla temporal mientras se ejecuta el cierre de sesión (dura milisegundos)
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
          },
        );
      },
    );
  }
}