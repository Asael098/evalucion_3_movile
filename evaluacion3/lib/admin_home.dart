import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'login.dart';
import 'add_package.dart';
import 'manage_workers.dart'; // Importar la nueva pantalla

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/packages'));
      if (response.statusCode == 200) {
        setState(() {
          packages = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }


  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPackages,
          )
        ],
      ),
      // --- MENÚ LATERAL PARA NAVEGACIÓN ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Menú Admin", style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Gestionar Paquetes"),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                _fetchPackages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Gestionar Empleados"),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageWorkersScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      // -------------------------------------
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : packages.isEmpty 
              ? const Center(child: Text("No hay paquetes registrados"))
              : ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final p = packages[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(
                          Icons.inventory, 
                          color: p['delivery_status'] == 'ENTREGADO' ? Colors.green : Colors.orange
                        ),
                        title: Text("Paquete #${p['package_id']} - ${p['description'] ?? ''}"),
                        subtitle: Text("Destino: ${p['destination_address']}\nEstado: ${p['delivery_status']}"),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Asignar Paquete"),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPackageScreen()));
          _fetchPackages();
        },
      ),
    );
  }
}