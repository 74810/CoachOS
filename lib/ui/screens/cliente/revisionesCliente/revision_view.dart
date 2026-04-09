import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/revision_model.dart'; // Ajusta la ruta
import '../../../../config/theme.dart';       // Ajusta la ruta
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Error: No hay usuario logueado")));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Mis Revisiones", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- SECCIÓN 1: ESTADO ACTUAL Y BOTÓN DE SUBIR ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
              if (!snapshot.hasData || snapshot.data!.data() == null) return const SizedBox();
              
              final data = snapshot.data!.data() as Map<String, dynamic>;
              
              // Lectura extra segura de la base de datos
              final nombrePlantilla = data['nombre_plantilla_activa']?.toString();
              final rawParametros = data['parametros_revision'];
              
              List<String> parametros = [];
              if (rawParametros is List) {
                parametros = rawParametros.map((e) => e.toString()).toList();
              }

              if (nombrePlantilla == null || parametros.isEmpty) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: const Center(
                    child: Text("Tu entrenador aún no te ha asignado\nuna plantilla de revisión.", 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.doc_chart_fill, color: Colors.purple, size: 40),
                    const SizedBox(height: 10),
                    Text("Plantilla Activa: $nombrePlantilla", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: Colors.purple,
                        onPressed: () => _abrirFormularioRevision(context, parametros),
                        child: const Text("+ Rellenar Revisión", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // --- SECCIÓN 2: HISTORIAL DE REVISIONES ---
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
                  return const Center(child: Text("Aún no has enviado ninguna revisión.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: revisiones.length,
                  itemBuilder: (context, index) {
                    final rev = revisiones[index];
                    final esPendiente = rev.estado == 'pendiente';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: esPendiente ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          child: Icon(esPendiente ? Icons.hourglass_top : Icons.check, color: esPendiente ? Colors.orange : Colors.green),
                        ),
                        title: Text("Revisión del ${rev.fecha.day}/${rev.fecha.month}/${rev.fecha.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(esPendiente ? "Esperando respuesta del coach..." : "¡Revisada!", style: TextStyle(color: esPendiente ? Colors.orange : Colors.green, fontSize: 12)),
                        children: [
                          const Divider(),
                          // Mostrar datos enviados
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Tus Datos:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                                const SizedBox(height: 8),
                                ...rev.valoresParametros.entries.map((e) => Text("• ${e.key}: ${e.value}", style: const TextStyle(fontSize: 14))),
                                
                                const SizedBox(height: 16),
                                const Text("Tus Sensaciones:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                                Text(rev.sensacionesCliente.isEmpty ? "No escribiste nada." : rev.sensacionesCliente, style: const TextStyle(fontStyle: FontStyle.italic)),
                                
                                // Mostrar respuesta del coach si ya la hay
                                if (!esPendiente && rev.respuestaCoach.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("👨‍🏫 Respuesta del Coach:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                        const SizedBox(height: 4),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- MODAL DINÁMICO PARA RELLENAR LA REVISIÓN ---
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

  // --- NUEVO: LISTA DE FOTOS ---
  List<File> _fotosSeleccionadas = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    for (String param in widget.parametrosAsignados) {
      _controllersParametros[param] = TextEditingController();
    }
  }

  // --- NUEVO: FUNCIÓN PARA ELEGIR FOTOS ---
  Future<void> _elegirFotos() async {
    // Añadimos imageQuality: 50 para que la foto pese la mitad sin perder apenas nitidez
    final List<XFile> imagenes = await _picker.pickMultiImage(
      imageQuality: 50, 
    );
    
    if (imagenes.isNotEmpty) {
      setState(() {
        _fotosSeleccionadas.addAll(imagenes.map((e) => File(e.path)));
        // Limitamos a un máximo de 5 fotos
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
      // --- NUEVO: SUBIR FOTOS A STORAGE PRIMERO ---
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

      // GUARDAR TODO EN FIRESTORE
      final data = {
        'fecha': FieldValue.serverTimestamp(),
        'valores_parametros': valoresFinales,
        'fotos_url': urlsFotos, // Aquí van los links de las fotos
        'sensaciones_cliente': _sensacionesController.text,
        'respuesta_coach': '',
        'estado': 'pendiente',
      };

      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).collection('revisiones').add(data);
          
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Revisión enviada. ¡Gran trabajo!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error enviando revisión: $e");
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al enviar: $e"), backgroundColor: Colors.red),
        );
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
                  }).toList(),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("2. Fotos de Progreso", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text("${_fotosSeleccionadas.length}/5", style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // --- LA GALERÍA DE FOTOS DEL CLIENTE ---
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