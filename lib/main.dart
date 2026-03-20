import 'package:coach_os_app/services/auth_wrapper.dart';
import 'package:coach_os_app/ui/screens/home_view.dart';
import 'package:coach_os_app/ui/screens/login_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';

void main() async {
  // Aseguramos que el motor de Flutter esté listo antes de llamar a Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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