import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../services/database_service.dart';
import '../../../models/tarifa_model.dart';
import '../../../config/theme.dart';

class TarifasView extends StatelessWidget {
  const TarifasView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: const Text(
          "Mis Tarifas", 
          style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondaryOrange,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
        onPressed: () => _mostrarModalCrear(context),
      ),
      body: StreamBuilder<List<Tarifa>>(
        stream: DatabaseService().getTarifas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          
          final tarifas = snapshot.data ?? [];

          if (tarifas.isEmpty) {
            return const Center(
              child: Text(
                "No tienes tarifas creadas.\nPulsa + para añadir una.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tarifas.length,
            itemBuilder: (context, index) {
              final tarifa = tarifas[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tarifa.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                          Text("${tarifa.precio}€", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.secondaryOrange)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(tarifa.descripcion, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.time, size: 16, color: AppTheme.mediumBlue),
                              const SizedBox(width: 6),
                              Text("Gracia: ${tarifa.diasGracia} días", style: const TextStyle(color: AppTheme.mediumBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          // --- NUEVAS ACCIONES: SWITCH VISIBILIDAD + TRASH ---
                          Row(
                            children: [
                              Text(tarifa.esVisible ? "Visible" : "Oculta", 
                                style: TextStyle(fontSize: 12, color: tarifa.esVisible ? Colors.green : Colors.grey)),
                              const SizedBox(width: 4),
                              Transform.scale(
                                scale: 0.7,
                                child: CupertinoSwitch(
                                  value: tarifa.esVisible,
                                  activeColor: AppTheme.primaryBlue,
                                  onChanged: (bool val) {
                                    DatabaseService().actualizarVisibilidadTarifa(tarifa.id, val);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmarEliminacion(context, tarifa),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarModalCrear(BuildContext context) {
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    final descController = TextEditingController();
    final graciaController = TextEditingController(text: "3");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nueva Tarifa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            const SizedBox(height: 20),
            _buildLabel("Nombre del Plan"),
            CupertinoTextField(
              controller: nombreController, 
              placeholder: "Ej: Plan Mensual Oro",
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Precio (€)"),
                      CupertinoTextField(
                        controller: precioController, 
                        placeholder: "Ej: 60",
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Días de Gracia"),
                      CupertinoTextField(
                        controller: graciaController, 
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel("Descripción"),
            CupertinoTextField(
              controller: descController, 
              placeholder: "Escribe qué incluye...",
              maxLines: 3,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.lightBlue, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () {
                  if (nombreController.text.isNotEmpty && precioController.text.isNotEmpty) {
                    // Al crearla, siempre pasamos true (o dejas que el DatabaseService lo gestione)
                    DatabaseService().crearTarifa(
                      nombreController.text,
                      int.parse(precioController.text),
                      descController.text,
                      int.tryParse(graciaController.text) ?? 3,
                      true, 
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Guardar Tarifa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  void _confirmarEliminacion(BuildContext context, Tarifa tarifa) async {
    final QuerySnapshot clientesConTarifa = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('idTarifa', isEqualTo: tarifa.id)
        .limit(1)
        .get();

    if (clientesConTarifa.docs.isNotEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Acción Bloqueada"),
          content: const Text("No puedes borrar esta tarifa porque hay clientes asignados a ella.\n\nDesactiva su visibilidad para que no se registren nuevos clientes con este precio."),
          actions: [
            CupertinoDialogAction(
              child: const Text("Entendido"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Eliminar Tarifa"),
        content: Text("¿Borrar '${tarifa.nombre}'? Esta acción es irreversible."),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await DatabaseService().eliminarTarifa(tarifa.id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
          CupertinoDialogAction(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}