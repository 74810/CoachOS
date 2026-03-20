import 'package:firebase_auth/firebase_auth.dart';

//Iniciar sesion con email y contraseña
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
        print('Error al iniciar sesión: ${e.toString()}');
      return null;
    }
  }

//Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
}