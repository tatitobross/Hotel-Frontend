import 'package:flutter/material.dart';

import '../app.dart';
import '../models/hotel_module.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'module_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Api api = Api(widget.token);
  int selected = 0;
  final modules = const [HotelModule.types,HotelModule.rooms,HotelModule.guests,HotelModule.reservations,HotelModule.consumptions];
  bool get isAdmin => value(widget.user,'role','').toLowerCase() == 'administrador';

  Future<void> logout() async {
    try { await api.call('/logout',method:'POST'); } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final current = selected == 0 ? null : modules[selected - 1];
    return Scaffold(
      appBar: AppBar(title:Text(current == null ? 'Panel principal' : hotelModules[current]!.title)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(decoration:const BoxDecoration(color:darkGold),accountName:Text(value(widget.user,'name',value(widget.user,'username'))),accountEmail:Text('${value(widget.user,'role')} · ${value(widget.user,'email')}'),currentAccountPicture:const CircleAvatar(child:Icon(Icons.person))),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(selected:selected == 0,leading:const Icon(Icons.dashboard_outlined),title:const Text('Dashboard'),onTap:()=>choose(0)),
                    for (var index = 0; index < modules.length; index++)
                      ListTile(selected:selected == index + 1,leading:Icon(hotelModules[modules[index]]!.icon),title:Text(hotelModules[modules[index]]!.title),onTap:()=>choose(index + 1)),
                  ],
                ),
              ),
              const Divider(),
              ListTile(leading:const Icon(Icons.logout),title:const Text('Cerrar sesión'),onTap:logout),
            ],
          ),
        ),
      ),
      body: current == null ? DashboardScreen(api:api,user:widget.user) : ModuleScreen(key:ValueKey(current),api:api,module:current,isAdmin:isAdmin),
    );
  }

  void choose(int index) { setState(()=>selected=index); Navigator.pop(context); }
}
