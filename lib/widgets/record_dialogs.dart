import 'package:flutter/material.dart';

import '../models/hotel_module.dart';
import '../services/api_service.dart';

class RecordDetails extends StatelessWidget {
  const RecordDetails({
    super.key,
    required this.title,
    required this.record,
  });

  final String title;
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final labels = <String, String>{
      'numero': 'Número de habitación',
      'piso': 'Piso',
      'nombre': 'Nombre',
      'apellido': 'Apellido',
      'documento': 'Documento',
      'telefono': 'Teléfono',
      'correo': 'Correo',
      'nacionalidad': 'Nacionalidad',
      'descripcion': 'Descripción',
      'capacidad': 'Capacidad',
      'precio_noche': 'Precio por noche',
      'fecha_entrada': 'Fecha de entrada',
      'fecha_salida': 'Fecha de salida',
      'personas': 'Personas',
      'noches': 'Noches',
      'total_hospedaje': 'Total de hospedaje',
      'total_consumos': 'Total de consumos',
      'total_general': 'Total general',
      'categoria': 'Categoría',
      'cantidad': 'Cantidad',
      'precio_unitario': 'Precio unitario',
      'subtotal': 'Subtotal',
      'estado': 'Estado',
      'activo': 'Activo',
      'observaciones': 'Observaciones',
    };
    final rows = record.entries.where((entry) {
      const ignored = {'id', 'created_at', 'updated_at', 'tipo_habitacion_id', 'huesped_id', 'habitacion_id', 'reserva_id'};
      return !ignored.contains(entry.key) && entry.value is! Map && entry.value is! List && entry.value != null;
    }).map((entry) {
      final raw = entry.value;
      final shown = entry.key.contains('precio') || entry.key.contains('total') || entry.key == 'subtotal'
          ? money(raw)
          : raw is bool
              ? (raw ? 'Sí' : 'No')
              : stateText(raw);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text('${labels[entry.key] ?? entry.key}: $shown'),
      );
    }).toList();

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows)),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    );
  }
}

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.api,
    required this.module,
    this.item,
  });

  final Api api;
  final HotelModule module;
  final Map<String, dynamic>? item;

  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final formKey = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  List<Map<String, dynamic>> types = [];
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> guests = [];
  List<Map<String, dynamic>> reservations = [];
  bool loadingRelations = true;
  bool saving = false;
  String? error;

  ModuleInfo get info => hotelModules[widget.module]!;

  @override
  void initState() {
    super.initState();
    for (final field in info.fields) {
      final existing = widget.item?[field.key] ?? defaultValue(field);
      if (field.type == FieldType.text || field.type == FieldType.number || field.type == FieldType.date) {
        controllers[field.key] = TextEditingController(text: existing?.toString() ?? '');
      } else {
        values[field.key] = existing;
      }
    }
    loadRelations();
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> responseList(dynamic response) {
    if (response is! Map || response['data'] is! List) return [];
    return (response['data'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> loadRelations() async {
    final fields = info.fields.map((field) => field.key).toSet();
    final needsTypes = fields.contains('tipo_habitacion_id');
    final needsRooms = fields.contains('habitacion_id');
    final needsGuests = fields.contains('huesped_id');
    final needsReservations = fields.contains('reserva_id');
    final calls = <Future<dynamic>>[];
    if (needsTypes) calls.add(widget.api.call('/tipos-habitacion'));
    if (needsRooms) calls.add(widget.api.call('/habitaciones'));
    if (needsGuests) calls.add(widget.api.call('/huespedes'));
    if (needsReservations) calls.add(widget.api.call('/reservas'));
    try {
      final results = calls.isEmpty ? <dynamic>[] : await Future.wait(calls);
      if (!mounted) return;
      var index = 0;
      setState(() {
        if (needsTypes) types = responseList(results[index++]);
        if (needsRooms) rooms = responseList(results[index++]);
        if (needsGuests) guests = responseList(results[index++]);
        if (needsReservations) {
          reservations = responseList(results[index++])
              .where((item) => value(item, 'estado') == 'en_estadia')
              .toList();
        }
        loadingRelations = false;
      });
    } on ApiException catch (exception) {
      if (mounted) setState(() {
        error = exception.message;
        loadingRelations = false;
      });
    }
  }

  String relationName(String key, Map<String, dynamic> item) {
    if (key == 'tipo_habitacion_id') return value(item, 'nombre');
    if (key == 'habitacion_id') return 'Habitación ${value(item, 'numero')}';
    if (key == 'huesped_id') return '${value(item, 'nombre')} ${value(item, 'apellido')}';
    return 'Reserva #${value(item, 'id')}';
  }

  List<Map<String, dynamic>> optionsFor(String key) {
    switch (key) {
      case 'tipo_habitacion_id':
        return types;
      case 'habitacion_id':
        return rooms.where((room) {
          final isCurrent = room['id']?.toString() == widget.item?['habitacion_id']?.toString();
          return value(room, 'estado') == 'disponible' || isCurrent;
        }).toList();
      case 'huesped_id':
        return guests;
      case 'reserva_id':
        return reservations;
    }
    return [];
  }

  dynamic selectedRelation(String key, List<Map<String, dynamic>> options) {
    final current = values[key] ?? widget.item?[key];
    return options.any((option) => option['id'].toString() == current?.toString()) ? current : null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final body = <String, dynamic>{};
    for (final field in info.fields) {
      final raw = controllers.containsKey(field.key) ? controllers[field.key]!.text.trim() : values[field.key];
      if (field.type == FieldType.number && raw.toString().isNotEmpty) {
        body[field.key] = num.tryParse(raw.toString()) ?? raw;
      } else if (field.type == FieldType.active) {
        body[field.key] = raw == true || raw == 1 || raw == '1';
      } else {
        body[field.key] = raw;
      }
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      String path = info.path;
      String method = widget.item == null ? 'POST' : 'PUT';
      if (widget.module == HotelModule.consumptions) {
        final reservationId = body.remove('reserva_id');
        path = '/reservas/$reservationId/consumos';
        method = 'POST';
      } else if (widget.item != null) {
        path = '$path/${widget.item!['id']}';
      }
      await widget.api.call(path, method: method, body: body);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget relationField(FieldSpec field) {
    final options = optionsFor(field.key);
    return DropdownButtonFormField<dynamic>(
      value: selectedRelation(field.key, options),
      isExpanded: true,
      decoration: InputDecoration(labelText: field.label),
      items: options.map((option) => DropdownMenuItem(value: option['id'], child: Text(relationName(field.key, option)))).toList(),
      validator: (value) => field.required && value == null ? 'Seleccione ${field.label.toLowerCase()}.' : null,
      onChanged: (value) => setState(() => values[field.key] = value),
    );
  }

  Widget choiceField(FieldSpec field) {
    final options = switch (field.type) {
      FieldType.roomState => const {'disponible': 'Disponible', 'limpieza': 'En limpieza', 'mantenimiento': 'En mantenimiento'},
      FieldType.category => const {'restaurante': 'Restaurante', 'bar': 'Bar', 'lavanderia': 'Lavandería', 'minibar': 'Minibar', 'spa': 'Spa', 'otro': 'Otro'},
      _ => const {},
    };
    return DropdownButtonFormField<dynamic>(
      value: values[field.key],
      decoration: InputDecoration(labelText: field.label),
      items: options.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
      onChanged: (value) => setState(() => values[field.key] = value),
    );
  }

  Widget activeField(FieldSpec field) {
    final selected = values[field.key] == true || values[field.key] == 1 || values[field.key] == '1';
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(field.label),
      value: selected,
      onChanged: (value) => setState(() => values[field.key] = value),
    );
  }

  Widget textField(FieldSpec field) {
    final controller = controllers[field.key]!;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: field.label),
      maxLines: field.key == 'descripcion' || field.key == 'observaciones' ? 3 : 1,
      keyboardType: field.type == FieldType.number ? TextInputType.number : null,
      validator: (text) {
        if (field.required && (text == null || text.trim().isEmpty)) return 'Ingrese ${field.label.toLowerCase()}.';
        if (field.key == 'correo' && text != null && text.isNotEmpty && !text.contains('@')) return 'Ingrese un correo válido.';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = info.fields;
    return AlertDialog(
      title: Text(widget.item == null ? 'Nuevo ${info.singular.toLowerCase()}' : 'Editar ${info.singular.toLowerCase()}'),
      content: SizedBox(
        width: 480,
        child: loadingRelations
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final field in fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: switch (field.type) {
                            FieldType.typeRelation || FieldType.roomRelation || FieldType.guestRelation || FieldType.reservationRelation => relationField(field),
                            FieldType.roomState || FieldType.category => choiceField(field),
                            FieldType.active => activeField(field),
                            _ => textField(field),
                          },
                        ),
                      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: saving || loadingRelations ? null : save, child: Text(saving ? 'Guardando...' : 'Guardar')),
      ],
    );
  }
}
