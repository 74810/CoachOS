import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/theme.dart';
import 'home_view.dart'; // Importante para el controlador de tabs

class PrincipalView extends StatelessWidget {
  const PrincipalView({super.key});

  void _mostrarPopupPago(BuildContext context, String uid) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Pago de Tarifa"),
        content: const Text("Tu tarifa ha caducado o está pendiente. ¿Deseas simular el pago ahora para reactivarla?"),
        actions: [
          CupertinoDialogAction(child: const Text("Cancelar"), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Simular Pago"),
            onPressed: () {
              Navigator.pop(context); 
              _procesarPagoAsync(context, uid); 
            },
          ),
        ],
      ),
    );
  }

  Future<void> _procesarPagoAsync(BuildContext context, String uid) async {
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 20)));
    try {
      await Future.delayed(const Duration(seconds: 2)); 
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'fecha_ultimo_pago': FieldValue.serverTimestamp(),
      });
      if (context.mounted) Navigator.pop(context); 
      scaffold.showSnackBar(const SnackBar(content: Text("¡Pago realizado con éxito!"), backgroundColor: Colors.green));
    } catch (e) {
      if (context.mounted) Navigator.pop(context); 
      scaffold.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  DateTime _calcularUltimaRevision(Map<String, dynamic> data, int frecuencia) {
    if (data['fecha_ultima_revision'] != null) {
      return (data['fecha_ultima_revision'] as Timestamp).toDate();
    } else if (data.containsKey('fecha_ultima_revision')) {
      return DateTime.now(); 
    } else {
      int diasRestar = frecuencia == 0 ? 1 : frecuencia + 1; // Ajuste para modo libre
      return DateTime.now().subtract(Duration(days: diasRestar));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Error"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        // PAGOS
        DateTime fechaPagoParseada = DateTime.now().subtract(const Duration(days: 31)); 
        if (data['fecha_ultimo_pago'] != null) fechaPagoParseada = (data['fecha_ultimo_pago'] as Timestamp).toDate();
        int diasDesdePago = DateTime.now().difference(fechaPagoParseada).inDays;
        bool tocaPagar = diasDesdePago >= 30;

        // REVISIONES Y MODO LIBRE
        int frecuencia = data['frecuencia_revisiones'] ?? 15;
        bool esLibre = frecuencia == 0; // MAGIA: Comprobamos si es libre

        DateTime ultimaRev = _calcularUltimaRevision(data, frecuencia);
        DateTime fechaObjetivo = ultimaRev.add(Duration(days: frecuencia));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("¡Hola, ${data['nombre'] ?? 'Atleta'}!", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              const Text("Este es tu resumen de hoy", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 30),

              // WIDGET PAGOS
              if (tocaPagar)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade200)),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.creditcard_fill, color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      const Text("¡Tarifa No Pagada!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 5),
                      const Text("Tu suscripción ha caducado. Pulsa el botón para simular el pago y reactivarla.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontSize: 14)),
                      const SizedBox(height: 15),
                      SizedBox(width: double.infinity, child: CupertinoButton(color: Colors.red, onPressed: () => _mostrarPopupPago(context, user.uid), child: const Text("PAGAR TARIFA", style: TextStyle(fontWeight: FontWeight.bold))))
                    ],
                  ),
                )
              else 
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 40),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tarifa Pagada", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Todo al día. Próximo pago en ${30 - diasDesdePago} días.", style: const TextStyle(color: Colors.black87, fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

              // WIDGET REVISIÓN EN VIVO
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, _) {
                  final ahora = DateTime.now();
                  
                  // MAGIA: Si es libre, siempre toca revisión.
                  final tocaRevision = esLibre || ahora.isAfter(fechaObjetivo);
                  final diferencia = esLibre ? Duration.zero : fechaObjetivo.difference(ahora);

                  return Container(
                    height: 220, 
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tocaRevision ? Colors.purple.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: tocaRevision ? Colors.purple.shade200 : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.timer, color: tocaRevision ? Colors.purple : AppTheme.primaryBlue, size: 40),
                        const SizedBox(height: 10),
                        
                        Text(
                          tocaRevision ? (esLibre ? "REVISIÓN LIBRE" : "¡TOCA REVISIÓN!") : "PRÓXIMA REVISIÓN", 
                          style: TextStyle(color: tocaRevision ? Colors.purple : AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                        
                        const SizedBox(height: 15),
                        
                        if (tocaRevision) ...[
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onPressed: () {
                                HomeViewCliente.of(context).cambiarTab(3); 
                              },
                              child: const Text("IR A MI REVISIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ] else ...[
                          const Text("Se abrirá en:", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 5),
                          Text("${diferencia.inDays}d, ${diferencia.inHours % 24}h, ${diferencia.inMinutes % 60}m, ${diferencia.inSeconds % 60}s", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryBlue)),
                        ],
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
        );
      },
    );
  }
}