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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = "";
  String _filtroSexo = 'Todos';
  bool _filtroSoloPagados = false;
  RangeValues _filtroRangoEdad = const RangeValues(15, 80);

  @override
  void initState() {
    super.initState();
    // microtask para no llamar setState durante un build en curso
    _searchController.addListener(() {
      Future.microtask(() {
        if (mounted) setState(() => _searchQuery = _searchController.text.toLowerCase());
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // límite de clientes según el plan del coach
  int _obtenerLimiteClientes(String plan) {
    switch (plan.toLowerCase()) {
      case 'cantera': return 3;
      case 'rookie': return 15;
      case 'all-star': return 30;
      case 'hall of fame': return 999999;
      default: return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Error de usuario"));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // título y botón filtros fuera del StreamBuilder para no perder el foco
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis Clientes',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppTheme.secondaryOrange),
                onPressed: _mostrarPanelFiltros,
              ),
            ],
          ),
        ),

        // buscador fuera del StreamBuilder para mantener el foco al teclear
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: Colors.grey),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _searchFocus.requestFocus();
                      },
                      child: const Icon(CupertinoIcons.xmark_circle_fill, size: 16, color: Colors.grey),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // lista reactiva dentro de los StreamBuilders
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
            builder: (context, coachSnap) {
              final coachData = coachSnap.data?.data() as Map<String, dynamic>? ?? {};
              final planActual = coachData['plan_suscripcion'] ?? 'cantera';
              final limite = _obtenerLimiteClientes(planActual);

              return StreamBuilder<List<Cliente>>(
                stream: DatabaseService().getClientes(),
                builder: (context, clientesSnap) {
                  if (clientesSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  final todos = clientesSnap.data ?? [];
                  final total = todos.length;
                  final estaAlLimite = total >= limite;

                  final filtrados = todos.where((c) {
                    final matchNombre = c.nombre.toLowerCase().contains(_searchQuery) ||
                        c.apellidos.toLowerCase().contains(_searchQuery);
                    final matchSexo = _filtroSexo == 'Todos' || c.sexo == _filtroSexo;
                    final matchSuscripcion = !_filtroSoloPagados || c.estadoSuscripcionReal == 'activo';
                    final matchEdad = c.edad == 0 ||
                        (c.edad >= _filtroRangoEdad.start && c.edad <= _filtroRangoEdad.end);
                    return matchNombre && matchSexo && matchSuscripcion && matchEdad;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: Text(
                          "Plazas ocupadas: $total / ${limite == 999999 ? '∞' : limite} (Plan ${planActual.toString().toUpperCase()})",
                          style: TextStyle(
                            color: estaAlLimite ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: filtrados.isEmpty
                            ? const Center(child: Text("No hay clientes que mostrar."))
                            : ListView.builder(
                                itemCount: filtrados.length,
                                itemBuilder: (context, index) {
                                  final cliente = filtrados[index];
                                  // color del semáforo según el estado de suscripción
                                  Color colorSemaforo = Colors.red;
                                  if (cliente.estadoSuscripcionReal == 'activo') colorSemaforo = Colors.green;
                                  if (cliente.estadoSuscripcionReal == 'aviso') colorSemaforo = Colors.orange;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: AppTheme.mediumBlue,
                                        child: Icon(CupertinoIcons.person_fill, color: Colors.white),
                                      ),
                                      title: Text(
                                        "${cliente.nombre} ${cliente.apellidos}",
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text("Estado: ${cliente.estado}"),
                                      trailing: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorSemaforo,
                                        ),
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (_) => ClienteDetalleView(cliente: cliente),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
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
                  const Text("Filtros",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 20),
                  // filtro por sexo
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
                  // filtro por rango de edad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edad', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${_filtroRangoEdad.start.round()} – ${_filtroRangoEdad.end.round()} años',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryOrange),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _filtroRangoEdad,
                    min: 10,
                    max: 90,
                    divisions: 80,
                    activeColor: AppTheme.secondaryOrange,
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(
                      _filtroRangoEdad.start.round().toString(),
                      _filtroRangoEdad.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setModalState(() => _filtroRangoEdad = values);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  // filtro por cuota pagada
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Aplicar"),
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
}
