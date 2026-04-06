import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/models/mensaje_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _miId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Crea un ID único combinando ambos IDs en orden alfabético
  String _generarChatId(String id1, String id2) {
    List<String> ids = [id1, id2];
    ids.sort(); 
    return ids.join('_');
  }

  // ENVIAR MENSAJE
  Future<void> enviarMensaje(String receptorId, String texto) async {
    if (texto.trim().isEmpty || _miId.isEmpty) return;

    String chatId = _generarChatId(_miId, receptorId);

    // 1. Guardar el mensaje en la colección global de chats
    await _db.collection('chats').doc(chatId).collection('mensajes').add({
      'emisor_id': _miId,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(),
    });

    // 2. Actualizar el documento padre del chat
    await _db.collection('chats').doc(chatId).set({
      'usuarios': [_miId, receptorId],
      'ultimo_mensaje': texto,
      'fecha': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. CRÍTICO: Guardar en los perfiles usando FieldValue.serverTimestamp()
    Map<String, dynamic> datosUltimoMensaje = {
      'ultimo_mensaje': texto,
      // CAMBIO AQUÍ: Usamos el timestamp nativo de Firebase en lugar de un String ISO
      'fecha_ultimo_mensaje': FieldValue.serverTimestamp(), 
    };

    await _db.collection('usuarios').doc(_miId).set(datosUltimoMensaje, SetOptions(merge: true));
    await _db.collection('usuarios').doc(receptorId).set(datosUltimoMensaje, SetOptions(merge: true));
  }

  // RECIBIR MENSAJES (Stream en tiempo real)
  Stream<List<Mensaje>> obtenerMensajes(String otroUsuarioId) {
    String chatId = _generarChatId(_miId, otroUsuarioId);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('fecha', descending: true) // True para que salgan abajo los nuevos
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Mensaje.fromFirestore(doc)).toList());
  }
}