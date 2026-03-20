import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/cliente_model.dart';
import '../../../config/theme.dart';
import 'tabs/perfil_tab.dart';
import 'tabs/entreno_tab.dart';
import 'tabs/dieta_tab.dart';
import '../chats/chat_view.dart'; 

class ClienteDetalleView extends StatefulWidget {
  final Cliente cliente;

  const ClienteDetalleView({super.key, required this.cliente});

  @override
  State<ClienteDetalleView> createState() => _ClienteDetalleViewState();
}

class _ClienteDetalleViewState extends State<ClienteDetalleView> {
  int _indiceSeleccionado = 0; // 0: Perfil, 1: Entreno, 2: Dieta, 3: Revisión, 4: Chat

String get _estadoSuscripcion {
    if (widget.cliente.cuotaPagada) return 'activo';

    try {
      if (widget.cliente.fechaUltimoMensaje.isEmpty) return 'inactivo';

      DateTime fechaCaducidad = DateTime.parse(widget.cliente.fechaUltimoMensaje);
      final diasDesdeCaducidad = DateTime.now().difference(fechaCaducidad).inDays;

      // 🔥 USAMOS LOS DÍAS DE GRACIA REALES (suponiendo que lo añadimos al modelo Cliente)
      // Si no, podemos usar un valor que el entrenador configure en "Ajustes"
      int margenEntrenador = 3; // Aquí leeríamos de la tarifa del cliente

      if (diasDesdeCaducidad <= margenEntrenador) {
        return 'aviso'; // NARANJA
      } else {
        return 'inactivo'; // ROJO
      }
    } catch (e) {
      return 'inactivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      
      // 1. CABECERA PERSONALIZADA CON SEMÁFORO
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
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.mediumBlue,
              child: Icon(CupertinoIcons.person_fill, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.cliente.nombre,
                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildSemaforo(_estadoSuscripcion),
            const SizedBox(width: 16),
          ],
        ),
      ),
      
      // 2. MENÚ INFERIOR (Sub-navegación del cliente)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: (index) => setState(() => _indiceSeleccionado = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
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

      // 3. CUERPO PRINCIPAL (Cambia según la pestaña elegida)
      body: SafeArea(
        child: _construirCuerpoPestana(),
      ),
    );
  }

  // --- CONTROLADOR DE PESTAÑAS ---
  Widget _construirCuerpoPestana() {
    switch (_indiceSeleccionado) {
      case 0: return PerfilTab(cliente: widget.cliente);
      case 1: return EntrenoTab(cliente: widget.cliente);
      case 2: return DietaTab(cliente: widget.cliente);
      case 3: return const Center(child: Text("Módulo de Revisiones en construcción", style: TextStyle(color: Colors.grey)));
      case 4: return ChatView(clienteId: widget.cliente.id, nombreCliente: widget.cliente.nombre, esPantallaCompleta: false);
      default: return PerfilTab(cliente: widget.cliente);
    }
  }

  // --- WIDGET DEL SEMÁFORO DE SUSCRIPCIÓN ---
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
        boxShadow: encendida ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)] : null,
      ),
    );
  }
}