import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart';
import '../../../../../models/rutina_model.dart';
import '../../../../../config/theme.dart';

class EntrenoTab extends StatelessWidget {
  final Cliente cliente;
  const EntrenoTab({super.key, required this.cliente});

  void _abrirConfigurador(BuildContext context, {Rutina? rutinaExistente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ModalNuevaRutina(cliente: cliente, rutinaEdit: rutinaExistente),
    );
  }

  void _borrarRutina(BuildContext context, String rutinaId) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text("¿Borrar entrenamiento?"),
        content: const Text("Esta acción eliminará la rutina por completo."),
        actions: [
          CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).collection('rutinas').doc(rutinaId).delete();
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
          .collection('rutinas')
          .orderBy('fecha_creacion', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
        final rutinas = snapshot.data?.docs.map((doc) => Rutina.fromFirestore(doc)).toList() ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("RUTINAS ASIGNADAS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _abrirConfigurador(context),
                  child: const Text("+ Nueva Rutina", style: TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...rutinas.map((r) => _buildCardRutina(context, r)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCardRutina(BuildContext context, Rutina rutina) {
    return _CardRutina(
      rutina: rutina,
      onEditar: () => _abrirConfigurador(context, rutinaExistente: rutina),
      onBorrar: () => _borrarRutina(context, rutina.id),
    );
  }
}

class _CardRutina extends StatefulWidget {
  final Rutina rutina;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;
  const _CardRutina({required this.rutina, required this.onEditar, required this.onBorrar});

  @override
  State<_CardRutina> createState() => _CardRutinaState();
}

class _CardRutinaState extends State<_CardRutina> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          onExpansionChanged: (v) => setState(() => _expandido = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.flame_fill, color: AppTheme.secondaryOrange, size: 20),
          ),
          title: Text(widget.rutina.titulo, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryBlue, fontSize: 15)),
          subtitle: Text('${widget.rutina.ejercicios.length} ejercicios',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(CupertinoIcons.pencil, color: AppTheme.primaryBlue.withOpacity(0.7), size: 20), onPressed: widget.onEditar),
              IconButton(icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 18), onPressed: widget.onBorrar),
              AnimatedRotation(
                turns: _expandido ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(CupertinoIcons.chevron_down, size: 15, color: Colors.grey.shade400),
              ),
            ],
          ),
          children: [
            if (widget.rutina.notas.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill, color: AppTheme.primaryBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.rutina.notas,
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: widget.rutina.ejercicios.map((ej) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.bolt_fill, size: 14, color: AppTheme.secondaryOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ej.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                              if (ej.notaEjercicio.isNotEmpty)
                                Text(ej.notaEjercicio, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${ej.series}×${ej.repeticiones}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalNuevaRutina extends StatefulWidget {
  final Cliente cliente;
  final Rutina? rutinaEdit;
  const _ModalNuevaRutina({required this.cliente, this.rutinaEdit});

  @override
  State<_ModalNuevaRutina> createState() => _ModalNuevaRutinaState();
}

class _ModalNuevaRutinaState extends State<_ModalNuevaRutina> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _notasGeneralesController = TextEditingController();
  List<EjercicioAsignado> ejerciciosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    if (widget.rutinaEdit != null) {
      _tituloController.text = widget.rutinaEdit!.titulo;
      _notasGeneralesController.text = widget.rutinaEdit!.notas;
      ejerciciosSeleccionados = widget.rutinaEdit!.ejercicios.map((e) => EjercicioAsignado(
        nombre: e.nombre, series: e.series, repeticiones: e.repeticiones, notaEjercicio: e.notaEjercicio
      )).toList();
    }
  }

  // importar plantilla desde la biblioteca del coach
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
              const Text("Mis Plantillas Guardadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .collection('biblioteca_rutinas')
                      .orderBy('fecha_creacion', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text("No tienes plantillas guardadas en Ajustes > Biblioteca."));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.file_download, color: AppTheme.secondaryOrange),
                          title: Text(data['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${(data['ejercicios'] as List).length} ejercicios"),
                          onTap: () {
                            setState(() {
                              _tituloController.text = data['titulo'] ?? '';
                              _notasGeneralesController.text = data['notas'] ?? '';
                              ejerciciosSeleccionados = (data['ejercicios'] as List? ?? [])
                                  .map((e) => EjercicioAsignado.fromMap(e as Map<String, dynamic>))
                                  .toList();
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Plantilla cargada."), backgroundColor: Colors.green),
                            );
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

  Future<void> _guardar() async {
    if (_tituloController.text.isEmpty || ejerciciosSeleccionados.isEmpty) return;

    final data = {
      'titulo': _tituloController.text,
      'notas': _notasGeneralesController.text,
      'ejercicios': ejerciciosSeleccionados.map((e) => e.toMap()).toList(),
    };

    try {
      if (widget.rutinaEdit != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.cliente.id)
            .collection('rutinas')
            .doc(widget.rutinaEdit!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.cliente.id)
            .collection('rutinas')
            .add({
              ...data,
              'fecha_creacion': FieldValue.serverTimestamp(),
            });
      }
          
      if (mounted) {
        Navigator.pop(context);
      }
      
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
              Text(widget.rutinaEdit != null ? "Editar Sesión" : "Nueva Sesión", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          
          // importar plantilla
          if (widget.rutinaEdit == null) ...[
            const SizedBox(height: 10),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _abrirSelectorBiblioteca,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2))
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books, color: AppTheme.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text("Importar de mi Biblioteca", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título de la rutina")),
          TextField(controller: _notasGeneralesController, decoration: const InputDecoration(labelText: "Notas generales (opcional)", hintStyle: TextStyle(fontSize: 12))),
          const SizedBox(height: 10),
          CupertinoButton(
            onPressed: () => setState(() => ejerciciosSeleccionados.add(EjercicioAsignado(nombre: "", series: "", repeticiones: "", notaEjercicio: ""))),
            child: const Text("+ Añadir Ejercicio"),
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
                          decoration: const InputDecoration(hintText: "Nota específica para este ejercicio", isDense: true),
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
          SizedBox(width: double.infinity, child: CupertinoButton.filled(onPressed: _guardar, child: const Text("GUARDAR Y CERRAR"))),
        ],
      ),
    );
  }
}