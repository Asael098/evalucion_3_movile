import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class RegisterWorkerScreen extends StatefulWidget {
  const RegisterWorkerScreen({super.key});

  @override
  State<RegisterWorkerScreen> createState() => _RegisterWorkerScreenState();
}

class _RegisterWorkerScreenState extends State<RegisterWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/worker'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": _nameController.text,
          "username": _userController.text,
          "password": _passController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trabajador registrado con éxito")),
          );
          Navigator.pop(context);
        }
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? "Error desconocido";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Nuevo Trabajador")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre Completo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Usuario (Login)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) => value!.length < 4 ? "Mínimo 4 caracteres" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _registerWorker,
                        child: const Text("REGISTRAR TRABAJADOR"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}