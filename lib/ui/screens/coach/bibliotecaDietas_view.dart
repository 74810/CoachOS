import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/dieta_model.dart';
import '../../../../config/theme.dart';

class BibliotecaDietasView extends StatelessWidget {
  const BibliotecaDietasView({super.key});

  void _abrirConfiguradorPlantilla(BuildContext context, {Dieta? plantillaExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ModalNuevaPlantillaDieta(plantillaEdit: plantillaExistente),
    );
  }

  void _borrarPlantilla(BuildContext context, String plantillaId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text("¿Borrar plantilla?"),
        content: const Text("No podrás recuperar esta dieta predefinida."),
        actions: [
          CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .collection('biblioteca_dietas')
                  .doc(plantillaId)
                  .delete();
            },
            child: const Text("Borrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Error de sesión")));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Biblioteca de Dietas", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirConfiguradorPlantilla(context),
        backgroundColor: AppTheme.secondaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Dieta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('biblioteca_dietas')
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
          
          final plantillas = snapshot.data?.docs.map((doc) => Dieta.fromFirestore(doc)).toList() ?? [];

          if (plantillas.isEmpty) {
            return const Center(
              child: Text("Tu biblioteca está vacía.\nCrea tu primera plantilla de nutrición.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plantillas.length,
            itemBuilder: (context, index) {
              final dieta = plantillas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.lightBlue.withOpacity(0.3),
                    child: Icon(
                      dieta.tipo == 'macros' ? Icons.pie_chart : Icons.restaurant_menu, 
                      color: AppTheme.primaryBlue
                    ),
                  ),
                  title: Text(dieta.titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  subtitle: Text("Tipo: ${dieta.tipo.toUpperCase()}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _abrirConfiguradorPlantilla(context, plantillaExistente: dieta)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _borrarPlantilla(context, dieta.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModalNuevaPlantillaDieta extends StatefulWidget {
  final Dieta? plantillaEdit;
  const _ModalNuevaPlantillaDieta({this.plantillaEdit});

  @override
  State<_ModalNuevaPlantillaDieta> createState() => _ModalNuevaPlantillaDietaState();
}

class _ComidaController {
  TextEditingController nombreCtrl;
  TextEditingController elementosCtrl;
  _ComidaController(this.nombreCtrl, this.elementosCtrl);
}

class _ModalNuevaPlantillaDietaState extends State<_ModalNuevaPlantillaDieta> {
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
    if (widget.plantillaEdit != null) {
      final p = widget.plantillaEdit!;
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
  }

  Future<void> _guardarPlantilla() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _tituloController.text.isEmpty) return;

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
      if (widget.plantillaEdit != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('biblioteca_dietas').doc(widget.plantillaEdit!.id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('biblioteca_dietas').add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {}
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
              Text(widget.plantillaEdit != null ? "Editar Dieta" : "Nueva Dieta", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          
          TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Nombre de la dieta (Ej: Volumen 3000 Kcal)")),
          
          const SizedBox(height: 16),
          // selector de tipo
          SizedBox(
            width: double.infinity,
            child: CupertinoSegmentedControl<String>(
              groupValue: _tipoSeleccionado,
              selectedColor: AppTheme.primaryBlue,
              borderColor: AppTheme.primaryBlue,
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
                    decoration: const InputDecoration(labelText: "Notas generales (Ej: Beber 3L de agua)", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: CupertinoButton.filled(onPressed: _guardarPlantilla, child: const Text("GUARDAR EN BIBLIOTECA"))),
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
          child: const Text("+ Añadir Comida (Ej: Desayuno)"),
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
                    decoration: InputDecoration(
                      hintText: _tipoSeleccionado == 'cerrada' 
                          ? "100g de pollo\n50g de arroz\n(Un alimento por línea)" 
                          : "2 palmas de proteína\n1 puñado de arroz\n(Una porción por línea)",
                      hintStyle: const TextStyle(fontSize: 12),
                    ),
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