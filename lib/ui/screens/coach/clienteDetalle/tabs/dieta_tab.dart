import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart'; 
import '../../../../../models/dieta_model.dart';   
import '../../../../../config/theme.dart';         

class DietaTab extends StatelessWidget {
  final Cliente cliente;
  const DietaTab({super.key, required this.cliente});

  void _abrirConfigurador(BuildContext context, {Dieta? dietaExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ModalNuevaDietaCliente(cliente: cliente, dietaEdit: dietaExistente),
    );
  }

  void _borrarDieta(BuildContext context, String dietaId) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text("¿Borrar dieta?"),
        content: const Text("Esta acción eliminará la dieta del cliente."),
        actions: [
          CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).collection('dietas').doc(dietaId).delete();
            },
            child: const Text("Borrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cliente.id)
          .collection('dietas')
          .orderBy('fecha_creacion', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
        
        final dietas = snapshot.data?.docs.map((doc) => Dieta.fromFirestore(doc)).toList() ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DIETAS ASIGNADAS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _abrirConfigurador(context),
                  child: const Text("+ Nueva Dieta", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (dietas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text("El cliente no tiene dietas asignadas", style: TextStyle(color: Colors.grey))),
              ),
            ...dietas.map((d) => _buildCardDieta(context, d)).toList(),
          ],
        );
      },
    );
  }

  // --- TARJETA CORREGIDA CON EXPANSION TILE ---
  Widget _buildCardDieta(BuildContext context, Dieta dieta) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(dieta.tipo == 'macros' ? Icons.pie_chart : Icons.restaurant_menu, color: Colors.green, size: 20),
        ),
        title: Text(dieta.titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        subtitle: Text("Tipo: ${dieta.tipo.toUpperCase()}", style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _abrirConfigurador(context, dietaExistente: dieta)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _borrarDieta(context, dieta.id)),
            const Icon(Icons.expand_more, color: Colors.grey),
          ],
        ),
        children: [
          // Mostrar Notas Generales si existen
          if (dieta.notasGenerales.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("Nota: ${dieta.notasGenerales}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ),

          // MOSTRAR CONTENIDO SEGÚN EL TIPO
          if (dieta.tipo == 'macros') 
            _buildDetalleMacros(dieta)
          else 
            _buildDetalleComidas(dieta),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Vista rápida de Macros para el entrenador
  Widget _buildDetalleMacros(Dieta dieta) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _macroDato("Kcal", "${dieta.kcal ?? 0}"),
          _macroDato("P", "${dieta.proteina ?? 0}g"),
          _macroDato("C", "${dieta.carbos ?? 0}g"),
          _macroDato("G", "${dieta.grasas ?? 0}g"),
        ],
      ),
    );
  }

  Widget _macroDato(String etiqueta, String valor) {
    return Column(
      children: [
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue)),
        Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // Vista rápida de Comidas para el entrenador
  Widget _buildDetalleComidas(Dieta dieta) {
    if (dieta.comidas == null) return const SizedBox();
    return Column(
      children: dieta.comidas!.map((comida) => ListTile(
        dense: true,
        title: Text(comida.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        subtitle: Text(comida.elementos.join(", "), maxLines: 2, overflow: TextOverflow.ellipsis),
      )).toList(),
    );
  }
}

// --- CLASE AUXILIAR PARA EL FORMULARIO ---
class _ComidaController {
  TextEditingController nombreCtrl;
  TextEditingController elementosCtrl;
  _ComidaController(this.nombreCtrl, this.elementosCtrl);
}

// --- EL MODAL (SE MANTIENE IGUAL QUE EL ANTERIOR) ---
class _ModalNuevaDietaCliente extends StatefulWidget {
  final Cliente cliente;
  final Dieta? dietaEdit;
  const _ModalNuevaDietaCliente({required this.cliente, this.dietaEdit});

  @override
  State<_ModalNuevaDietaCliente> createState() => _ModalNuevaDietaClienteState();
}

class _ModalNuevaDietaClienteState extends State<_ModalNuevaDietaCliente> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  String _tipoSeleccionado = 'cerrada'; 

  final TextEditingController _kcalController = TextEditingController();
  final TextEditingController _proController = TextEditingController();
  final TextEditingController _carbosController = TextEditingController();
  final TextEditingController _grasasController = TextEditingController();

  List<_ComidaController> _comidasControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.dietaEdit != null) {
      _cargarDatosEnFormulario(widget.dietaEdit!);
    }
  }

  void _cargarDatosEnFormulario(Dieta p) {
    _tituloController.text = p.titulo;
    _notasController.text = p.notasGenerales;
    _tipoSeleccionado = p.tipo;

    if (p.tipo == 'macros') {
      _kcalController.text = p.kcal?.toString() ?? '';
      _proController.text = p.proteina?.toString() ?? '';
      _carbosController.text = p.carbos?.toString() ?? '';
      _grasasController.text = p.grasas?.toString() ?? '';
    } else {
      if (p.comidas != null) {
        _comidasControllers = p.comidas!.map((c) => _ComidaController(
          TextEditingController(text: c.nombre),
          TextEditingController(text: c.elementos.join('\n')),
        )).toList();
      }
    }
  }

  void _abrirSelectorBiblioteca() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Importar de mi Biblioteca", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .collection('biblioteca_dietas')
                      .orderBy('fecha_creacion', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return const Center(child: Text("No tienes plantillas guardadas."));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final dietaPlantilla = Dieta.fromFirestore(docs[index]);
                        return ListTile(
                          leading: const Icon(Icons.file_download, color: Colors.green),
                          title: Text(dietaPlantilla.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(dietaPlantilla.tipo),
                          onTap: () {
                            setState(() {
                              _cargarDatosEnFormulario(dietaPlantilla);
                            });
                            Navigator.pop(context);
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

  Future<void> _guardarEnCliente() async {
    if (_tituloController.text.isEmpty) return;

    List<Comida>? comidasFinales;
    if (_tipoSeleccionado != 'macros') {
      comidasFinales = _comidasControllers.map((c) {
        List<String> items = c.elementosCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList();
        return Comida(nombre: c.nombreCtrl.text, elementos: items);
      }).toList();
    }

    final data = {
      'titulo': _tituloController.text,
      'tipo': _tipoSeleccionado,
      'notas_generales': _notasController.text,
      'kcal': _tipoSeleccionado == 'macros' ? int.tryParse(_kcalController.text) : null,
      'proteina': _tipoSeleccionado == 'macros' ? int.tryParse(_proController.text) : null,
      'carbos': _tipoSeleccionado == 'macros' ? int.tryParse(_carbosController.text) : null,
      'grasas': _tipoSeleccionado == 'macros' ? int.tryParse(_grasasController.text) : null,
      'comidas': comidasFinales?.map((c) => c.toMap()).toList(),
      'fecha_creacion': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.dietaEdit != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(widget.cliente.id).collection('dietas').doc(widget.dietaEdit!.id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('usuarios').doc(widget.cliente.id).collection('dietas').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error guardando dieta al cliente: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.dietaEdit != null ? "Editar Dieta" : "Nueva Dieta", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          
          if (widget.dietaEdit == null) ...[
            const SizedBox(height: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _abrirSelectorBiblioteca,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3))
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text("Importar de mi Biblioteca", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Nombre de la dieta")),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSegmentedControl<String>(
              groupValue: _tipoSeleccionado,
              selectedColor: Colors.green,
              borderColor: Colors.green,
              children: const {
                'cerrada': Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Menú Cerrado")),
                'porciones': Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Porciones")),
                'macros': Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Macros Flex")),
              },
              onValueChanged: (value) => setState(() => _tipoSeleccionado = value),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_tipoSeleccionado == 'macros') _buildFormularioMacros()
                  else _buildFormularioComidas(),
                  
                  const SizedBox(height: 20),
                  TextField(
                    controller: _notasController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Notas generales", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: CupertinoButton.filled(onPressed: _guardarEnCliente, child: const Text("GUARDAR Y ENVIAR AL CLIENTE"))),
        ],
      ),
    );
  }

  Widget _buildFormularioMacros() {
    return Column(
      children: [
        TextField(controller: _kcalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Calorías Totales (Kcal)", prefixIcon: Icon(Icons.local_fire_department, color: Colors.orange))),
        Row(
          children: [
            Expanded(child: TextField(controller: _proController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Proteínas (g)"))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _carbosController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Carbos (g)"))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _grasasController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Grasas (g)"))),
          ],
        )
      ],
    );
  }

  Widget _buildFormularioComidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _comidasControllers.add(_ComidaController(TextEditingController(), TextEditingController()))),
          child: const Text("+ Añadir Comida", style: TextStyle(color: Colors.green)),
        ),
        ..._comidasControllers.asMap().entries.map((entry) {
          int idx = entry.key;
          _ComidaController ctrl = entry.value;
          return Card(
            margin: const EdgeInsets.only(top: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: ctrl.nombreCtrl, decoration: const InputDecoration(hintText: "Nombre de la comida"))),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _comidasControllers.removeAt(idx))),
                    ],
                  ),
                  TextField(
                    controller: ctrl.elementosCtrl,
                    maxLines: null, 
                    decoration: const InputDecoration(hintText: "Escribe los alimentos (uno por línea)", hintStyle: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}