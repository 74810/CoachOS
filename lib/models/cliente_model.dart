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
  
  // En base de datos están como String
  final String ultimoMensaje;
  final String fechaUltimoMensaje;
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
    return Cliente(
      id: id,
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '', 
      edad: data['edad'] ?? 0,
      telefono: data['telefono'] ?? '',
      estado: data['estado'] ?? 'Activo',
      cuotaPagada: data['cuota_pagada'] ?? false,
      entrenadorId: data['entrenador_id'] ?? '', // <--- Cambiado para coincidir con el inyector
      sexo: data['sexo'] ?? '',
      lesionesPrevias: data['lesiones_previas'] ?? '',
      patologias: data['patologias'] ?? '',
      ultimoMensaje: data['ultimo_mensaje'] ?? '',
      fechaUltimoMensaje: data['fecha_ultimo_mensaje'] ?? '',
      precioTarifa: data['precio_tarifa'] ?? 0,
      tipoTarifa: data['tipo_tarifa'] ?? '',
    );
  }

double get precioTarifaDouble {
    return precioTarifa.toDouble();
  }
}