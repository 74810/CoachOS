import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart';
import '../../../../../models/revision_model.dart';
import '../../../../../config/theme.dart';
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
              const Text("Asignar Plantilla al Cliente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
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
                          leading: const Icon(CupertinoIcons.doc_chart_fill, color: AppTheme.primaryBlue),
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
    
    // índice 0 = Libre, el resto coincide con los días
    List<Widget> opciones = [
      const Center(child: Text("Libre (Siempre)", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold))),
      ...List.generate(30, (index) => Center(child: Text("${index + 1} días")))
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Frecuencia de Revisión", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          height: 100,
          child: CupertinoPicker(
            itemExtent: 40,
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
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PLANTILLA ACTIVA', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      CupertinoButton(padding: EdgeInsets.zero, minSize: 0, onPressed: () => _abrirSelectorPlantillas(context), child: const Text("Cambiar", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(nombrePlantilla ?? "Ninguna asignada", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 14),
                  Container(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FRECUENCIA EXIGIDA', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      CupertinoButton(padding: EdgeInsets.zero, minSize: 0, onPressed: () => _cambiarFrecuencia(context, frecuencia), child: const Text("Editar", style: TextStyle(color: AppTheme.primaryBlue, fontSize: 14, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    frecuencia == 0 ? "Modo Libre (Siempre permitido)" : "Cada $frecuencia días",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                  ),
                ],
              ),
            );
          },
        ),

        // historial de revisiones
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

                  final colorEstado = esPendiente ? AppTheme.secondaryOrange : const Color(0xFF34C759);
                  return GestureDetector(
                    onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => _ModalCorregirRevision(cliente: cliente, revision: rev)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(esPendiente ? CupertinoIcons.clock_fill : CupertinoIcons.checkmark_seal_fill, color: colorEstado, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Revisión ${rev.fecha.day}/${rev.fecha.month}/${rev.fecha.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
                                Text(esPendiente ? 'Pendiente de revisión' : 'Revisada',
                                    style: TextStyle(fontSize: 12, color: colorEstado, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 18),
                            onPressed: () => showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text("Borrar Revisión"),
                                content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
                                actions: [
                                  CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.pop(context)),
                                  CupertinoDialogAction(isDestructiveAction: true, child: const Text("Borrar"), onPressed: () async {
                                    Navigator.pop(context);
                                    await FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).collection('revisiones').doc(rev.id).delete();
                                  }),
                                ],
                              ),
                            ),
                          ),
                          Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("Revisión de ${widget.cliente.nombre}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
              IconButton(onPressed: () => Navigator.pop(context), icon: Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DATOS SUBIDOS', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.lightBlue.withOpacity(0.5), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.revision.valoresParametros.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8, top: 1), decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle)),
                    Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(e.value.toString(), style: const TextStyle(fontSize: 14)),
                  ]),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.revision.fotosUrl.isNotEmpty) ...[
              Text('FOTOS', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 8),
              SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: widget.revision.fotosUrl.length, itemBuilder: (context, index) => Padding(padding: const EdgeInsets.only(right: 8.0), child: GestureDetector(onTap: () => Navigator.push(context, CupertinoPageRoute(fullscreenDialog: true, builder: (context) => VisualizadorImagen(imageUrl: widget.revision.fotosUrl[index]))), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.revision.fotosUrl[index], width: 100, height: 120, fit: BoxFit.cover)))))),
              const SizedBox(height: 20),
            ],
            Text('SENSACIONES', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(widget.revision.sensacionesCliente.isEmpty ? "Sin comentarios" : widget.revision.sensacionesCliente, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            Text('TU RESPUESTA', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _respuestaController,
              maxLines: 5,
              placeholder: "Escribe tu feedback al cliente...",
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            ),
            const SizedBox(height: 16),
          ]))),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(14),
              onPressed: _guardando ? null : _guardarRespuesta,
              child: const Text("Guardar y marcar revisada", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}