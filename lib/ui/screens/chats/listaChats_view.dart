import 'package:coach_os_app/ui/screens/chats/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/database_service.dart';
import '../../../models/cliente_model.dart';
import '../../../config/theme.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  String _searchQueryChats = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABECERA
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chats', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.add_circled_solid, size: 30, color: AppTheme.secondaryOrange),
                onPressed: () => _mostrarModalNuevoChat(context),
              ),
            ],
          ),
        ),
        
        // BUSCADOR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CupertinoSearchTextField(
            placeholder: 'Buscar chat...',
            backgroundColor: Colors.white,
            onChanged: (value) => setState(() => _searchQueryChats = value.toLowerCase()),
          ),
        ),

        // LISTA
        Expanded(
          child: StreamBuilder<List<Cliente>>(
            stream: DatabaseService().getClientes(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEstadoVacio();

              // Filtramos limpiamente con isNotEmpty (Evita fallos de null)
              var clientesConChat = snapshot.data!.where((c) => c.ultimoMensaje.isNotEmpty).toList();
              
              if (_searchQueryChats.isNotEmpty) {
                clientesConChat = clientesConChat.where((c) => c.nombre.toLowerCase().contains(_searchQueryChats)).toList();
              }

              // Ordenamos limpiamente
              clientesConChat.sort((a, b) => b.fechaUltimoMensaje.compareTo(a.fechaUltimoMensaje));

              if (clientesConChat.isEmpty) return _buildEstadoVacio();

              return ListView.builder(
                itemCount: clientesConChat.length,
                itemBuilder: (context, index) {
                  final cliente = clientesConChat[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.mediumBlue,
                        child: Icon(CupertinoIcons.person_fill, color: Colors.white),
                      ),
                      title: Text("${cliente.nombre} ${cliente.apellidos}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(cliente.ultimoMensaje, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.push(context, CupertinoPageRoute(builder: (_) => ChatView(clienteId: cliente.id, nombreCliente: cliente.nombre)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.chat_bubble_2, size: 80, color: AppTheme.lightBlue),
          const SizedBox(height: 16),
          Text("No hay chats recientes", style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _mostrarModalNuevoChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightBlue,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Selecciona un cliente", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<Cliente>>(
                  stream: DatabaseService().getClientes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final clientes = snapshot.data!;
                    return ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (context, index) {
                        final cliente = clientes[index];
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: AppTheme.mediumBlue, child: Icon(CupertinoIcons.person_fill, color: Colors.white)),
                          title: Text("${cliente.nombre} ${cliente.apellidos}"),
                          onTap: () {
                            Navigator.pop(context); // Cierra modal
                            Navigator.push(context, CupertinoPageRoute(builder: (_) => ChatView(clienteId: cliente.id, nombreCliente: cliente.nombre)));
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}