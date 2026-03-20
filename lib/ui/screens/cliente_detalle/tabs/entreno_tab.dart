import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../models/cliente_model.dart';
import '../../../../config/theme.dart';

class EntrenoTab extends StatelessWidget {
  final Cliente cliente;

  const EntrenoTab({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // CABECERA Y BOTÓN AÑADIR
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("RUTINA ACTUAL", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Row(
                children: [
                  Icon(CupertinoIcons.add_circled_solid, size: 20, color: AppTheme.secondaryOrange),
                  SizedBox(width: 4),
                  Text("Asignar", style: TextStyle(color: AppTheme.secondaryOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              onPressed: () => print("Abrir biblioteca de rutinas"),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // LISTA DE DÍAS DE ENTRENAMIENTO
        _buildDiaEntreno(dia: "Lunes", titulo: "Pecho y Tríceps", ejercicios: 6, completado: true),
        _buildDiaEntreno(dia: "Miércoles", titulo: "Espalda y Bíceps", ejercicios: 5, completado: false),
        _buildDiaEntreno(dia: "Viernes", titulo: "Pierna Completa", ejercicios: 7, completado: false),
        
        const SizedBox(height: 24),

        // HISTORIAL / MÉTRICAS RÁPIDAS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.flame_fill, color: AppTheme.secondaryOrange, size: 20),
                  SizedBox(width: 8),
                  Text("Estadísticas del mes", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _EstadisticaRapida(valor: "12", etiqueta: "Sesiones"),
                  _EstadisticaRapida(valor: "85%", etiqueta: "Cumplimiento"),
                  _EstadisticaRapida(valor: "2.4k", etiqueta: "Volumen (kg)"),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiaEntreno({required String dia, required String titulo, required int ejercicios, required bool completado}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: completado ? Colors.green.withOpacity(0.1) : AppTheme.lightBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            completado ? CupertinoIcons.checkmark_alt : Icons.fitness_center, 
            color: completado ? Colors.green : AppTheme.primaryBlue,
          ),
        ),
        title: Text(dia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
        subtitle: Text("$titulo • $ejercicios ejercicios", style: const TextStyle(fontSize: 13)),
        trailing: const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 18),
        onTap: () => print("Ver detalles del entreno del $dia"),
      ),
    );
  }
}

class _EstadisticaRapida extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _EstadisticaRapida({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 4),
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}