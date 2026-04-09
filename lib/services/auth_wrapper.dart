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
        
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
        }

        if (!authSnapshot.hasData) {
          return const LoginView();
        }

        //Si hay sesión, buscam su documento EXACTO en Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, userDoc) {
            if (userDoc.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
            }

            if (userDoc.hasData && userDoc.data!.exists) {
              final data = userDoc.data!.data() as Map<String, dynamic>;
              final String rol = data['rol']?.toString().trim().toLowerCase() ?? 'cliente';

              if (rol == 'entrenador') return const HomeView();
              if (rol == 'admin') return const Scaffold(body: Center(child: Text("Admin")));
              return const HomeViewCliente();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await FirebaseAuth.instance.signOut();
            });

            // Pantalla temporal mientras se ejecuta el cierre de sesión
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