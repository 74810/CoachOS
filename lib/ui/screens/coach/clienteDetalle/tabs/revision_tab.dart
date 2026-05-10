import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart';
import '../../../../../models/revision_model.dart';
import 'package:coach_os_app/ui/widgets/visualizador_imagen.dart';

class RevisionTab extends StatelessWidget {
  final Cliente cliente;
  const RevisionTab({super.key, required this.cliente});

  void _abrirSelectorPlantillas(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Asignar Plantilla al Cliente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('biblioteca_revisiones').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());
                    final docs = snapshot.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final plantilla = PlantillaRevision.fromFirestore(docs[index]);
                        return ListTile(
                          leading: const Icon(CupertinoIcons.doc_chart_fill, color: Colors.purple),
                          title: Text(plantilla.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () async {
                            Navigator.pop(context);
                            await FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).set({'parametros_revision': plantilla.parametros, 'nombre_plantilla_activa': plantilla.titulo}, SetOptions(merge: true));
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

  void _cambiarFrecuencia(BuildContext context, int frecuenciaActual) {
    int nuevaFrecuencia = frecuenciaActual;
    
    // Construimos la lista de opciones (El 0 será Libre)
    List<Widget> opciones = [
      const Center(child: Text("Libre (Siempre)", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
      ...List.generate(30, (index) => Center(child: Text("${index + 1} días")))
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Frecuencia de Revisión", style: TextStyle(color: Colors.purple, fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          height: 100,
          child: CupertinoPicker(
            itemExtent: 40, 
            // Como el índice 0 es "Libre", el índice coincide exactamente con los días
            scrollController: FixedExtentScrollController(initialItem: frecuenciaActual),
            onSelectedItemChanged: (index) => nuevaFrecuencia = index,
            children: opciones,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).set({'frecuencia_revisiones': nuevaFrecuencia}, SetOptions(merge: true));
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final nombrePlantilla = data['nombre_plantilla_activa'] as String?;
            final frecuencia = data['frecuencia_revisiones'] ?? 15;

            return Container(
              margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.withOpacity(0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("PLANTILLA ACTIVA", style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)), CupertinoButton(padding: EdgeInsets.zero, minSize: 0, onPressed: () => _abrirSelectorPlantillas(context), child: const Text("Cambiar", style: TextStyle(color: Colors.purple, fontSize: 14)))]),
                  Text(nombrePlantilla ?? "Ninguna", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("FRECUENCIA EXIGIDA", style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)), CupertinoButton(padding: EdgeInsets.zero, minSize: 0, onPressed: () => _cambiarFrecuencia(context, frecuencia), child: const Text("Editar", style: TextStyle(color: Colors.purple, fontSize: 14)))]),
                  
                  // MAGIA AQUÍ: Mostramos "Modo Libre" si es 0
                  Text(
                    frecuencia == 0 ? "Modo Libre (Siempre permitido)" : "Cada $frecuencia días", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ],
              ),
            );
          },
        ),

        // HISTORIAL CON BOTÓN DE BORRAR
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).collection('revisiones').orderBy('fecha', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CupertinoActivityIndicator());
              final revisiones = snapshot.data?.docs.map((doc) => Revision.fromFirestore(doc)).toList() ?? [];

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: revisiones.length,
                itemBuilder: (context, index) {
                  final rev = revisiones[index];
                  final esPendiente = rev.estado == 'pendiente';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: esPendiente ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2), child: Icon(esPendiente ? Icons.hourglass_top : Icons.check, color: esPendiente ? Colors.orange : Colors.green)),
                      title: Text("Revisión del ${rev.fecha.day}/${rev.fecha.month}/${rev.fecha.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 20),
                            onPressed: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: const Text("Borrar Revisión"),
                                  content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
                                  actions: [
                                    CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.pop(context)),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text("Borrar"),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).collection('revisiones').doc(rev.id).delete();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => _ModalCorregirRevision(cliente: cliente, revision: rev)),
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
}

class _ModalCorregirRevision extends StatefulWidget {
  final Cliente cliente;
  final Revision revision;
  const _ModalCorregirRevision({required this.cliente, required this.revision});
  @override State<_ModalCorregirRevision> createState() => _ModalCorregirRevisionState();
}
class _ModalCorregirRevisionState extends State<_ModalCorregirRevision> {
  final TextEditingController _respuestaController = TextEditingController();
  bool _guardando = false;

  @override void initState() { super.initState(); _respuestaController.text = widget.revision.respuestaCoach; }

  Future<void> _guardarRespuesta() async {
    if (_guardando || _respuestaController.text.isEmpty) return;
    setState(() => _guardando = true);
    await FirebaseFirestore.instance.collection('usuarios').doc(widget.cliente.id).collection('revisiones').doc(widget.revision.id).update({'respuesta_coach': _respuestaController.text.trim(), 'estado': 'revisada'});
    if (mounted) Navigator.pop(context);
  }

  @override Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20), height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Revisión de ${widget.cliente.nombre}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Datos subidos:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widget.revision.valoresParametros.entries.map((e) => Text("• ${e.key}: ${e.value}")).toList())),
            const SizedBox(height: 20),
            if (widget.revision.fotosUrl.isNotEmpty) SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: widget.revision.fotosUrl.length, itemBuilder: (context, index) => Padding(padding: const EdgeInsets.only(right: 8.0), child: GestureDetector(onTap: () => Navigator.push(context, CupertinoPageRoute(fullscreenDialog: true, builder: (context) => VisualizadorImagen(imageUrl: widget.revision.fotosUrl[index]))), child: Image.network(widget.revision.fotosUrl[index], width: 100, height: 120, fit: BoxFit.cover))))),
            const SizedBox(height: 20),
            const Text("Sus sensaciones:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(widget.revision.sensacionesCliente.isEmpty ? "Sin comentarios" : widget.revision.sensacionesCliente),
            const SizedBox(height: 20),
            TextField(controller: _respuestaController, maxLines: 5, decoration: const InputDecoration(hintText: "Tu Respuesta / Feedback")),
          ]))),
          SizedBox(width: double.infinity, child: CupertinoButton(color: Colors.green, onPressed: _guardando ? null : _guardarRespuesta, child: const Text("GUARDAR Y MARCAR REVISADA")))
        ],
      ),
    );
  }
}