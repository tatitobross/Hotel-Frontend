import 'package:flutter/material.dart';

enum HotelModule { types, rooms, guests, reservations, consumptions }

enum FieldType { text, number, date, active, typeRelation, roomRelation, guestRelation, reservationRelation, roomState, category }

class FieldSpec {
  const FieldSpec(this.key, this.label, {this.required = false, this.type = FieldType.text});
  final String key;
  final String label;
  final bool required;
  final FieldType type;
}

class ModuleInfo {
  const ModuleInfo(this.title, this.singular, this.path, this.icon, this.fields, this.main, this.detail);
  final String title;
  final String singular;
  final String path;
  final IconData icon;
  final List<FieldSpec> fields;
  final String Function(Map<String, dynamic>) main;
  final String Function(Map<String, dynamic>) detail;
}

String value(Map<String, dynamic>? item, String key, [String fallback = '—']) {
  final data = item?[key];
  return data == null || data.toString().isEmpty ? fallback : data.toString();
}

Map<String, dynamic>? mapValue(Map<String, dynamic> item, String key) {
  final data = item[key];
  return data is Map ? Map<String, dynamic>.from(data) : null;
}

String stateText(dynamic state) {
  const names = <String, String>{
    'disponible': 'Disponible', 'ocupada': 'Ocupada', 'limpieza': 'Limpieza', 'mantenimiento': 'Mantenimiento',
    'reservada': 'Reservada', 'en_estadia': 'En estadía', 'finalizada': 'Finalizada', 'cancelada': 'Cancelada',
    'restaurante': 'Restaurante', 'bar': 'Bar', 'lavanderia': 'Lavandería', 'minibar': 'Minibar', 'spa': 'Spa', 'otro': 'Otro',
  };
  return names[state?.toString()] ?? state?.toString() ?? '—';
}

String money(dynamic amount) => 'L ${amount?.toString() ?? '0.00'}';

final hotelModules = <HotelModule, ModuleInfo>{
  HotelModule.types: ModuleInfo('Tipos de habitación', 'Tipo de habitación', '/tipos-habitacion', Icons.category_outlined, const [
    FieldSpec('nombre', 'Nombre', required: true),
    FieldSpec('descripcion', 'Descripción'),
    FieldSpec('capacidad', 'Capacidad', required: true, type: FieldType.number),
    FieldSpec('precio_noche', 'Precio por noche (L.)', required: true, type: FieldType.number),
    FieldSpec('activo', 'Activo', type: FieldType.active),
  ], (item) => value(item, 'nombre'), (item) => '${value(item, 'capacidad')} personas · ${money(item['precio_noche'])} por noche'),
  HotelModule.rooms: ModuleInfo('Habitaciones', 'Habitación', '/habitaciones', Icons.bed_outlined, const [
    FieldSpec('numero', 'Número', required: true),
    FieldSpec('piso', 'Piso', required: true, type: FieldType.number),
    FieldSpec('tipo_habitacion_id', 'Tipo de habitación', required: true, type: FieldType.typeRelation),
    FieldSpec('estado', 'Estado', type: FieldType.roomState),
    FieldSpec('activo', 'Activa', type: FieldType.active),
    FieldSpec('observaciones', 'Observaciones'),
  ], (item) => 'Habitación ${value(item, 'numero')}', (item) => '${value(mapValue(item, 'tipo'), 'nombre', 'Sin tipo')} · ${stateText(value(item, 'estado'))}'),
  HotelModule.guests: ModuleInfo('Huéspedes', 'Huésped', '/huespedes', Icons.people_outline, const [
    FieldSpec('nombre', 'Nombre', required: true),
    FieldSpec('apellido', 'Apellido', required: true),
    FieldSpec('documento', 'DPI / documento', required: true),
    FieldSpec('telefono', 'Teléfono', required: true),
    FieldSpec('correo', 'Correo'),
    FieldSpec('nacionalidad', 'Nacionalidad'),
    FieldSpec('activo', 'Activo', type: FieldType.active),
  ], (item) => '${value(item, 'nombre')} ${value(item, 'apellido')}', (item) => '${value(item, 'documento')} · ${value(item, 'telefono')}'),
  HotelModule.reservations: ModuleInfo('Reservas', 'Reserva', '/reservas', Icons.calendar_month_outlined, const [
    FieldSpec('huesped_id', 'Huésped', required: true, type: FieldType.guestRelation),
    FieldSpec('habitacion_id', 'Habitación', required: true, type: FieldType.roomRelation),
    FieldSpec('fecha_entrada', 'Fecha de entrada (AAAA-MM-DD)', required: true, type: FieldType.date),
    FieldSpec('fecha_salida', 'Fecha de salida (AAAA-MM-DD)', required: true, type: FieldType.date),
    FieldSpec('personas', 'Personas', required: true, type: FieldType.number),
    FieldSpec('observaciones', 'Observaciones'),
  ], (item) => 'Reserva #${value(item, 'id')}', (item) => '${value(mapValue(item, 'huesped'), 'nombre', 'Huésped')} · Hab. ${value(mapValue(item, 'habitacion'), 'numero')} · ${stateText(value(item, 'estado'))}'),
  HotelModule.consumptions: ModuleInfo('Consumos', 'Consumo', '/consumos', Icons.room_service_outlined, const [
    FieldSpec('reserva_id', 'Reserva en estadía', required: true, type: FieldType.reservationRelation),
    FieldSpec('categoria', 'Categoría', required: true, type: FieldType.category),
    FieldSpec('descripcion', 'Descripción', required: true),
    FieldSpec('cantidad', 'Cantidad', required: true, type: FieldType.number),
    FieldSpec('precio_unitario', 'Precio unitario (L.)', required: true, type: FieldType.number),
  ], (item) => value(item, 'descripcion'), (item) => '${stateText(value(item, 'categoria'))} · ${money(item['subtotal'] ?? item['total'])}'),
};

dynamic defaultValue(FieldSpec field) {
  if (field.type == FieldType.active) return true;
  if (field.type == FieldType.roomState) return 'disponible';
  if (field.type == FieldType.category) return 'otro';
  return '';
}
