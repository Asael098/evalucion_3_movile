import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'admin_home.dart';
import 'worker_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _userController.text,
          "password": _passController.text
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        final userId = data['user_id'];

        if (!mounted) return;

        if (role == 'ADMIN') {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const AdminHomeScreen())
          );
        } else {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => WorkerHomeScreen(userId: userId))
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales Inválidas"))
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paquexpress Login")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 80, color: Colors.indigo),
              const SizedBox(height: 30),
              TextField(
                controller: _userController, 
                decoration: const InputDecoration(
                  labelText: "Usuario", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)
                )
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController, 
                decoration: const InputDecoration(
                  labelText: "Contraseña", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock)
                ), 
                obscureText: true
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white
                      ),
                      onPressed: _login, 
                      child: const Text("INICIAR SESIÓN")
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }
}