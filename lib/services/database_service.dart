import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/models/cliente_model.dart';
import 'package:coach_os_app/models/tarifa_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // clientes vinculados al coach autenticado
  Stream<List<Cliente>> getClientes() {
    final String miUid = _auth.currentUser?.uid ?? "";
    return _db
        .collection('usuarios')
        .where('entrenador_id', isEqualTo: miUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Cliente.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // gestión de tarifas
  Future<void> eliminarTarifa(String id) async {
    await _db.collection('tarifas').doc(id).delete();
  }

  Future<void> actualizarTarifa(String id, String nombre, int precio, String desc, int gracia) async {
    await _db.collection('tarifas').doc(id).update({
      'nombre': nombre,
      'precio': precio,
      'descripcion': desc,
      'diasGracia': gracia,
    });
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

  Future<void> actualizarVisibilidadTarifa(String tarifaId, bool nuevaVisibilidad) async {
    await _db.collection('tarifas').doc(tarifaId).update({'esVisible': nuevaVisibilidad});
  }

  // solo tarifas del coach autenticado
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

  // entrenadores activos visibles para el onboarding del cliente
  Stream<List<Map<String, dynamic>>> getEntrenadoresActivos() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'entrenador')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // leads vinculados al coach autenticado
  Stream<List<Map<String, dynamic>>> getLeads() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'cliente')
        .where('estado_onboarding', isEqualTo: 'lead')
        .where('entrenador_id', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // tarifas visibles de un coach concreto para su perfil público
  Stream<List<Tarifa>> getTarifasVisiblesDeCoach(String coachId) {
    return _db
        .collection('tarifas')
        .where('coachId', isEqualTo: coachId)
        .where('esVisible', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Tarifa.fromFirestore(d.data(), d.id))
            .toList());
  }

  // activa un lead asignándole tarifa y marcando cuota como pagada
  Future<void> activarClienteConTarifa({
    required String clienteId,
    required String coachId,
    required String nombreTarifa,
    required int precioTarifa,
    int diasGracia = 3,
  }) async {
    await _db.collection('usuarios').doc(clienteId).update({
      'estado_onboarding': 'activo',
      'entrenador_id': coachId,
      'tipo_tarifa': nombreTarifa,
      'precio_tarifa': precioTarifa,
      'dias_gracia': diasGracia,
      'cuota_pagada': true,
      'fecha_ultimo_pago': FieldValue.serverTimestamp(),
    });
  }

  // crea el documento inicial del cliente tras su registro
  Future<void> crearDocumentoCliente({
    required String uid,
    required String nombre,
    required String email,
    String? entrenadorId,
  }) async {
    await _db.collection('usuarios').doc(uid).set({
      'nombre': nombre,
      'apellidos': '',
      'email': email,
      'rol': 'cliente',
      'estado_onboarding': 'lead',
      'entrenador_id': entrenadorId,
      'edad': 0,
      'telefono': '',
      'sexo': '',
      'lesiones_previas': '',
      'patologias': '',
      'cuota_pagada': false,
      'precio_tarifa': 0,
      'tipo_tarifa': '',
      'fecha_creacion': FieldValue.serverTimestamp(),
    });
  }

  // métodos exclusivos del administrador

  Stream<List<Map<String, dynamic>>> adminGetEntrenadores() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'entrenador')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> adminGetClientes() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'cliente')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> adminActualizarSuscripcionCoach({
    required String coachId,
    required bool activa,
    required String plan,
    required DateTime fechaFin,
  }) async {
    await _db.collection('usuarios').doc(coachId).update({
      'subscripcion_activa': activa,
      'plan_suscripcion': plan,
      'fecha_fin_plan': Timestamp.fromDate(fechaFin),
    });
  }

  Future<void> adminActualizarPagoCliente({
    required String clienteId,
    required bool cuotaPagada,
  }) async {
    final data = <String, dynamic>{'cuota_pagada': cuotaPagada};
    if (cuotaPagada) data['fecha_ultimo_pago'] = FieldValue.serverTimestamp();
    await _db.collection('usuarios').doc(clienteId).update(data);
  }

  Future<void> adminActualizarCampos(String uid, Map<String, dynamic> campos) async {
    await _db.collection('usuarios').doc(uid).update(campos);
  }

  // actualiza datos profesionales del coach
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
