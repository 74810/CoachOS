import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/dieta_model.dart'; 
import '../../../config/theme.dart';

class DietaCliente extends StatelessWidget {
  const DietaCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error: No hay usuario logueado")));
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .collection('dietas')
              .orderBy('fecha_creacion', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }

            final dietas = snapshot.hasData
                ? snapshot.data!.docs.map((doc) => Dieta.fromFirestore(doc)).toList()
                : <Dieta>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              children: [
                const Text('Mi Nutrición',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                const SizedBox(height: 24),

                if (dietas.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.doc_text_fill, size: 40, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(height: 16),
                        const Text('Sin plan asignado',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                        const SizedBox(height: 8),
                        Text('Tu entrenador aún no te ha asignado ningún plan de nutrición.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4)),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('PLANES ASIGNADOS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
                  ),
                  ...dietas.map((d) => _buildCardDietaCliente(d)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  //TARJETA PRINCIPAL DESPLEGABLE
  Widget _buildCardDietaCliente(Dieta dieta) {
    final IconData icono = dieta.tipo == 'macros' ? CupertinoIcons.chart_pie_fill : CupertinoIcons.square_list_fill;
    final String subtitulo = dieta.tipo == 'macros'
        ? 'Objetivos Diarios (IIFYM)'
        : (dieta.tipo == 'cerrada' ? 'Menú Cerrado' : 'Dieta por Porciones');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: true,
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppTheme.secondaryOrange, size: 22),
          ),
          title: Text(dieta.titulo,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.primaryBlue)),
          subtitle: Text(subtitulo,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
          children: [
            if (dieta.notasGenerales.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill, color: AppTheme.primaryBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${dieta.notasGenerales}',
                          style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            if (dieta.tipo == 'macros') _buildVistaMacros(dieta) else _buildVistaComidas(dieta),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  //DISEÑO: SI LA DIETA ES DE MACROS
  Widget _buildVistaMacros(Dieta dieta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _macroCirculo("Kcal", dieta.kcal?.toString() ?? "-", Colors.orange),
          _macroCirculo("Pro", "${dieta.proteina ?? "-"}g", Colors.redAccent),
          _macroCirculo("Carbo", "${dieta.carbos ?? "-"}g", Colors.blueAccent),
          _macroCirculo("Grasa", "${dieta.grasas ?? "-"}g", Colors.amber),
        ],
      ),
    );
  }

  Widget _macroCirculo(String titulo, String valor, Color color) {
    return Column(
      children: [
        Container(
          width: 65, height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 4),
            color: Colors.white,
          ),
          child: Center(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 14))),
        ),
        const SizedBox(height: 8),
        Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  //DISEÑO: SI LA DIETA ES MENÚ O PORCIONES
  Widget _buildVistaComidas(Dieta dieta) {
    if (dieta.comidas == null || dieta.comidas!.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text("No hay comidas registradas"));
    }

    return Column(
      children: dieta.comidas!.map((comida) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.clock_fill, size: 14, color: AppTheme.secondaryOrange),
                  const SizedBox(width: 6),
                  Text(comida.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.primaryBlue)),
                ],
              ),
              const SizedBox(height: 10),
              ...comida.elementos.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      decoration: const BoxDecoration(color: AppTheme.secondaryOrange, shape: BoxShape.circle),
                    ),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4))),
                  ],
                ),
              )).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }
}