import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/revision_model.dart'; 
import '../../../../config/theme.dart';       

class BibliotecaRevisionesView extends StatelessWidget {
  const BibliotecaRevisionesView({super.key});

  void _abrirConfiguradorPlantilla(BuildContext context, {PlantillaRevision? plantillaExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ModalNuevaPlantillaRevision(plantillaEdit: plantillaExistente),
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
        content: const Text("Los clientes que ya tengan esta revisión asignada no la perderán, pero no podrás volver a usarla."),
        actions: [
          CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .collection('biblioteca_revisiones')
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
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text("Plantillas de Revisión", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirConfiguradorPlantilla(context),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Plantilla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('biblioteca_revisiones')
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
          
          final plantillas = snapshot.data?.docs.map((doc) => PlantillaRevision.fromFirestore(doc)).toList() ?? [];

          if (plantillas.isEmpty) {
            return const Center(
              child: Text("Tu biblioteca está vacía.\nCrea tu primera plantilla de revisión.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plantillas.length,
            itemBuilder: (context, index) {
              final plantilla = plantillas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: const Icon(CupertinoIcons.doc_chart_fill, color: Colors.purple),
                  ),
                  title: Text(plantilla.titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  subtitle: Text("${plantilla.parametros.length} parámetros a medir"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _abrirConfiguradorPlantilla(context, plantillaExistente: plantilla)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _borrarPlantilla(context, plantilla.id)),
                    ],
                  ),
                  children: plantilla.parametros.map((param) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.check_circle_outline, color: Colors.purple, size: 16),
                    title: Text(param),
                  )).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModalNuevaPlantillaRevision extends StatefulWidget {
  final PlantillaRevision? plantillaEdit;
  const _ModalNuevaPlantillaRevision({this.plantillaEdit});

  @override
  State<_ModalNuevaPlantillaRevision> createState() => _ModalNuevaPlantillaRevisionState();
}

class _ModalNuevaPlantillaRevisionState extends State<_ModalNuevaPlantillaRevision> {
  final TextEditingController _tituloController = TextEditingController();
  List<TextEditingController> _parametrosControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.plantillaEdit != null) {
      _tituloController.text = widget.plantillaEdit!.titulo;
      _parametrosControllers = widget.plantillaEdit!.parametros
          .map((p) => TextEditingController(text: p))
          .toList();
    } else {
      _parametrosControllers.add(TextEditingController(text: "Peso (kg)"));
    }
  }

Future<void> _guardarPlantilla() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _tituloController.text.isEmpty) return;

    List<String> parametrosFinales = _parametrosControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (parametrosFinales.isEmpty) return;

    final data = {
      'titulo': _tituloController.text,
      'parametros': parametrosFinales,
      'fecha_creacion': FieldValue.serverTimestamp(),
    };

    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      if (widget.plantillaEdit != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('biblioteca_revisiones').doc(widget.plantillaEdit!.id).update(data);
      } else {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('biblioteca_revisiones').add(data);
      }
      
      navigator.pop();
    } catch (e) {
      navigator.pop();
      scaffold.showSnackBar(SnackBar(content: Text("Error de Firebase: $e"), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.plantillaEdit != null ? "Editar Plantilla" : "Nueva Plantilla", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          
          TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Nombre (Ej: Revisión Quincenal)", hintStyle: TextStyle(fontSize: 14))),
          const SizedBox(height: 10),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Text("Nota: Las fotos y el cuadro de texto para sensaciones ya vienen incluidos por defecto. Aquí solo define los DATOS NUMÉRICOS que quieres que el cliente rellene.", style: TextStyle(fontSize: 12, color: Colors.purple)),
          ),
          const SizedBox(height: 10),

          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => setState(() => _parametrosControllers.add(TextEditingController())),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle, color: Colors.purple),
                SizedBox(width: 8),
                Text("Añadir parámetro a medir", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _parametrosControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _parametrosControllers[index],
                          decoration: InputDecoration(
                            hintText: "Ej: Perímetro Cintura (cm)",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _parametrosControllers.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: CupertinoButton(color: Colors.purple, onPressed: _guardarPlantilla, child: const Text("GUARDAR PLANTILLA", style: TextStyle(fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}