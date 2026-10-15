import 'package:flutter/material.dart';

import '../app.dart';
import '../models/hotel_module.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.api, required this.user});
  final Api api;
  final Map<String, dynamic> user;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  String? error;
  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final response = await widget.api.call('/dashboard');
      if (mounted) setState(() => data = Map<String,dynamic>.from((response as Map)['data'] as Map));
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data == null && error == null) return const Center(child:CircularProgressIndicator());
    if (error != null) return Center(child:Text(error!));
    final cards = <({String title, dynamic total, IconData icon})>[
      (title:'Habitaciones',total:data!['habitaciones_total'],icon:Icons.bed_outlined),
      (title:'Disponibles',total:data!['habitaciones_disponibles'],icon:Icons.check_circle_outline),
      (title:'Ocupadas',total:data!['habitaciones_ocupadas'],icon:Icons.hotel_outlined),
      (title:'Llegadas hoy',total:data!['llegadas_hoy'],icon:Icons.login),
      (title:'Salidas hoy',total:data!['salidas_hoy'],icon:Icons.logout),
      (title:'Ocupación',total:'${data!['ocupacion_porcentaje']}%',icon:Icons.pie_chart_outline),
    ];
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Bienvenido, ${value(widget.user,'name')}',style:Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height:20),
          GridView.count(crossAxisCount:MediaQuery.of(context).size.width > 700 ? 3 : 2,childAspectRatio:1.45,crossAxisSpacing:12,mainAxisSpacing:12,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),children:cards.map((card)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(card.icon,color:gold),const Spacer(),Text('${card.total}',style:Theme.of(context).textTheme.headlineMedium),Text(card.title)])))).toList()),
        ],
      ),
    );
  }
}
