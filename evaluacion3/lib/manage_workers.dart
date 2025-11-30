import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'register_worker.dart';

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen> {
  List workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  // --- LEER (READ) ---
  Future<void> _fetchWorkers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/workers'));
      if (response.statusCode == 200) {
        setState(() {
          workers = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- BORRAR (DELETE) ---
  Future<void> _deleteWorker(int id) async {
    // Confirmación antes de borrar
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Estás seguro? Si el trabajador tiene entregas, podría dar error."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final response = await http.delete(Uri.parse('$baseUrl/workers/$id'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trabajador eliminado")));
      _fetchWorkers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al eliminar (¿Tiene paquetes asignados?)")));
    }
  }

  // --- ACTUALIZAR (UPDATE) ---
  Future<void> _showEditDialog(Map worker) async {
    final nameCtrl = TextEditingController(text: worker['full_name']);
    final passCtrl = TextEditingController(); // Vacío, solo si quiere cambiarla

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar: ${worker['username']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre Completo"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Nueva Contraseña (Opcional)"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateWorker(worker['user_id'], nameCtrl.text, passCtrl.text);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  Future<void> _updateWorker(int id, String name, String password) async {
    Map<String, dynamic> data = {"full_name": name};
    if (password.isNotEmpty) {
      data["password"] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/workers/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      _fetchWorkers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Actualizado correctamente")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestionar Empleados")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () async {
          // --- CREAR (CREATE) - Reutilizamos la pantalla existente ---
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterWorkerScreen()));
          _fetchWorkers();
        },
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : workers.isEmpty 
          ? const Center(child: Text("No hay trabajadores registrados"))
          : ListView.builder(
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final w = workers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(w['full_name'][0].toUpperCase()),
                    ),
                    title: Text(w['full_name']),
                    subtitle: Text("Usuario: ${w['username']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(w),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteWorker(w['user_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}