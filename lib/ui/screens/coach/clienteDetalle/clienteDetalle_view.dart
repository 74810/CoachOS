import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_os_app/ui/screens/coach/clienteDetalle/tabs/revision_tab.dart';
import 'package:coach_os_app/ui/screens/compartidos/perfilUsuario_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/cliente_model.dart';
import '../../../../config/theme.dart';
import 'tabs/perfil_tab.dart';
import 'tabs/entreno_tab.dart';
import 'tabs/dieta_tab.dart';
import '../../compartidos/chats/chat_view.dart';

class ClienteDetalleView extends StatefulWidget {
  final Cliente cliente;
  const ClienteDetalleView({super.key, required this.cliente});

  @override
  State<ClienteDetalleView> createState() => _ClienteDetalleViewState();
}

class _ClienteDetalleViewState extends State<ClienteDetalleView> {
  int _indiceSeleccionado = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => PerfilUsuarioView(uid: widget.cliente.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.mediumBlue,
                        child: Icon(CupertinoIcons.person_fill, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.cliente.nombre,
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(CupertinoIcons.info_circle_fill, size: 18, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // semáforo actualizado en tiempo real desde Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(widget.cliente.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildSemaforo(widget.cliente.estadoSuscripcionReal);
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final clienteActualizado = Cliente.fromFirestore(data, widget.cliente.id);
                return _buildSemaforo(clienteActualizado.estadoSuscripcionReal);
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: (index) => setState(() => _indiceSeleccionado = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.secondaryOrange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_solid), label: 'Perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Entreno'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Dieta'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_chart_fill), label: 'Revisión'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2_fill), label: 'Chat'),
        ],
      ),
      body: SafeArea(child: _construirCuerpoPestana()),
    );
  }

  Widget _construirCuerpoPestana() {
    switch (_indiceSeleccionado) {
      case 0: return PerfilTab(cliente: widget.cliente);
      case 1: return EntrenoTab(cliente: widget.cliente);
      case 2: return DietaTab(cliente: widget.cliente);
      case 3: return RevisionTab(cliente: widget.cliente);
      case 4: return ChatView(
        receptorId: widget.cliente.id,
        nombreReceptor: widget.cliente.nombre,
        esPantallaCompleta: false,
      );
      default: return PerfilTab(cliente: widget.cliente);
    }
  }

  Widget _buildSemaforo(String estado) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LuzSemaforo(color: Colors.green, encendida: estado == 'activo'),
        const SizedBox(width: 4),
        _LuzSemaforo(color: Colors.orange, encendida: estado == 'aviso'),
        const SizedBox(width: 4),
        _LuzSemaforo(color: Colors.red, encendida: estado == 'inactivo'),
      ],
    );
  }
}

// indicador circular del semáforo de suscripción
class _LuzSemaforo extends StatelessWidget {
  final Color color;
  final bool encendida;
  const _LuzSemaforo({required this.color, required this.encendida});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: encendida ? color : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: encendida
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
            : null,
      ),
    );
  }
}
