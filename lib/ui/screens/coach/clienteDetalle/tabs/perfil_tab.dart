import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../models/cliente_model.dart';
import '../../../../../config/theme.dart';
import '../../../../widgets/estadisticas_cliente_widget.dart';

class PerfilTab extends StatelessWidget {
  final Cliente cliente;

  const PerfilTab({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(cliente.id).snapshots(),
      builder: (context, snap) {
        final dataCliente = snap.data?.data() as Map<String, dynamic>? ?? {};
        final List<String> parametros = List<String>.from(dataCliente['parametros_revision'] ?? []);
        final String nombrePlantilla = dataCliente['nombre_plantilla_activa'] ?? '';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // datos del cliente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DATOS DEL CLIENTE", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _FilaDato(
                    titulo: "Edad / Sexo",
                    valor: "${dataCliente['edad'] ?? cliente.edad} años • ${dataCliente['sexo'] ?? cliente.sexo}",
                  ),
                  const Divider(color: AppTheme.lightBlue),
                  _FilaDato(
                    titulo: "Lesiones y\nPatologías",
                    valor: () { final v = (dataCliente['lesiones'] as String?) ?? ''; return v.isEmpty ? 'Ninguna registrada' : v; }(),
                  ),
                  const Divider(color: AppTheme.lightBlue),
                  _FilaDato(
                    titulo: "Alergias e\nIntolerancias",
                    valor: () { final v = (dataCliente['alergias'] as String?) ?? ''; return v.isEmpty ? 'Ninguna registrada' : v; }(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // aviso si no hay plantilla asignada
            if (parametros.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.doc_chart, color: Colors.orange, size: 36),
                    const SizedBox(height: 10),
                    const Text("Sin plantilla de revisión asignada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text("Ve a la pestaña Revisión y asigna una plantilla al cliente para ver sus gráficas de evolución.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ] else ...[
              if (nombrePlantilla.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.doc_chart_fill, color: Colors.purple, size: 16),
                      const SizedBox(width: 6),
                      Text(nombrePlantilla, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: EstadisticasClienteWidget(clienteId: cliente.id),
              ),
            ],

            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

}

// fila de dato del perfil
class _FilaDato extends StatelessWidget {
  final String titulo;
  final String valor;
  const _FilaDato({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
        Expanded(child: Text(valor, style: const TextStyle(color: Colors.black87))),
      ],
    );
  }
}
