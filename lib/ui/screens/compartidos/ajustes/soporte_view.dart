import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme.dart';

class SoporteView extends StatefulWidget {
  final String rol;
  const SoporteView({super.key, required this.rol});

  @override
  State<SoporteView> createState() => _SoporteViewState();
}

class _SoporteViewState extends State<SoporteView> {
  int? _preguntaAbierta;

  // preguntas frecuentes diferenciadas por rol
  static const List<Map<String, String>> _faqCoach = [
    {
      'q': '¿Cómo añado un nuevo cliente?',
      'a': 'Ve a la sección "Clientes" y comparte tu código de entrenador. El cliente debe introducirlo al registrarse o desde su perfil para vincularse contigo automáticamente.',
    },
    {
      'q': '¿Cómo creo y asigno una rutina?',
      'a': 'En "Ajustes → Rutinas" puedes crear plantillas de entrenamiento. Una vez creadas, entra en el perfil de un cliente y asígnale la rutina desde la pestaña "Entreno".',
    },
    {
      'q': '¿Cómo gestiono las revisiones?',
      'a': 'Desde "Ajustes → Revisiones" creas plantillas de revisión con los campos que necesites. Asígnalas al cliente desde su perfil. El cliente las rellenará periódicamente y tú verás los datos en tiempo real.',
    },
    {
      'q': '¿Cómo funciona el pago de mi suscripción?',
      'a': 'El pago se procesa de forma segura a través de PayPal en modo sandbox (pruebas). En producción, al seleccionar un plan se abrirá Safari con la pasarela de PayPal. Una vez completado el pago, tu plan se activa automáticamente.',
    },
    {
      'q': '¿Qué ocurre si no renuevo mi plan?',
      'a': 'Cuando tu suscripción venza, pasarás automáticamente al plan Cantera (gratuito, hasta 3 clientes). Tus datos no se pierden; solo se limita el número de clientes activos hasta que renueves.',
    },
    {
      'q': '¿Puedo cambiar de plan en cualquier momento?',
      'a': 'Sí. Si mejoras tu plan a mitad de período, solo pagas la diferencia prorrata por los días restantes. Si lo cambias a un plan inferior, el cambio es gratuito y mantiene tu fecha de vencimiento actual.',
    },
    {
      'q': '¿Cómo edito mis tarifas para los clientes?',
      'a': 'Ve a "Mi Despacho → Mis Tarifas". Toca sobre cualquier tarifa para editar el nombre, descripción, precio y período de gracia.',
    },
  ];

  static const List<Map<String, String>> _faqCliente = [
    {
      'q': '¿Cómo veo mi rutina de entrenamiento?',
      'a': 'Ve a la pestaña "Entreno" en el menú inferior. Allí encontrarás tu rutina actual asignada por tu entrenador con todos los ejercicios y series.',
    },
    {
      'q': '¿Cómo relleno mi revisión?',
      'a': 'Entra en la pestaña "Revisión". Verás los campos que tu entrenador ha definido (peso, medidas, etc.). Rellena los datos y guarda; tu entrenador los verá al instante.',
    },
    {
      'q': '¿Cómo contacto con mi entrenador?',
      'a': 'Usa la pestaña "Chat" para enviarle mensajes directos. También puedes ver sus datos de contacto en su perfil profesional.',
    },
    {
      'q': '¿Cómo actualizo mis datos personales?',
      'a': 'Ve a "Ajustes → Editar ficha". Podrás actualizar tu nombre, fecha de nacimiento, altura, peso objetivo y otros datos clínicos.',
    },
    {
      'q': '¿Cómo funciona el pago a mi entrenador?',
      'a': 'El pago de tu tarifa se gestiona directamente con tu entrenador fuera de la app. CoachOS muestra el estado de tu tarifa (activa / pendiente) según lo que configure tu entrenador, pero no procesa el cobro.',
    },
    {
      'q': '¿Mis datos son privados?',
      'a': 'Sí. Tus datos de salud y progreso solo son visibles para ti y tu entrenador asignado. CoachOS nunca comparte tu información con terceros.',
    },
    {
      'q': '¿Qué hago si me han asignado la rutina incorrecta?',
      'a': 'Contacta con tu entrenador a través del chat de la app. Solo él puede modificar o reasignar tus planes de entrenamiento y dieta.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool esCoach = widget.rol == 'entrenador';
    final faqs = esCoach ? _faqCoach : _faqCliente;

    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: const Text('Soporte'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.arrow_left, color: AppTheme.primaryBlue),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // banner de bienvenida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.mediumBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(CupertinoIcons.headphones, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Centro de ayuda',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Encuentra respuestas rápidas o contáctanos.',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // título FAQ
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Preguntas frecuentes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // preguntas expandibles
          Container(
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: List.generate(faqs.length, (i) {
                final abierta = _preguntaAbierta == i;
                final esPrimera = i == 0;
                final esUltima = i == faqs.length - 1;

                return Column(
                  children: [
                    if (!esPrimera)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    InkWell(
                      onTap: () => setState(
                        () => _preguntaAbierta = abierta ? null : i,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: esPrimera ? const Radius.circular(20) : Radius.zero,
                        bottom: esUltima && !abierta ? const Radius.circular(20) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: abierta
                                    ? AppTheme.primaryBlue.withOpacity(0.1)
                                    : AppTheme.lightBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                abierta
                                    ? CupertinoIcons.minus
                                    : CupertinoIcons.plus,
                                size: 14,
                                color: abierta ? AppTheme.primaryBlue : AppTheme.mediumBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faqs[i]['q']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: abierta ? AppTheme.primaryBlue : const Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: abierta
                          ? Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                              child: Text(
                                faqs[i]['a']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF718096),
                                  height: 1.6,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // contacto
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Contacto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
          ),

          Container(
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                _buildContactoTile(
                  icono: CupertinoIcons.mail_solid,
                  color: AppTheme.primaryBlue,
                  titulo: 'Envíanos un email',
                  subtitulo: 'soporte@coachos.app',
                  onTap: () => _abrirUrl('mailto:soporte@coachos.app'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactoTile({
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, color: color, size: 20),
      ),
      title: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
      trailing: const Icon(CupertinoIcons.arrow_up_right, size: 14, color: Color(0xFFADB5BD)),
      onTap: onTap,
    );
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
