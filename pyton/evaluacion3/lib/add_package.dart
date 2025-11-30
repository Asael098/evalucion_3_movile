import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class AddPackageScreen extends StatefulWidget {
  const AddPackageScreen({super.key});
  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List workers = [];
  int? selectedWorkerId;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/workers'));
      if (response.statusCode == 200) {
        setState(() {
          workers = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching workers: $e");
    }
  }

  Future<void> _savePackage() async {
    if (selectedWorkerId == null || _addressCtrl.text.isEmpty) return;
    
    await http.post(
      Uri.parse('$baseUrl/packages'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": selectedWorkerId,
        "destination_address": _addressCtrl.text,
        "description": _descCtrl.text
      }),
    );
    if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asignar Paquete")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Seleccionar Trabajador",
                border: OutlineInputBorder()
              ),
              value: selectedWorkerId,
              items: workers.map((w) {
                return DropdownMenuItem<int>(
                  value: w['user_id'],
                  child: Text(w['full_name']),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedWorkerId = val),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _addressCtrl, 
              decoration: const InputDecoration(
                labelText: "Dirección de Destino",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map)
              )
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descCtrl, 
              decoration: const InputDecoration(
                labelText: "Descripción del Paquete",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description)
              )
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white
                ),
                onPressed: _savePackage, 
                child: const Text("GUARDAR Y ASIGNAR")
              ),
            )
          ],
        ),
      ),
    );
  }
}