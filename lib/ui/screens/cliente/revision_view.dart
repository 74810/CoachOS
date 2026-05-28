import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/revision_model.dart';
import '../../../config/theme.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_os_app/ui/widgets/visualizador_imagen.dart';

class RevisionCliente extends StatelessWidget {
  const RevisionCliente({super.key});

  void _abrirFormularioRevision(BuildContext context, List<String> parametros) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ModalFormularioRevision(parametrosAsignados: parametros),
    );
  }

  DateTime _calcularUltimaRevision(Map<String, dynamic> data, int frecuencia) {
    if (data['fecha_ultima_revision'] != null) {
      return (data['fecha_ultima_revision'] as Timestamp).toDate();
    } else if (data.containsKey('fecha_ultima_revision')) {
      return DateTime.now(); 
    } else {
      int diasRestar = frecuencia == 0 ? 1 : frecuencia + 1;
      return DateTime.now().subtract(Duration(days: diasRestar));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Error: No hay usuario logueado")));

    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      body: SafeArea(
        child: Column(
        children: [
          // TÍTULO DE PÁGINA
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mis Revisiones',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
          ),

          // PANEL SUPERIOR CON TEMPORIZADOR Y BLOQUEO
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
              if (!snapshot.hasData || snapshot.data!.data() == null) return const SizedBox();
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final nombrePlantilla = data['nombre_plantilla_activa']?.toString();
              final rawParametros = data['parametros_revision'];
              
              List<String> parametros = [];
              if (rawParametros is List) {
                parametros = rawParametros.map((e) => e.toString()).toList();
              }

              if (nombrePlantilla == null || parametros.isEmpty) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.doc_chart_fill, color: AppTheme.primaryBlue, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('Tu entrenador aún no te ha asignado una plantilla de revisión.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
                );
              }

              int frecuencia = data['frecuencia_revisiones'] ?? 15;
              bool esLibre = frecuencia == 0;

              DateTime ultimaRev = _calcularUltimaRevision(data, frecuencia);
              DateTime fechaObjetivo = ultimaRev.add(Duration(days: frecuencia));

              return Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, _) {
                    final ahora = DateTime.now();
                    final tocaRevision = esLibre || ahora.isAfter(fechaObjetivo);
                    final diferencia = esLibre ? Duration.zero : fechaObjetivo.difference(ahora);

                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: AppTheme.lightBlue, shape: BoxShape.circle),
                              child: const Icon(CupertinoIcons.doc_chart_fill, color: AppTheme.primaryBlue, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Plantilla Activa', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                  Text(nombrePlantilla, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (tocaRevision) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              esLibre ? '✓ Modo Libre Activado' : '✓ Formulario Abierto',
                              style: const TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(14),
                              onPressed: () => _abrirFormularioRevision(context, parametros),
                              child: const Text('+ Rellenar Revisión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ] else ...[
                          Text('Próxima revisión disponible en',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${diferencia.inDays}d  ${diferencia.inHours % 24}h  ${diferencia.inMinutes % 60}m  ${diferencia.inSeconds % 60}s',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                ),
              );
            },
          ),

          // HISTORIAL DE REVISIONES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .collection('revisiones')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
                
                final revisiones = snapshot.data?.docs.map((doc) => Revision.fromFirestore(doc)).toList() ?? [];

                if (revisiones.isEmpty) {
                  return Center(
                    child: Text('Aún no has enviado ninguna revisión.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: revisiones.length,
                  itemBuilder: (context, index) {
                    final rev = revisiones[index];
                    final esPendiente = rev.estado == 'pendiente';
                    final colorEstado = esPendiente ? AppTheme.secondaryOrange : const Color(0xFF34C759);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ExpansionTile(
                          collapsedBackgroundColor: Colors.white,
                          backgroundColor: Colors.white,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              esPendiente ? CupertinoIcons.clock_fill : CupertinoIcons.checkmark_seal_fill,
                              color: colorEstado, size: 20,
                            ),
                          ),
                          title: Text(
                            'Revisión ${rev.fecha.day}/${rev.fecha.month}/${rev.fecha.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryBlue),
                          ),
                          subtitle: Text(
                            esPendiente ? 'Esperando respuesta del coach...' : '¡Revisada por tu coach!',
                            style: TextStyle(color: colorEstado, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TUS DATOS', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  ...rev.valoresParametros.entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle)),
                                        Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(e.value.toString(), style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  )),
                                
                                if (rev.fotosUrl.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text('FOTOS', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 80,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: rev.fotosUrl.length,
                                      itemBuilder: (context, imgIndex) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(context, CupertinoPageRoute(fullscreenDialog: true, builder: (context) => VisualizadorImagen(imageUrl: rev.fotosUrl[imgIndex])));
                                            },
                                            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(rev.fotosUrl[imgIndex], width: 80, height: 80, fit: BoxFit.cover)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),
                                Text('SENSACIONES', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                const SizedBox(height: 6),
                                Text(rev.sensacionesCliente.isEmpty ? 'No escribiste nada.' : rev.sensacionesCliente, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700, fontSize: 14)),
                                
                                if (!esPendiente && rev.respuestaCoach.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34C759).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFF34C759).withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFF34C759), size: 16),
                                            const SizedBox(width: 6),
                                            Text('Respuesta del Coach', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(rev.respuestaCoach),
                                      ],
                                    ),
                                  )
                                ]
                              ],
                            ),
                          )
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
        ),
      ),
    );
  }
}

