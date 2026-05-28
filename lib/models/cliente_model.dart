import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String id;
  final String nombre;
  final String apellidos;
  final int edad;
  final String telefono;
  final String estado;
  final bool cuotaPagada;
  final String entrenadorId;
  final String sexo;
  final String lesionesPrevias;
  final String patologias;
  final String ultimoMensaje;
  final DateTime fechaUltimoMensaje;
  final DateTime fechaUltimoPago;
  final int precioTarifa;
  final String tipoTarifa;
  // lead | activo
  final String estadoOnboarding;

  Cliente({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.edad,
    required this.telefono,
    required this.estado,
    required this.cuotaPagada,
    required this.entrenadorId,
    required this.sexo,
    required this.lesionesPrevias,
    required this.patologias,
    required this.ultimoMensaje,
    required this.fechaUltimoMensaje,
    required this.fechaUltimoPago,
    required this.precioTarifa,
    required this.tipoTarifa,
    this.estadoOnboarding = 'activo',
  });

  factory Cliente.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime fechaParseada = DateTime.fromMillisecondsSinceEpoch(0);
    var fechaData = data['fecha_ultimo_mensaje'];
    if (fechaData != null) {
      if (fechaData is Timestamp) {
        fechaParseada = fechaData.toDate();
      } else if (fechaData is String && fechaData.isNotEmpty) {
        fechaParseada = DateTime.tryParse(fechaData) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    // sin registro de pago → se asume 31 días vencido
    DateTime fechaPagoParseada = DateTime.now().subtract(const Duration(days: 31));
    var fechaPagoData = data['fecha_ultimo_pago'];
    if (fechaPagoData != null && fechaPagoData is Timestamp) {
      fechaPagoParseada = fechaPagoData.toDate();
    }

    return Cliente(
      id: id,
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      edad: data['edad'] ?? 0,
      telefono: data['telefono'] ?? '',
      estado: data['estado'] ?? 'Activo',
      cuotaPagada: data['cuota_pagada'] ?? false,
      entrenadorId: data['entrenador_id'] ?? '',
      sexo: data['sexo'] ?? '',
      lesionesPrevias: data['lesiones_previas'] ?? '',
      patologias: data['patologias'] ?? '',
      ultimoMensaje: data['ultimo_mensaje'] ?? '',
      fechaUltimoMensaje: fechaParseada,
      fechaUltimoPago: fechaPagoParseada,
      precioTarifa: data['precio_tarifa'] ?? 0,
      tipoTarifa: data['tipo_tarifa'] ?? '',
      estadoOnboarding: data['estado_onboarding'] ?? 'activo',
    );
  }

  double get precioTarifaDouble => precioTarifa.toDouble();

  // semáforo unificado: activo | aviso | inactivo
  String get estadoSuscripcionReal {
    int diasDesdePago = DateTime.now().difference(fechaUltimoPago).inDays;
    if (diasDesdePago < 30) return 'activo';
    if (diasDesdePago <= 33) return 'aviso';
    return 'inactivo';
  }
}
