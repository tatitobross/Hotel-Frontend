import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool hidden = true;
  String? error;

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() { loading = true; error = null; });
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'username': username.text.trim(), 'password': password.text, 'device_name': 'hotel-flutter'}),
      );
      final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || data['access_token'] == null) throw ApiException(errorText(data));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(token: data['access_token'].toString(), user: Map<String,dynamic>.from(data['user'] as Map))));
    } on http.ClientException {
      setState(() => error = 'No se pudo conectar con Laravel. Inicia el backend en el puerto 8000.');
    } on ApiException catch (exception) {
      setState(() => error = exception.message);
    } catch (_) {
      setState(() => error = 'No se pudo iniciar sesión.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() { username.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 410),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.hotel_rounded, size: 70, color: gold),
                    const SizedBox(height: 12),
                    Text('Hotel', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 5),
                    const Text('Reservas y atención a huéspedes', textAlign: TextAlign.center),
                    const SizedBox(height: 26),
                    TextFormField(controller: username, decoration: const InputDecoration(labelText:'Usuario',prefixIcon:Icon(Icons.person_outline)), validator: (text) => text == null || text.trim().isEmpty ? 'Ingrese su usuario' : null),
                    const SizedBox(height: 14),
                    TextFormField(controller: password, obscureText: hidden, onFieldSubmitted: (_) => login(), decoration: InputDecoration(labelText:'Contraseña',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(icon:Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),onPressed:()=>setState(()=>hidden=!hidden))), validator: (text) => text == null || text.isEmpty ? 'Ingrese su contraseña' : null),
                    if (error != null) Padding(padding: const EdgeInsets.only(top:14), child: Text(error!, textAlign:TextAlign.center, style:const TextStyle(color:Colors.red))),
                    const SizedBox(height: 20),
                    FilledButton.icon(onPressed: loading ? null : login, icon:const Icon(Icons.login), label:Text(loading ? 'Ingresando...' : 'Iniciar sesión')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
