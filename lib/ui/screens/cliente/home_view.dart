import 'package:coach_os_app/ui/screens/cliente/chatCliente/chatCliente.dart';
import 'package:coach_os_app/ui/screens/cliente/entrenoCliente/entreno_view.dart';
import 'package:coach_os_app/ui/screens/cliente/revisionesCliente/revision_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/ajustes_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dietaCliente/dieta_view.dart';
import '../../../config/theme.dart';
import 'principal_tab.dart'; 
class HomeViewCliente extends StatefulWidget {
  const HomeViewCliente({super.key});

  @override
  State<HomeViewCliente> createState() => _HomeViewClienteState();
}

class _HomeViewClienteState extends State<HomeViewCliente> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const PrincipalTab(), 
    const DietaCliente(),
    const EntrenoCliente(),
    const RevisionCliente(),
    const ChatCliente(),
    const AjustesView(rol: 'cliente'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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