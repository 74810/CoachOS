import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/coach/clienteDetalle/clienteDetalle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/cliente_model.dart';
import '../../../services/database_service.dart';

class ClientesView extends StatefulWidget {
  const ClientesView({super.key});

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  String _searchQuery = "";
  String _filtroSexo = 'Todos';
  bool _filtroSoloPagados = false;
  RangeValues _filtroRangoEdad = const RangeValues(15, 80);

  // --- 1. LÓGICA DE LÍMITES DE SUSCRIPCIÓN ---
  int _obtenerLimiteClientes(String plan) {
    switch (plan.toLowerCase()) {
      case 'cantera': return 3;
      case 'rookie': return 15;
      case 'all-star': return 30;
      case 'hall of fame': return 999999; // Representa Ilimitado
      default: return 3; // Ante la duda, aplicamos el plan gratis
    }
  }

  void _intentarAnadirCliente(BuildContext context, int clientesActuales, int limite) {
    if (clientesActuales >= limite) {
      // BLOQUEO: Ha llegado al límite
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Límite Alcanzado"),
          content: Text("Actualmente tienes $clientesActuales clientes, que es el límite de tu plan. Ve a 'Ajustes > Mi Plan' para mejorar tu suscripción y seguir creciendo."),
          actions: [
            CupertinoDialogAction(
              child: const Text("Entendido"),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text("Ver Planes", style: TextStyle(color: AppTheme.primaryBlue)),
              onPressed: () {
                Navigator.pop(context);
                // Aquí en el futuro puedes hacer un Navigator.push a la vista de planes
              },
            )
          ],
        )
      );
    } else {
      // PERMITIDO: Aún tiene espacio
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Aún tienes espacio para ${limite - clientesActuales} clientes más."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        )
      );
      // TODO: Aquí pondrás la navegación a tu futura pantalla de "Captar/Crear Cliente"
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Error de usuario"));

    // 1er Stream: Escuchamos el plan de suscripción del Coach
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
      builder: (context, coachSnapshot) {
        if (!coachSnapshot.hasData) return const Center(child: CupertinoActivityIndicator());
        
        final coachData = coachSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        // Lee el campo donde guardes su plan (ajusta el nombre si se llama diferente en Firebase)
        final planActual = coachData['plan_suscripcion'] ?? 'cantera'; 
        final limite = _obtenerLimiteClientes(planActual);

        // 2do Stream: Escuchamos cuántos clientes tiene asignados
        return StreamBuilder<List<Cliente>>(
          stream: DatabaseService().getClientes(),
          builder: (context, clientesSnapshot) {
            if (clientesSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
            
            final todosLosClientes = clientesSnapshot.data ?? [];
            final totalClientesActuales = todosLosClientes.length;
            final bool estaAlLimite = totalClientesActuales >= limite;

            // Filtros visuales de la lista
            final clientesFiltrados = todosLosClientes.where((c) {
              final matchNombre = c.nombre.toLowerCase().contains(_searchQuery) || c.apellidos.toLowerCase().contains(_searchQuery);
              final matchSexo = _filtroSexo == 'Todos' || c.sexo == _filtroSexo;
              final matchSuscripcion = !_filtroSoloPagados || c.estadoSuscripcionReal == 'activo';
              final matchEdad = c.edad == 0 || (c.edad >= _filtroRangoEdad.start && c.edad <= _filtroRangoEdad.end);
              return matchNombre && matchSexo && matchSuscripcion && matchEdad;
            }).toList();

            return Scaffold(
              backgroundColor: Colors.transparent, 
              
              // --- 2. EL BOTÓN FLOTANTE INTELIGENTE ---
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _intentarAnadirCliente(context, totalClientesActuales, limite),
                backgroundColor: estaAlLimite ? Colors.grey : AppTheme.primaryBlue,
                icon: Icon(estaAlLimite ? CupertinoIcons.lock_fill : CupertinoIcons.add, color: Colors.white),
                label: Text(
                  estaAlLimite ? "Límite Alcanzado" : "Añadir Cliente",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),

              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mis Clientes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        IconButton(icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppTheme.secondaryOrange), onPressed: _mostrarPanelFiltros),
                      ],
                    ),
                  ),
                  
                  // Contador visual sutil debajo del título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Plazas ocupadas: $totalClientesActuales / ${limite == 999999 ? '∞' : limite} (Plan ${planActual.toString().toUpperCase()})",
                      style: TextStyle(color: estaAlLimite ? Colors.red : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: CupertinoSearchTextField(
                      placeholder: 'Buscar por nombre...',
                      backgroundColor: Colors.white,
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    ),
                  ),
                  
                  Expanded(
                    child: clientesFiltrados.isEmpty 
                      ? const Center(child: Text("No hay clientes que mostrar."))
                      : ListView.builder(
                          itemCount: clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            Color colorSemaforo = Colors.red;
                            if (cliente.estadoSuscripcionReal == 'activo') colorSemaforo = Colors.green;
                            if (cliente.estadoSuscripcionReal == 'aviso') colorSemaforo = Colors.orange;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: AppTheme.mediumBlue, child: Icon(CupertinoIcons.person_fill, color: Colors.white)),
                                title: Text("${cliente.nombre} ${cliente.apellidos}", style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text("Estado: ${cliente.estado}"),
                                trailing: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: colorSemaforo)),
                                onTap: () {
                                  Navigator.push(context, CupertinoPageRoute(builder: (context) => ClienteDetalleView(cliente: cliente)));
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarPanelFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightBlue,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Filtros", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSegmentedControl<String>(
                      groupValue: _filtroSexo,
                      selectedColor: AppTheme.primaryBlue,
                      borderColor: AppTheme.primaryBlue,
                      unselectedColor: Colors.white,
                      children: const {
                        'Todos': Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Todos')),
                        'Hombre': Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Hombres')),
                        'Mujer': Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Mujeres')),
                      },
                      onValueChanged: (val) {
                        setModalState(() => _filtroSexo = val);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  RangeSlider(
                    values: _filtroRangoEdad,
                    min: 10, max: 90, divisions: 80,
                    activeColor: AppTheme.secondaryOrange,
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(_filtroRangoEdad.start.round().toString(), _filtroRangoEdad.end.round().toString()),
                    onChanged: (values) {
                      setModalState(() => _filtroRangoEdad = values);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Solo cuota pagada", style: TextStyle(fontWeight: FontWeight.w600)),
                      CupertinoSwitch(
                        value: _filtroSoloPagados,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) {
                          setModalState(() => _filtroSoloPagados = val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Aplicar")))
                ],
              ),
            );
          }
        );
      }
    );
  }
}