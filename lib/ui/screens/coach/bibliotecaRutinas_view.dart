import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/rutina_model.dart';
import '../../../../config/theme.dart';

class BibliotecaRutinasView extends StatelessWidget {
  const BibliotecaRutinasView({super.key});

  void _abrirConfiguradorPlantilla(BuildContext context, {Rutina? plantillaExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ModalNuevaPlantilla(plantillaEdit: plantillaExistente),
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
        content: const Text("No podrás recuperar esta rutina."),
        actions: [
          CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .collection('biblioteca_rutinas')
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

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error de sesión")));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mi Biblioteca", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirConfiguradorPlantilla(context),
        backgroundColor: AppTheme.secondaryOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nueva Plantilla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('biblioteca_rutinas')
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
          
          final plantillas = snapshot.data?.docs.map((doc) => Rutina.fromFirestore(doc)).toList() ?? [];

          if (plantillas.isEmpty) {
            return const Center(
              child: Text("Tu biblioteca está vacía.\nCrea tu primera plantilla de entrenamiento.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plantillas.length,
            itemBuilder: (context, index) {
              final rutina = plantillas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.lightBlue.withOpacity(0.3),
                    child: const Icon(Icons.fitness_center, color: AppTheme.primaryBlue),
                  ),
                  title: Text(rutina.titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  subtitle: Text("${rutina.ejercicios.length} ejercicios guardados"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _abrirConfiguradorPlantilla(context, plantillaExistente: rutina)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _borrarPlantilla(context, rutina.id)),
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

// modal crear / editar plantilla
class _ModalNuevaPlantilla extends StatefulWidget {
  final Rutina? plantillaEdit;
  const _ModalNuevaPlantilla({this.plantillaEdit});

  @override
  State<_ModalNuevaPlantilla> createState() => _ModalNuevaPlantillaState();
}

class _ModalNuevaPlantillaState extends State<_ModalNuevaPlantilla> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _notasGeneralesController = TextEditingController();
  List<EjercicioAsignado> ejerciciosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    if (widget.plantillaEdit != null) {
      _tituloController.text = widget.plantillaEdit!.titulo;
      _notasGeneralesController.text = widget.plantillaEdit!.notas;
      ejerciciosSeleccionados = widget.plantillaEdit!.ejercicios.map((e) => EjercicioAsignado(
        nombre: e.nombre, series: e.series, repeticiones: e.repeticiones, notaEjercicio: e.notaEjercicio
      )).toList();
    }
  }

  Future<void> _guardarPlantilla() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _tituloController.text.isEmpty || ejerciciosSeleccionados.isEmpty) return;

    final data = {
      'titulo': _tituloController.text,
      'notas': _notasGeneralesController.text,
      'ejercicios': ejerciciosSeleccionados.map((e) => e.toMap()).toList(),
    };

    try {
      if (widget.plantillaEdit != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('biblioteca_rutinas')
            .doc(widget.plantillaEdit!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('biblioteca_rutinas')
            .add({...data, 'fecha_creacion': FieldValue.serverTimestamp()});
      }
      
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.plantillaEdit != null ? "Editar Plantilla" : "Nueva Plantilla", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Nombre de la plantilla (Ej: Hipertrofia Día 1)")),
          TextField(controller: _notasGeneralesController, decoration: const InputDecoration(labelText: "Notas de esta plantilla", hintStyle: TextStyle(fontSize: 12))),
          const SizedBox(height: 10),
          CupertinoButton(
            onPressed: () => setState(() => ejerciciosSeleccionados.add(EjercicioAsignado(nombre: "", series: "", repeticiones: "", notaEjercicio: ""))),
            child: const Text("+ Añadir Ejercicio a la plantilla"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: ejerciciosSeleccionados.length,
              itemBuilder: (context, index) {
                final ej = ejerciciosSeleccionados[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        TextField(
                          controller: TextEditingController(text: ej.nombre)..selection = TextSelection.collapsed(offset: ej.nombre.length),
                          decoration: const InputDecoration(hintText: "Nombre del ejercicio", isDense: true),
                          onChanged: (v) => ej.nombre = v,
                        ),
                        Row(
                          children: [
                            Expanded(child: TextField(
                              controller: TextEditingController(text: ej.series)..selection = TextSelection.collapsed(offset: ej.series.length),
                              decoration: const InputDecoration(hintText: "Series"), onChanged: (v) => ej.series = v,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(
                              controller: TextEditingController(text: ej.repeticiones)..selection = TextSelection.collapsed(offset: ej.repeticiones.length),
                              decoration: const InputDecoration(hintText: "Reps"), onChanged: (v) => ej.repeticiones = v,
                            )),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(() => ejerciciosSeleccionados.removeAt(index))),
                          ],
                        ),
                        TextField(
                          controller: TextEditingController(text: ej.notaEjercicio)..selection = TextSelection.collapsed(offset: ej.notaEjercicio.length),
                          decoration: const InputDecoration(hintText: "Nota técnica predeterminada", isDense: true),
                          onChanged: (v) => ej.notaEjercicio = v,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: CupertinoButton.filled(onPressed: _guardarPlantilla, child: const Text("GUARDAR PLANTILLA"))),
        ],
      ),
    );
  }
}