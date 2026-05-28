import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/chat_service.dart';
import '../../../../models/mensaje_model.dart';
import '../../../../config/theme.dart';
import '../perfilUsuario_view.dart';

class ChatView extends StatefulWidget {
  final String receptorId;
  final String nombreReceptor;
  final bool esPantallaCompleta;

  const ChatView({
    super.key, 
    required this.receptorId, 
    required this.nombreReceptor,
    this.esPantallaCompleta = true,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _mensajeController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _miUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    _mensajeController.clear();

    try {
      await _chatService.enviarMensaje(widget.receptorId, texto);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esPantallaCompleta) {
      return _buildCuerpoChat();
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context, 
              CupertinoPageRoute(builder: (context) => PerfilUsuarioView(uid: widget.receptorId))
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.nombreReceptor, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.info_circle_fill, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _buildCuerpoChat(),
      ),
    );
  }

  Widget _buildCuerpoChat() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Mensaje>>(
            stream: _chatService.obtenerMensajes(widget.receptorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              
              final mensajes = snapshot.data ?? [];
              
              if (mensajes.isEmpty) {
                return const Center(
                  child: Text("Escribe el primer mensaje...", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {
                  final msg = mensajes[index];
                  bool esMio = msg.emisorId == _miUid;
                  return _buildBurbuja(msg.texto, esMio);
                },
              );
            },
          ),
        ),
        
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            // padding extra para el indicador home en modo embebido
            widget.esPantallaCompleta
                ? 10
                : 10 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _mensajeController,
                  placeholder: "Escribe un mensaje...",
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue, 
                    borderRadius: BorderRadius.circular(25)
                  ),
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _enviarMensaje,
                child: const Icon(
                  CupertinoIcons.arrow_up_circle_fill, 
                  size: 40, 
                  color: AppTheme.secondaryOrange
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBurbuja(String texto, bool esMio) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: esMio ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(esMio ? 18 : 0),
            bottomRight: Radius.circular(esMio ? 0 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        child: Text(
          texto,
          style: TextStyle(color: esMio ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }
}