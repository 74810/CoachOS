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
  // CAMBIO 1: Ahora es de tipo DateTime para poder ordenar los chats correctamente
  final DateTime fechaUltimoMensaje; 
  final int precioTarifa;
  final String tipoTarifa;

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
    required this.precioTarifa,
    required this.tipoTarifa,
  });

  factory Cliente.fromFirestore(Map<String, dynamic> data, String id) {
    // CAMBIO 2: Conversor inteligente de fechas (Timestamp de Firebase a DateTime de Dart)
    DateTime fechaParseada = DateTime.fromMillisecondsSinceEpoch(0);
    var fechaData = data['fecha_ultimo_mensaje'];
    
    if (fechaData != null) {
      if (fechaData is Timestamp) {
        fechaParseada = fechaData.toDate();
      } else if (fechaData is String && fechaData.isNotEmpty) {
        fechaParseada = DateTime.tryParse(fechaData) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
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
      fechaUltimoMensaje: fechaParseada, // Asignamos la fecha parseada
      precioTarifa: data['precio_tarifa'] ?? 0,
      tipoTarifa: data['tipo_tarifa'] ?? '',
    );
  }

  double get precioTarifaDouble {
    return precioTarifa.toDouble();
  }
}