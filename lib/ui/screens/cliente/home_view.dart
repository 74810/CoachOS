import 'package:coach_os_app/ui/screens/cliente/chatCliente.dart';
import 'package:coach_os_app/ui/screens/cliente/entreno_view.dart';
import 'package:coach_os_app/ui/screens/cliente/revision_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/ajustes_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dieta_view.dart';
import '../../../config/theme.dart';
import 'principal_view.dart'; 

class HomeViewCliente extends StatefulWidget {
  const HomeViewCliente({super.key});

  // Controlador mágico para cambiar de tab desde cualquier pantalla hija
  static _HomeViewClienteState of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeViewClienteState>()!;
  }

  @override
  State<HomeViewCliente> createState() => _HomeViewClienteState();
}

class _HomeViewClienteState extends State<HomeViewCliente> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const PrincipalView(), 
    const DietaCliente(),
    const EntrenoCliente(),
    const RevisionCliente(),
    const ChatCliente(),
    const AjustesView(rol: 'cliente'),
  ];

  // Función para mover la pestaña (Llamada desde principal_view)
  void cambiarTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => cambiarTab(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.news), label: 'Dieta'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.flame), label: 'Entreno'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.graph_square), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}