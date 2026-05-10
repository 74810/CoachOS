import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/models/cliente_model.dart';
import 'package:coach_os_app/models/tarifa_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtiene la lista de clientes que pertenecen específicamente al coach logueado
  Stream<List<Cliente>> getClientes() {
    final String miUid = _auth.currentUser?.uid ?? "";

    return _db
        .collection('usuarios')
        .where('entrenador_id', isEqualTo: miUid) // Filtro para que el coach solo vea sus clientes
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Cliente.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }
  // Stream<List<Ejercicio>> getEjercicios() {
  //   return _db.collection('biblioteca_ejercicios').snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       return Ejercicio.fromFirestore(doc.data(), doc.id);
  //     }).toList();
  //   });
  // }

  //GESTIÓN DE TARIFAS
  Future<void> eliminarTarifa(String id) async {
    await _db.collection('tarifas').doc(id).delete();
  }

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

  // Cambio visibilidad tarifa
  Future<void> actualizarVisibilidadTarifa(String tarifaId, bool nuevaVisibilidad) async {
    await _db.collection('tarifas').doc(tarifaId).update({
      'esVisible': nuevaVisibilidad,
    });
  }

  // Obtiene solo las tarifas que ha creado el coach que está usando la app
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

  //PERFIL Y CONFIGURACIÓN
  // Actualizo los datos profesionales del coach 
  Future<void> actualizarPerfil({
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
}
