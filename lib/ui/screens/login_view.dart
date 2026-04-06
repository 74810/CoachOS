import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/services/auth_service.dart';
import 'package:coach_os_app/ui/screens/registro_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/CoachOSIcon.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                'CoachOS',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email del Entrenador',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email)
                ),
              ),
              const SizedBox(height: 20),
            
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock)
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async{
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    if(email.isNotEmpty && password.isNotEmpty){
                      var user = await _authService.signIn(email, password);
                      if(user != null){
                        print("Login correcto: ${user.uid}"); 
                          Navigator.pushReplacementNamed(context, '/');
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error, credenciales incorrectas'))
                        );
                      }
                    }
                    print("Intentando iniciar sesión con email: ${_emailController.text}");
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
                ),
              ),

              // Busca esta Row al final de tu login_view.dart y sustitúyela:
const SizedBox(height: 30),

// BOTÓN DE REGISTRO CORREGIDO (CON FLEXIBLE)
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text("¿No tienes cuenta? ", style: TextStyle(color: Colors.grey)),
    // Envolvemos el GestureDetector en un Flexible para evitar el overflow
    Flexible(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const RegistroEntrenadorView()),
          );
        },
        child: const Text(
          "Regístrate como Entrenador",
          textAlign: TextAlign.center, // Centramos el texto si baja de línea
          style: TextStyle(
            color: AppTheme.secondaryOrange, // Tu color naranja
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
),
            ],
          ),
        ),
      ),
    );
  }
}