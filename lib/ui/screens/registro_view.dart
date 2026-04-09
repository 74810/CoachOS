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
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _registrar() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    //Validaciones básicas
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
      //Crear usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      //Guardar datos en Firestore con el ROL de Coach
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': nombre,
        'email': email,
        'rol': 'coach',
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      //Volver al Login
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Cuenta creada! Inicia sesión ahora."), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al registrarse";
      if (e.code == 'email-already-in-use') mensaje = "Este correo ya está registrado.";
      if (e.code == 'invalid-email') mensaje = "El correo no tiene un formato válido.";
      _mostrarError(mensaje);
    } catch (e) {
      _mostrarError("Ocurrió un error inesperado.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlue),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fitness_center_rounded, size: 60, color: AppTheme.secondaryOrange),
              const SizedBox(height: 20),
              const Text(
                "Únete a CoachOS",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
              ),
              const Text(
                "Crea tu cuenta de Entrenador",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // CAMPOS DE TEXTO
              _buildTextField(controller: _nombreController, hint: "Nombre completo", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(controller: _emailController, hint: "Correo electrónico", icon: Icons.email_outlined, isEmail: true),
              const SizedBox(height: 16),
              _buildTextField(controller: _passwordController, hint: "Contraseña", icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 16),
              _buildTextField(controller: _confirmPasswordController, hint: "Repetir contraseña", icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 32),

              // BOTÓN DE REGISTRO
              SizedBox(
                height: 50,
                child: CupertinoButton.filled(
                  onPressed: _isLoading ? null : _registrar,
                  child: _isLoading 
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text("CREAR CUENTA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}