import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart';
import '../../../../../config/theme.dart';

class DietaTab extends StatelessWidget {
  final Cliente cliente;

  const DietaTab({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CABECERA MACROS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("OBJETIVO DIARIO", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil_circle_fill, size: 24, color: AppTheme.secondaryOrange),
              onPressed: () => print("Editar macros"),
            ),
          ],
        ),
        
        // TARJETA DE MACROS
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("2.450", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, height: 1)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("Kcal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroIndicador(titulo: "Proteína", gramos: "160g", color: Colors.redAccent),
                  _MacroIndicador(titulo: "Carbos", gramos: "280g", color: Colors.green),
                  _MacroIndicador(titulo: "Grasas", gramos: "75g", color: Colors.orangeAccent),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 32),

        // COMIDAS DEL DÍA
        const Text("PLAN DE COMIDAS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        
        _buildComidaCard(
          comida: "Desayuno",
          hora: "08:00",
          descripcion: "Avena con proteína y arándanos",
          kcal: "450 kcal",
        ),
        _buildComidaCard(
          comida: "Comida",
          hora: "14:30",
          descripcion: "Arroz basmati con pollo a la plancha y aguacate",
          kcal: "750 kcal",
        ),
        _buildComidaCard(
          comida: "Cena",
          hora: "21:00",
          descripcion: "Salmón al horno con patata asada y espárragos",
          kcal: "620 kcal",
        ),
      ],
    );
  }

  Widget _buildComidaCard({required String comida, required String hora, required String descripcion, required String kcal}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightBlue, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(comida, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                Row(
                  children: [
                    const Icon(CupertinoIcons.clock, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(hora, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(descripcion, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.mediumBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(kcal, style: const TextStyle(color: AppTheme.mediumBlue, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class _MacroIndicador extends StatelessWidget {
  final String titulo;
  final String gramos;
  final Color color;

  const _MacroIndicador({required this.titulo, required this.gramos, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(gramos, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}