import 'package:flutter/material.dart';

import '../app.dart';
import '../models/hotel_module.dart';
import '../services/api_service.dart';
import '../widgets/record_dialogs.dart';

class ModuleScreen extends StatefulWidget {
  const ModuleScreen({
    super.key,
    required this.api,
    required this.module,
    required this.isAdmin,
  });

  final Api api;
  final HotelModule module;
  final bool isAdmin;

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final TextEditingController search = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? error;

  ModuleInfo get info => hotelModules[widget.module]!;

  bool get canCreate {
    return widget.isAdmin ||
        <HotelModule>[
          HotelModule.guests,
          HotelModule.reservations,
          HotelModule.consumptions,
        ].contains(widget.module);
  }

  bool get canEdit {
    return widget.isAdmin ||
        <HotelModule>[HotelModule.guests, HotelModule.reservations]
            .contains(widget.module);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final filter = Uri.encodeQueryComponent(search.text.trim());
      final response = await widget.api.call('${info.path}?buscar=$filter');
      final rawItems = response is Map && response['data'] is List
          ? response['data'] as List
          : const <dynamic>[];
      final loadedItems = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (mounted) setState(() => items = loadedItems);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Map<String, dynamic>? item]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => RecordEditor(
        api: widget.api,
        module: widget.module,
        item: item,
      ),
    );
    if (changed == true) await load();
  }

  Future<void> remove(Map<String, dynamic> item) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Desea eliminar ${info.main(item)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    try {
      await widget.api.call('${info.path}/${item['id']}', method: 'DELETE');
      showMessage('Registro eliminado.');
      await load();
    } on ApiException catch (exception) {
      showMessage(exception.message, error: true);
    }
  }

  Future<void> reservationAction(
    Map<String, dynamic> item,
    String action,
  ) async {
    try {
      final response = await widget.api.call('/reservas/${item['id']}/$action', method: 'POST');
      if (!mounted) return;
      if (action == 'checkout' && response is Map && response['factura'] is Map) {
        await showDialog<void>(
          context: context,
          builder: (_) => HotelInvoiceDialog(invoice: Map<String, dynamic>.from(response['factura'] as Map)),
        );
      }
      showMessage('Acción realizada correctamente.');
      await load();
    } on ApiException catch (exception) {
      showMessage(exception.message, error: true);
    }
  }

  void showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  onSubmitted: (_) => load(),
                  decoration: InputDecoration(
                    labelText: 'Buscar ${info.title.toLowerCase()}',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: load,
                    ),
                  ),
                ),
              ),
              if (canCreate) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: load,
            child: items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 180),
                      Center(
                        child: Text(
                          'No hay ${info.title.toLowerCase()} registrados.',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) => recordTile(items[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget recordTile(Map<String, dynamic> item) {
    final actions = <Widget>[
      IconButton(
        tooltip: 'Ver detalle',
        icon: const Icon(Icons.visibility_outlined),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => RecordDetails(title: info.main(item), record: item),
        ),
      ),
    ];

    if (canEdit) {
      actions.add(
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => edit(item),
        ),
      );
    }
    if (widget.isAdmin) {
      actions.add(
        IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => remove(item),
        ),
      );
    }

    final state = value(item, 'estado');
    if (widget.module == HotelModule.reservations && state == 'reservada') {
      actions.add(
        IconButton(
          tooltip: 'Check-in',
          icon: const Icon(Icons.login),
          onPressed: () => reservationAction(item, 'checkin'),
        ),
      );
      actions.add(
        IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.cancel_outlined),
          onPressed: () => reservationAction(item, 'cancelar'),
        ),
      );
    }
    if (widget.module == HotelModule.reservations && state == 'en_estadia') {
      actions.add(
        IconButton(
          tooltip: 'Check-out',
          icon: const Icon(Icons.logout),
          onPressed: () => reservationAction(item, 'checkout'),
        ),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xffffe8b1),
        child: Icon(info.icon, color: darkGold),
      ),
      title: Text(info.main(item)),
      subtitle: Text(info.detail(item)),
      trailing: Wrap(children: actions),
    );
  }
}
