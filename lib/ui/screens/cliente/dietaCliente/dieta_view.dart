import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/dieta_model.dart'; 
import '../../../../config/theme.dart';

class DietaCliente extends StatelessWidget {
  const DietaCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error: No hay usuario logueado")));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Mi Nutrición", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('dietas')
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("Tu entrenador aún no te ha\nasignado una dieta.", 
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final dietas = snapshot.data!.docs.map((doc) => Dieta.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dietas.length,
            itemBuilder: (context, index) {
              return _buildCardDietaCliente(dietas[index]);
            },
          );
        },
      ),
    );
  }

  // --- LA TARJETA PRINCIPAL DESPLEGABLE ---
  Widget _buildCardDietaCliente(Dieta dieta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        initiallyExpanded: true, 
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(dieta.tipo == 'macros' ? Icons.pie_chart : Icons.restaurant, color: Colors.green),
        ),
        title: Text(dieta.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
        subtitle: Text(
          dieta.tipo == 'macros' ? 'Objetivos Diarios (IIFYM)' : (dieta.tipo == 'cerrada' ? 'Menú Cerrado' : 'Dieta por Porciones'), 
          style: const TextStyle(color: Colors.grey, fontSize: 12)
        ),
        children: [
          if (dieta.notasGenerales.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text("💡 Nota del Coach: ${dieta.notasGenerales}", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ),
          
          // --- AQUÍ OCURRE LA MAGIA DEL CAMALEÓN ---
          if (dieta.tipo == 'macros') 
            _buildVistaMacros(dieta)
          else 
            _buildVistaComidas(dieta),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- DISEÑO: SI LA DIETA ES DE MACROS ---
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

  // --- DISEÑO: SI LA DIETA ES MENÚ O PORCIONES ---
  Widget _buildVistaComidas(Dieta dieta) {
    if (dieta.comidas == null || dieta.comidas!.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text("No hay comidas registradas"));
    }

    return Column(
      children: dieta.comidas!.map((comida) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comida.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const Divider(),
              ...comida.elementos.map((item) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3))),
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