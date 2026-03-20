import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/models/cliente_model.dart';
import 'package:coach_os_app/models/ejercicio_model.dart';
import 'package:coach_os_app/models/mensaje_model.dart';
import 'package:coach_os_app/models/tarifa_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Stream<List<Cliente>> getClientes() {
    final String miUid = _auth.currentUser?.uid ?? "";

    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'Cliente')
        .where('entrenador_id', isEqualTo: miUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Cliente.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }
  Stream<List<Ejercicio>> getEjercicios() {
    return _db.collection('biblioteca_ejercicios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ejercicio.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // --- CHATS ---

  // 1. Leer los mensajes (Ahora dentro de la colección 'usuarios')
  Stream<List<Mensaje>> getMensajes(String clienteId) {
    return _db
        .collection('usuarios') // <--- CAMBIADO de 'clientes' a 'usuarios'
        .doc(clienteId)
        .collection('mensajes')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Mensaje.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

 // 2. Enviar mensaje (Ahora actualiza el documento en 'usuarios')
  Future<void> enviarMensaje(String clienteId, String texto, bool esEntrenador) async {
    final timestamp = FieldValue.serverTimestamp();

    // Guardamos en la subcolección del usuario
    await _db.collection('usuarios').doc(clienteId).collection('mensajes').add({
      'texto': texto,
      'esEntrenador': esEntrenador,
      'timestamp': timestamp,
    });

    // Actualizamos los campos de previsualización en el perfil del cliente
    await _db.collection('usuarios').doc(clienteId).update({
      'ultimo_mensaje': texto,
      'fecha_ultimo_mensaje': DateTime.now().toIso8601String(),
    });
  }

// --- TARIFAS ---
  Future<void> eliminarTarifa(String id) async {
    await _db.collection('tarifas').doc(id).delete();
  }

// Corrección en lib/services/database_service.dart
Future<void> crearTarifa(String nombre, int precio, String desc, int gracia, bool visible) async { // Quitamos el 'bool bool' raro
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  await _db.collection('tarifas').add({
    'nombre': nombre,
    'precio': precio,
    'descripcion': desc,
    'diasGracia': gracia, // Asegúrate de que en Firebase sea CamelCase
    'esVisible': visible, 
    'coachId': uid,
    'fecha_creacion': FieldValue.serverTimestamp(),
  });
}

// 2. Nueva función para cambiar la visibilidad desde la lista
Future<void> actualizarVisibilidadTarifa(String tarifaId, bool nuevaVisibilidad) async {
  await _db.collection('tarifas').doc(tarifaId).update({
    'esVisible': nuevaVisibilidad,
  });
}

// 3. Obtener tarifas: Asegúrate de filtrar por coachId
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

Future<void> actualizarPerfilAdmin({
  required String uid,
  required String nombre,
  required String descripcion,
  required String horarioInicio,
  required String horarioFin,
}) async {
  return await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
    'nombre': nombre,
    'descripcion': descripcion,
    'horarioInicio': horarioInicio,
    'horarioFin': horarioFin,
    'perfilCompletado': true,
  }, SetOptions(merge: true));
}

Future<void> inicializarUsuariosConIds() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // 1. GENERAR EL ADMIN
  // ID: 3l9JDlXLkPVxnsT3s16mpDfjlfU2
  await db.collection('usuarios').doc('3l9JDlXLkPVxnsT3s16mpDfjlfU2').set({
    'uid': '3l9JDlXLkPVxnsT3s16mpDfjlfU2',
    'rol': 'admin',
    'nombre': 'Administrador',
    'apellidos': 'CoachOS Global',
    'email': 'admin@coachos.com',
    'fecha_registro': FieldValue.serverTimestamp(),
  });

  // 2. GENERAR EL COACH (ENTRENADOR)
  // ID: D5nhvKpt2dTGdQ05LYKZvToWFIg1
  await db.collection('usuarios').doc('D5nhvKpt2dTGdQ05LYKZvToWFIg1').set({
    'uid': 'D5nhvKpt2dTGdQ05LYKZvToWFIg1',
    'rol': 'entrenador',
    'nombre': 'Marcos',
    'apellidos': 'Coach Principal',
    'email': 'coach@coachos.com',
    'suscripcion_activa': true,
    'plan': 'Premium',
    'fecha_registro': FieldValue.serverTimestamp(),
  });

  // 3. GENERAR EL CLIENTE VINCULADO AL COACH ANTERIOR
  // ID: NHTSqVeTsXNGVKPU6gWEaXAdM0z1
  await db.collection('usuarios').doc('NHTSqVeTsXNGVKPU6gWEaXAdM0z1').set({
    'uid': 'NHTSqVeTsXNGVKPU6gWEaXAdM0z1',
    'rol': 'Cliente', // Con C mayúscula como espera tu Stream
    'entrenador_id': 'D5nhvKpt2dTGdQ05LYKZvToWFIg1', // <--- Vínculo vital
    'nombre': 'Carlos',
    'apellidos': 'Cliente Test',
    'email': 'cliente@test.com',
    'cuota_pagada': true,
    'estado': 'Activo',
    'precio_tarifa': 50,
    'fecha_registro': FieldValue.serverTimestamp(),
  });

  print("✅ Usuarios inyectados con los UIDs proporcionados.");
}
}