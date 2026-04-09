import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart';
import '../../../../../models/revision_model.dart';
import '../../../../../config/theme.dart';

class RevisionTab extends StatelessWidget {
  final Cliente cliente;
  const RevisionTab({super.key, required this.cliente});

  void _abrirSelectorPlantillas(BuildContext context) {
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
              const Text("Asignar Plantilla al Cliente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(user.uid)
                      .collection('biblioteca_revisiones')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return const Center(child: Text("No tienes plantillas en tu biblioteca."));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final plantilla = PlantillaRevision.fromFirestore(docs[index]);
                        return ListTile(
                          leading: const Icon(CupertinoIcons.doc_chart_fill, color: Colors.purple),
                          title: Text(plantilla.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${plantilla.parametros.length} parámetros"),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final scaffold = ScaffoldMessenger.of(context);

                            try {
                              await FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).set({
                                'parametros_revision': plantilla.parametros,
                                'nombre_plantilla_activa': plantilla.titulo,
                              }, SetOptions(merge: true));

                              navigator.pop();
                              
                              scaffold.showSnackBar(
                                SnackBar(content: Text("Plantilla asignada a ${cliente.nombre}"), backgroundColor: Colors.purple),
                              );
                              
                            } catch (e) {
                              navigator.pop();
                              
                              scaffold.showSnackBar(
                                SnackBar(content: Text("ERROR DE PERMISOS: $e\nVe a Firebase > Firestore > Rules"), backgroundColor: Colors.red, duration: const Duration(seconds: 8)),
                              );
                            }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //PLANTILLA ACTIVA
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final nombrePlantilla = data['nombre_plantilla_activa'] as String?;
            final parametros = List<String>.from(data['parametros_revision'] ?? []);

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("CONFIGURACIÓN ACTUAL", style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => _abrirSelectorPlantillas(context),
                        child: const Text("Cambiar", style: TextStyle(color: Colors.purple, fontSize: 14)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (nombrePlantilla == null)
                    const Text("El cliente no tiene ninguna plantilla asignada. No podrá subir revisiones.", style: TextStyle(color: Colors.grey, fontSize: 14))
                  else ...[
                    Text(nombrePlantilla, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                    const SizedBox(height: 4),
                    Text("Se pedirán ${parametros.length} datos: ${parametros.join(', ')}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ]
                ],
              ),
            );
          },
        ),

        //HISTORIAL DE REVISIONES ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(cliente.id)
                .collection('revisiones')
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
              
              final revisiones = snapshot.data?.docs.map((doc) => Revision.fromFirestore(doc)).toList() ?? [];

              if (revisiones.isEmpty) {
                return const Center(child: Text("El cliente aún no ha subido ninguna revisión.", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: revisiones.length,
                itemBuilder: (context, index) {
                  final rev = revisiones[index];
                  final esPendiente = rev.estado == 'pendiente';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: esPendiente ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        child: Icon(esPendiente ? Icons.hourglass_top : Icons.check, color: esPendiente ? Colors.orange : Colors.green),
                      ),
                      title: Text("Revisión del ${rev.fecha.day}/${rev.fecha.month}/${rev.fecha.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(esPendiente ? "Esperando tu respuesta" : "Revisada", style: TextStyle(color: esPendiente ? Colors.orange : Colors.green)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) => _ModalCorregirRevision(cliente: cliente, revision: rev),
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
}
//MODAL PARA QUE EL COACH CONTESTE LA REVISIÓN
class _ModalCorregirRevision extends StatefulWidget {
  final Cliente cliente;
  final Revision revision;
  const _ModalCorregirRevision({required this.cliente, required this.revision});

  @override
  State<_ModalCorregirRevision> createState() => _ModalCorregirRevisionState();
}

class _ModalCorregirRevisionState extends State<_ModalCorregirRevision> {
  final TextEditingController _respuestaController = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _respuestaController.text = widget.revision.respuestaCoach;
  }

  Future<void> _guardarRespuesta() async {
    if (_guardando || _respuestaController.text.isEmpty) return;
    setState(() => _guardando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.cliente.id)
          .collection('revisiones')
          .doc(widget.revision.id)
          .update({
            'respuesta_coach': _respuestaController.text.trim(),
            'estado': 'revisada', // Mágicamente pasará de naranja a verde
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Respuesta enviada al cliente"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
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
              Text("Revisión de ${widget.cliente.nombre}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Mostrar los datos
                  const Text("Datos subidos:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.revision.valoresParametros.entries.map((e) => Text("• ${e.key}: ${e.value}", style: const TextStyle(fontSize: 15))).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  //Mostrar las Fotos
                  const Text("Fotos de progreso:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  if (widget.revision.fotosUrl.isEmpty)
                    const Text("El cliente no subió fotos esta vez.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.revision.fotosUrl.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(widget.revision.fotosUrl[index], width: 100, height: 120, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  //Sensaciones del cliente
                  const Text("Sus sensaciones:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Text(widget.revision.sensacionesCliente.isEmpty ? "Sin comentarios" : widget.revision.sensacionesCliente),
                  ),

                  const SizedBox(height: 20),
                  
                  //Respuesta
                  const Text("Tu Respuesta / Feedback:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _respuestaController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Escribe aquí tu análisis, si le cambias los macros, etc.",
                      filled: true,
                      fillColor: Colors.green.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.green)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, 
            child: CupertinoButton(
              color: Colors.green, 
              onPressed: _guardando ? null : _guardarRespuesta, 
              child: _guardando 
                  ? const CupertinoActivityIndicator(color: Colors.white) 
                  : const Text("GUARDAR Y MARCAR REVISADA", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ),
        ],
      ),
    );
  }
}