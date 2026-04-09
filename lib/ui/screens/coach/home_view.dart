import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/compartidos/ajustes/ajustes_view.dart';
import 'package:coach_os_app/ui/screens/compartidos/chats/listaChats_view.dart';
import 'package:coach_os_app/ui/screens/coach/miDespacho/miDespacho_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:coach_os_app/ui/screens/coach/clientes_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _indiceSeleccionado = 0;

  // Guardamos las pantallas en memoria
  final List<Widget> _pantallas = [
    const ClientesView(),
    const DespachoView(),
    const ChatsView(),
    const AjustesView(rol: 'entrenador'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: (index) => setState(() => _indiceSeleccionado = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.group_solid), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.briefcase_fill), label: 'Despacho'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_2_fill), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings_solid), label: 'Ajustes'),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _indiceSeleccionado,
          children: _pantallas,
        ),
      ),
    );
  }
}