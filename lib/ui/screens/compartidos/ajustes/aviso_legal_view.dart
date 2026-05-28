import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class AvisoLegalView extends StatelessWidget {
  const AvisoLegalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: const Text('Aviso Legal'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.arrow_left, color: AppTheme.primaryBlue),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // cabecera
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
                  child: const Icon(CupertinoIcons.doc_text_fill, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documentos legales',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Última actualización: mayo 2025',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // secciones legales
          _buildSeccion(
            titulo: '1. Datos del Responsable',
            contenido:
                'En cumplimiento del artículo 10 de la Ley 34/2002, de Servicios de la Sociedad de la Información y Comercio Electrónico, se informa:\n\n'
                '• Denominación social: CoachOS SL (en constitución)\n'
                '• Actividad: Plataforma digital de gestión para entrenadores personales\n'
                '• Email de contacto: legal@coachos.app\n'
                '• Dominio web: coachos.app',
          ),

          _buildSeccion(
            titulo: '2. Objeto y Ámbito de Aplicación',
            contenido:
                'CoachOS es una plataforma B2B2C que facilita la gestión de clientes, planes de entrenamiento, dietas y revisiones físicas entre entrenadores personales y sus clientes.\n\n'
                'El uso de la aplicación implica la aceptación plena y sin reservas de las presentes condiciones legales.',
          ),

          _buildSeccion(
            titulo: '3. Protección de Datos (RGPD)',
            contenido:
                'De conformidad con el Reglamento (UE) 2016/679 (RGPD) y la Ley Orgánica 3/2018 (LOPDGDD):\n\n'
                '• Responsable del tratamiento: CoachOS SL\n'
                '• Finalidad: Prestación del servicio de gestión deportiva, comunicaciones entre entrenador y cliente, facturación y soporte.\n'
                '• Legitimación: Ejecución del contrato de servicio y consentimiento del interesado.\n'
                '• Destinatarios: No se ceden datos a terceros salvo obligación legal. Firebase (Google LLC) actúa como encargado del tratamiento bajo cláusulas contractuales estándar.\n'
                '• Derechos: Acceso, rectificación, supresión, portabilidad y oposición escribiendo a privacidad@coachos.app.',
          ),

          _buildSeccion(
            titulo: '4. Datos de Salud',
            contenido:
                'La aplicación puede recopilar datos de categoría especial (datos de salud) como peso, medidas corporales y marcadores físicos. Estos datos:\n\n'
                '• Solo son accesibles por el usuario y su entrenador vinculado.\n'
                '• Se almacenan cifrados en servidores de Google Firebase (región europe-west).\n'
                '• No se usan con fines publicitarios ni se comparten con terceros.\n'
                '• Se eliminan completamente al borrar la cuenta.',
          ),

          _buildSeccion(
            titulo: '5. Condiciones del Servicio',
            contenido:
                '• El plan Cantera es gratuito e incluye hasta 3 clientes activos.\n'
                '• Los planes de pago (Rookie, All-Star, Hall of Fame) se facturan mensualmente a través de PayPal.\n'
                '• El incumplimiento de pago conlleva la degradación automática al plan Cantera sin pérdida de datos.\n'
                '• CoachOS se reserva el derecho de modificar precios con un preaviso de 30 días.\n'
                '• No se ofrecen reembolsos por períodos parciales salvo incidencia técnica imputable a CoachOS.',
          ),

          _buildSeccion(
            titulo: '6. Propiedad Intelectual',
            contenido:
                'Todos los contenidos de CoachOS (diseño, código, textos, logotipos) son propiedad de CoachOS SL y están protegidos por la legislación de propiedad intelectual española e internacional.\n\n'
                'Los contenidos generados por entrenadores (rutinas, dietas, revisiones) son propiedad del entrenador que los crea. CoachOS únicamente actúa como plataforma de almacenamiento y distribución.',
          ),

          _buildSeccion(
            titulo: '7. Responsabilidad',
            contenido:
                'CoachOS no es un servicio médico ni sanitario. Los planes de entrenamiento y nutrición son responsabilidad del entrenador que los diseña.\n\n'
                'CoachOS no se responsabiliza de daños derivados del seguimiento incorrecto de los planes, lesiones, o decisiones tomadas por los usuarios con base en la información de la aplicación.',
          ),

          _buildSeccion(
            titulo: '8. Cookies y Almacenamiento Local',
            contenido:
                'La aplicación móvil utiliza almacenamiento local (shared preferences) únicamente para mantener la sesión activa del usuario. No se usan cookies de rastreo ni tecnologías de seguimiento publicitario.',
          ),

          _buildSeccion(
            titulo: '9. Ley Aplicable y Jurisdicción',
            contenido:
                'Las presentes condiciones se rigen por la legislación española. Para la resolución de cualquier conflicto, las partes se someten a los Juzgados y Tribunales de España, con renuncia expresa a cualquier otro fuero.',
          ),

          const SizedBox(height: 24),

          // footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.envelope, color: AppTheme.mediumBlue, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Para consultas legales: legal@coachos.app',
                    style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSeccion({required String titulo, required String contenido}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryBlue, size: 16),
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          iconColor: AppTheme.mediumBlue,
          collapsedIconColor: AppTheme.mediumBlue,
          children: [
            Text(
              contenido,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5568),
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
