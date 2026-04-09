import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/chat_service.dart';
import '../../../../models/mensaje_model.dart';
import '../../../../config/theme.dart';

// IMPORTANTE: Añadimos la importación absoluta del perfil para que no falle
import 'package:coach_os_app/ui/screens/compartidos/perfilUsuario_view.dart';

class ChatCliente extends StatefulWidget {
  const ChatCliente({super.key});

  @override
  State<ChatCliente> createState() => _ChatClienteViewState();
}

class _ChatClienteViewState extends State<ChatCliente> {
  final TextEditingController _mensajeController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String _miUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  String? _entrenadorId;
  String _nombreEntrenador = "Cargando...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosEntrenador();
  }

  // --- LÓGICA EXCLUSIVA DEL CLIENTE: BUSCAR A SU ENTRENADOR ---
  Future<void> _cargarDatosEntrenador() async {
    if (_miUid.isEmpty) return;

    try {
      final miDoc = await FirebaseFirestore.instance.collection('usuarios').doc(_miUid).get();
      
      if (miDoc.exists && miDoc.data()!.containsKey('entrenador_id')) {
        final coachId = miDoc.data()!['entrenador_id'];

        final coachDoc = await FirebaseFirestore.instance.collection('usuarios').doc(coachId).get();
        String nombre = "Tu Entrenador";
        
        if (coachDoc.exists) {
          nombre = coachDoc.data()?['nombre'] ?? "Tu Entrenador";
        }

        setState(() {
          _entrenadorId = coachId;
          _nombreEntrenador = nombre;
          _isLoading = false;
        });
      } else {
        setState(() {
          _nombreEntrenador = "Sin entrenador asignado";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _nombreEntrenador = "Error de conexión";
        _isLoading = false;
      });
      print("Error cargando entrenador: $e");
    }
  }

  // --- ENVIAR MENSAJE ---
  void _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _entrenadorId == null) return;

    _mensajeController.clear();

    try {
      await _chatService.enviarMensaje(_entrenadorId!, texto);
    } catch (e) {
      print("LOG: Error crítico al enviar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        // AHORA EL TÍTULO ES IDÉNTICO AL DEL COACH Y CLICABLE
        title: GestureDetector(
          onTap: () {
            // Si el cliente tiene entrenador, le abrimos su perfil
            if (_entrenadorId != null) {
              Navigator.push(
                context, 
                CupertinoPageRoute(builder: (context) => PerfilUsuarioView(uid: _entrenadorId!))
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _nombreEntrenador, 
                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)
              ),
              const SizedBox(width: 6),
              // Icono gris para indicar que se puede hacer clic
              if (_entrenadorId != null)
                const Icon(CupertinoIcons.info_circle_fill, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CupertinoActivityIndicator()) 
            : _entrenadorId == null 
                ? _buildPantallaSinEntrenador()
                : _buildCuerpoChat(),
      ),
    );
  }

  // --- CUERPO DEL CHAT ---
  Widget _buildCuerpoChat() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Mensaje>>(
            stream: _chatService.obtenerMensajes(_entrenadorId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              
              final mensajes = snapshot.data ?? [];
              
              if (mensajes.isEmpty) {
                return const Center(
                  child: Text("Escribe el primer mensaje a tu entrenador...", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                reverse: true, // Empieza desde abajo
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
        
        // --- INPUT DE TEXTO ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  // --- BURBUJAS DE MENSAJE ---
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

  // --- VISTA POR SI EL CLIENTE AÚN NO TIENE COACH ---
  Widget _buildPantallaSinEntrenador() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("No tienes un entrenador asignado", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}