import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../ui/screens/home_view.dart';
import '../ui/screens/login_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. SI NO HAY SESIÓN ACTIVA -> LOGIN
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
        }

        if (!authSnapshot.hasData) {
          return const LoginView();
        }

        // 2. SI HAY SESIÓN -> BUSCAMOS EL ROL EN FIRESTORE
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(authSnapshot.data!.uid)
              .get(),
          builder: (context, userDoc) {
            if (userDoc.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
            }

            // A. SI EL DOCUMENTO EXISTE EN FIRESTORE
            if (userDoc.hasData && userDoc.data!.exists) {
              final data = userDoc.data!.data() as Map<String, dynamic>;
              final String rol = data['rol']?.toString().trim().toLowerCase() ?? 'cliente';

              debugPrint("🚨 ROL DETECTADO: [$rol]");

              // --- VISTA ADMIN ---
              if (rol == 'admin') {
                return Scaffold(
                  backgroundColor: Colors.redAccent,
                  appBar: AppBar(
                    title: const Text("Panel Administración"),
                    backgroundColor: Colors.red.shade900,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      )
                    ],
                  ),
                  body: const Center(
                    child: Text(
                      "🛡️ MODO ADMINISTRADOR\nConfiguración Global",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              } 
              
              // --- VISTA ENTRENADOR ---
              else if (rol == 'entrenador') {
                return const HomeView();
              } 
              
              // --- VISTA CLIENTE ---
              else {
                return Scaffold(
                  backgroundColor: const Color(0xFFE8F5E9),
                  appBar: AppBar(
                    title: const Text("Mi Entrenamiento"),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      )
                    ],
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_pin, size: 80, color: Colors.green),
                          const SizedBox(height: 20),
                          const Text(
                            "¡Hola, Cliente!",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Tu panel personal se está sincronizando...",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            icon: const Icon(Icons.logout),
                            label: const Text("CERRAR SESIÓN"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }

            // B. SI NO HAY DOCUMENTO EN FIRESTORE (PERFIL NO ENCONTRADO)
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_accounts, color: Colors.orange, size: 80),
                      const SizedBox(height: 20),
                      const Text("Perfil no encontrado", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text(
                        "No tienes una ficha en la base de datos con este email.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text("VOLVER AL LOGIN"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}