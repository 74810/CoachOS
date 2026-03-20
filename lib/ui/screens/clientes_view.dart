import 'package:coach_os_app/config/theme.dart';
import 'package:coach_os_app/ui/screens/cliente_detalle/clienteDetalle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/cliente_model.dart';
import '../../services/database_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis Clientes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppTheme.secondaryOrange),
                onPressed: _mostrarPanelFiltros,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CupertinoSearchTextField(
            placeholder: 'Buscar por nombre...',
            backgroundColor: Colors.white,
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Cliente>>(
            stream: DatabaseService().getClientes(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay clientes registrados."));
              }

              // Aplicar filtros
              final clientes = snapshot.data!.where((c) {
                final matchNombre = c.nombre.toLowerCase().contains(_searchQuery) || 
                                    c.apellidos.toLowerCase().contains(_searchQuery);
                final matchSexo = _filtroSexo == 'Todos' || c.sexo == _filtroSexo;
                final matchSuscripcion = !_filtroSoloPagados || c.cuotaPagada == true;
                final matchEdad = c.edad >= _filtroRangoEdad.start && c.edad <= _filtroRangoEdad.end;

                return matchNombre && matchSexo && matchSuscripcion && matchEdad;
              }).toList();

              return ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
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
                      title: Text("${cliente.nombre} ${cliente.apellidos}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Estado: ${cliente.estado}"),
                      trailing: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cliente.cuotaPagada ? Colors.green : AppTheme.secondaryOrange,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context, 
                          CupertinoPageRoute(
                            builder: (context) => ClienteDetalleView(cliente: cliente),
                          ),
                        );
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Aplicar"),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}