//MODAL DINÁMICO PARA RELLENAR LA REVISIÓN (SIN CAMBIOS)
class _ModalFormularioRevision extends StatefulWidget {
  final List<String> parametrosAsignados;
  const _ModalFormularioRevision({required this.parametrosAsignados});

  @override
  State<_ModalFormularioRevision> createState() => _ModalFormularioRevisionState();
}

class _ModalFormularioRevisionState extends State<_ModalFormularioRevision> {
  final Map<String, TextEditingController> _controllersParametros = {};
  final TextEditingController _sensacionesController = TextEditingController();
  bool _guardando = false; 

  List<File> _fotosSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    for (String param in widget.parametrosAsignados) {
      _controllersParametros[param] = TextEditingController();
    }
  }

  Future<void> _elegirFotos() async {
    final List<XFile> imagenes = await _picker.pickMultiImage(imageQuality: 50);
    if (imagenes.isNotEmpty) {
      setState(() {
        _fotosSeleccionadas.addAll(imagenes.map((e) => File(e.path)));
        if (_fotosSeleccionadas.length > 5) {
          _fotosSeleccionadas = _fotosSeleccionadas.sublist(0, 5);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solo puedes subir un máximo de 5 fotos."), backgroundColor: Colors.orange));
        }
      });
    }
  }

  Future<void> _enviarRevision() async {
    if (_guardando) return; 
    setState(() => _guardando = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> valoresFinales = {};
    _controllersParametros.forEach((parametro, controller) {
      valoresFinales[parametro] = controller.text.trim();
    });

    List<String> urlsFotos = [];

    try {
      for (int i = 0; i < _fotosSeleccionadas.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('revisiones')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
            
        await ref.putFile(_fotosSeleccionadas[i]);
        final url = await ref.getDownloadURL();
        urlsFotos.add(url);
      }

      final data = {
        'fecha': FieldValue.serverTimestamp(),
        'valores_parametros': valoresFinales,
        'fotos_url': urlsFotos,
        'sensaciones_cliente': _sensacionesController.text,
        'respuesta_coach': '',
        'estado': 'pendiente',
      };

      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('revisiones').add(data);
      
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'fecha_ultima_revision': FieldValue.serverTimestamp(),
      });
          
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Revisión enviada. ¡Gran trabajo!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      print("Error enviando revisión: $e");
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red));
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
              const Text("Nueva Revisión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Tus Datos Físicos", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  
                  ...widget.parametrosAsignados.map((param) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllersParametros[param],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: param,
                          filled: true,
                          fillColor: Colors.purple.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("2. Fotos de Progreso", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text("${_fotosSeleccionadas.length}/5", style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._fotosSeleccionadas.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: -10, right: -10,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => setState(() => _fotosSeleccionadas.removeAt(entry.key)),
                              ),
                            )
                          ],
                        );
                      }),
                      if (_fotosSeleccionadas.length < 5)
                        GestureDetector(
                          onTap: _elegirFotos,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purple.withOpacity(0.3), style: BorderStyle.solid)),
                            child: const Icon(Icons.add_a_photo, color: Colors.purple),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("3. Sensaciones y Dudas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sensacionesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "¿Cómo ha ido la semana? ¿Has pasado hambre? ¿Dudas con algún ejercicio?",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
              color: Colors.purple, 
              onPressed: _guardando ? null : _enviarRevision, 
              child: _guardando 
                  ? const CupertinoActivityIndicator(color: Colors.white) 
                  : const Text("ENVIAR REVISIÓN AL COACH", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ),
        ],
      ),
    );
  }
}