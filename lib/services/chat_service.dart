import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/models/mensaje_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _miId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // id único ordenando los dos uids alfabéticamente
  String _generarChatId(String id1, String id2) {
    List<String> ids = [id1, id2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> enviarMensaje(String receptorId, String texto) async {
    if (texto.trim().isEmpty || _miId.isEmpty) return;

    // si el emisor es un lead sin coach asignado, lo vincula automáticamente
    try {
      final miDoc = await _db.collection('usuarios').doc(_miId).get();
      final miData = miDoc.data() ?? {};
      if (miData['rol'] == 'cliente' &&
          miData['estado_onboarding'] == 'lead' &&
          (miData['entrenador_id'] == null || miData['entrenador_id'] == '')) {
        final receptorDoc = await _db.collection('usuarios').doc(receptorId).get();
        if (receptorDoc.data()?['rol'] == 'entrenador') {
          await _db.collection('usuarios').doc(_miId).update({'entrenador_id': receptorId});
        }
      }
    } catch (_) {}

    String chatId = _generarChatId(_miId, receptorId);

    // guarda el mensaje en la subcolección
    await _db.collection('chats').doc(chatId).collection('mensajes').add({
      'emisor_id': _miId,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(),
    });

    // actualiza metadatos del chat para el preview de la bandeja
    await _db.collection('chats').doc(chatId).set({
      'usuarios': [_miId, receptorId],
      'ultimo_mensaje': texto,
      'fecha': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // propaga el último mensaje a los perfiles de ambos usuarios
    Map<String, dynamic> datosUltimoMensaje = {
      'ultimo_mensaje': texto,
      'fecha_ultimo_mensaje': FieldValue.serverTimestamp(),
    };
    await _db.collection('usuarios').doc(_miId).set(datosUltimoMensaje, SetOptions(merge: true));
    await _db.collection('usuarios').doc(receptorId).set(datosUltimoMensaje, SetOptions(merge: true));
  }

  // stream de mensajes ordenados cronológicamente
  Stream<List<Mensaje>> obtenerMensajes(String otroUsuarioId) {
    String chatId = _generarChatId(_miId, otroUsuarioId);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Mensaje.fromFirestore(doc)).toList());
  }
}
