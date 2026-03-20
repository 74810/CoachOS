import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/database_service.dart';
import '../../../models/mensaje_model.dart';
import '../../../config/theme.dart';

class ChatView extends StatefulWidget {
  final String clienteId;
  final String nombreCliente;
  final bool esPantallaCompleta; // 🔥 LA VARIABLE MÁGICA

  const ChatView({
    super.key, 
    required this.clienteId, 
    required this.nombreCliente,
    this.esPantallaCompleta = true, // Por defecto es true para que funcione en la lista de chats
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _mensajeController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;
    _mensajeController.clear();
    await _dbService.enviarMensaje(widget.clienteId, texto, true);
  }

  @override
  Widget build(BuildContext context) {
    // Si no es pantalla completa no muestra el Scaffold con AppBar
    if (!widget.esPantallaCompleta) {
      return _buildCuerpoChat();
    }

    // Si es pantalla completa (desde la lista de chats), muestra el Scaffold normal con su AppBar
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.nombreCliente, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _buildCuerpoChat(),
      ),
    );
  }

  //cuerpo en un widget aparte para reutilizarlo en ambos casos
  Widget _buildCuerpoChat() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Mensaje>>(
            stream: _dbService.getMensajes(widget.clienteId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("Empieza la conversación", style: TextStyle(color: Colors.grey)),
                );
              }
              
              final mensajes = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {
                  final msg = mensajes[index];
                  final esMio = msg.esEntrenador;

                  return Align(
                    alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: esMio ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(esMio ? 16 : 0),
                          bottomRight: Radius.circular(esMio ? 0 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                        ]
                      ),
                      child: Text(
                        msg.texto,
                        style: TextStyle(color: esMio ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // ZONA DE ESCRIBIR MENSAJE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _mensajeController,
                  placeholder: "Escribe un mensaje...",
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(20)),
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _enviarMensaje,
                child: const Icon(CupertinoIcons.arrow_up_circle_fill, size: 36, color: AppTheme.secondaryOrange),
              ),
            ],
          ),
        ),
      ],
    );
  }
}