import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'login.dart'; // Importar Login para redirigir
import 'delivery_detail.dart';

class WorkerHomeScreen extends StatefulWidget {
  final int userId;
  const WorkerHomeScreen({super.key, required this.userId});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  List myPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPackages();
  }

  Future<void> _fetchMyPackages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/my-packages/${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() {
          myPackages = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Elimina todas las rutas anteriores
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Entregas"),
        actions: [
          // BOTÓN DE SALIR (NUEVO)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : myPackages.isEmpty 
          ? const Center(child: Text("No tienes entregas pendientes 🎉"))
          : ListView.builder(
              itemCount: myPackages.length,
              itemBuilder: (context, index) {
                final p = myPackages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.local_shipping, color: Colors.white),
                    ),
                    title: Text("Paquete #${p['package_id']}"),
                    subtitle: Text(p['destination_address']),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => DeliveryDetailScreen(package: p, agentId: widget.userId))
                      );
                      _fetchMyPackages(); // Recargar al volver
                    },
                  ),
                );
              },
            ),
    );
  }
}