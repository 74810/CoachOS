import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/models/cliente_model.dart';
import 'package:coach_os_app/models/ejercicio_model.dart';
import 'package:coach_os_app/models/tarifa_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtengo la lista de clientes que pertenecen específicamente al coach logueado
  Stream<List<Cliente>> getClientes() {
    final String miUid = _auth.currentUser?.uid ?? "";

    return _db
        .collection('usuarios')
        .where('entrenador_id', isEqualTo: miUid) // Filtro para que el coach solo vea a los suyos
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Cliente.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Traigo todos los ejercicios de la biblioteca global para los entrenamientos
  Stream<List<Ejercicio>> getEjercicios() {
    return _db.collection('biblioteca_ejercicios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ejercicio.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
  // --- GESTIÓN DE TARIFAS ---

  // Elimino una tarifa de la base de datos por su ID
  Future<void> eliminarTarifa(String id) async {
    await _db.collection('tarifas').doc(id).delete();
  }

  // Creo una nueva tarifa vinculándola al ID del coach actual
  Future<void> crearTarifa(String nombre, int precio, String desc, int gracia, bool visible) async { 
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('tarifas').add({
      'nombre': nombre,
      'precio': precio,
      'descripcion': desc,
      'diasGracia': gracia, 
      'esVisible': visible, 
      'coachId': uid,
      'fecha_creacion': FieldValue.serverTimestamp(),
    });
  }

  // Cambio si una tarifa es pública o privada para los clientes
  Future<void> actualizarVisibilidadTarifa(String tarifaId, bool nuevaVisibilidad) async {
    await _db.collection('tarifas').doc(tarifaId).update({
      'esVisible': nuevaVisibilidad,
    });
  }

  // Obtengo solo las tarifas que ha creado el coach que está usando la app
  Stream<List<Tarifa>> getTarifas() {
    final uid = _auth.currentUser?.uid;
    return _db
        .collection('tarifas')
        .where('coachId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tarifa.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // --- PERFIL Y CONFIGURACIÓN ---

  // Actualizo los datos profesionales del coach (horarios, descripción, etc.)
  Future<void> actualizarPerfilAdmin({
    required String uid,
    required String nombre,
    required String descripcion,
    required String horarioInicio,
    required String horarioFin,
  }) async {
    return await _db.collection('usuarios').doc(uid).set({
      'nombre': nombre,
      'descripcion': descripcion,
      'horarioInicio': horarioInicio,
      'horarioFin': horarioFin,
      'perfilCompletado': true,
    }, SetOptions(merge: true));
  }

  Future<void> inicializarBaseDeDatosMaestra() async {
  final db = FirebaseFirestore.instance;

  // MAPA CON LOS DATOS EXACTOS (Copiados de tus capturas)
  Map<String, Map<String, dynamic>> usuarios = {
    // ADMIN (admin@test.com)
    '3l9JDAU9FpS04P73nS8UfT629Xw1': {
      'uid': '3l9JDAU9FpS04P73nS8UfT629Xw1',
      'rol': 'admin',
      'nombre': 'Administrador Jefe',
      'email': 'admin@test.com',
    },
    // COACH (coach@test.com)
    'jxINtvli6aKDZGxBrPlvIX1Kh83': {
      'uid': 'jxINtvli6aKDZGxBrPlvIX1Kh83',
      'rol': 'entrenador',
      'nombre': 'Marcos Entrenador',
      'email': 'coach@test.com',
    },
    // CLIENTE (cliente@test.com)
    'G7crcmPusdQ9ukh5lKG7lUpaZUz1': {
      'uid': 'G7crcmPusdQ9ukh5lKG7lUpaZUz1',
      'rol': 'cliente',
      'nombre': 'Carlos Cliente',
      'email': 'cliente@test.com',
      'entrenador_id': 'jxINtvli6aKDZGxBrPlvIX1Kh83', // Vinculado a Marcos
    },
  };

  try {
    for (var entry in usuarios.entries) {
      await db.collection('usuarios').doc(entry.key).set(entry.value);
      print("✅ Usuario sincronizado: ${entry.value['nombre']}");
    }
    print("🚀 BASE DE DATOS REPARADA CON ÉXITO");
  } catch (e) {
    print("❌ ERROR AL REPARAR: $e");
  }
}
}