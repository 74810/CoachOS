import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Añadido para poder cerrar sesión
import 'package:coach_os_app/services/auth_wrapper.dart';
import 'package:coach_os_app/ui/screens/coach/home_view.dart';
import 'package:coach_os_app/ui/screens/login_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';

void main() async {
  // Asegura que los widgets de Flutter estén listos antes de inicializar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la conexión con Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirebaseAuth.instance.signOut();

  // Arrancamos la App limpia
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoachOS',
      theme: AppTheme.getTheme(),
      home: const AuthWrapper(), 
      routes: {
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomeView(),
      },
    );
  }
}