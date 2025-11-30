import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Necesario para consultar Nominatim desde Flutter
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'config.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final Map package;
  final int agentId;
  const DeliveryDetailScreen({super.key, required this.package, required this.agentId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  XFile? _pickedImage;
  Uint8List? _webImageBytes;
  Position? _position;
  String? _currentAddress; 
  bool _isLoading = false;
  bool _isGettingLocation = true;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImage = pickedFile;
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _pickedImage = pickedFile;
        });
      }
    }
  }

  // --- FUNCIÓN MEJORADA PARA OBTENER DIRECCIÓN EN WEB Y MÓVIL ---
  Future<void> _getLocationAndAddress() async {
    setState(() => _isGettingLocation = true);

    try {
      // 1. Permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se requiere permiso de ubicación")));
           setState(() => _isGettingLocation = false);
         }
         return;
      }

      // 2. Obtener Coordenadas
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      String address = "Buscando dirección...";

      // 3. Estrategia para obtener dirección
      if (kIsWeb) {
        // --- SOLUCIÓN PARA WEB: CONSULTAR NOMINATIM DIRECTAMENTE ---
        try {
          final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            // Intentamos armar la dirección bonita
            if (data['address'] != null) {
              final addr = data['address'];
              final road = addr['road'] ?? '';
              final number = addr['house_number'] ?? '';
              final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? '';
              
              if (road.isNotEmpty) {
                address = "$road $number, $city";
              } else {
                address = data['display_name'] ?? "Ubicación Web detectada";
              }
            }
          }
        } catch (e) {
          print("Error Nominatim Web: $e");
          address = "GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        }
      } else {
        // --- SOLUCIÓN PARA MÓVIL (ANDROID/IOS) ---
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            address = "${place.street}, ${place.subLocality}, ${place.locality}";
          }
        } catch (e) {
          print("Error Geocoding Nativo: $e");
          // Si falla el nativo, intentamos fallback a coordenadas
          address = "Ubicación GPS: ${position.latitude}, ${position.longitude}";
        }
      }

      if (mounted) {
        setState(() {
          _position = position;
          _currentAddress = address;
          _isGettingLocation = false;
        });
      }

    } catch (e) {
      if (mounted) setState(() => _isGettingLocation = false);
      print("Error General GPS: $e");
    }
  }

  Future<void> _completeDelivery() async {
    if ((_pickedImage == null && _webImageBytes == null) || _position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto y Ubicación requeridas")));
      return;
    }

    setState(() => _isLoading = true);
    
    var uri = Uri.parse('$baseUrl/deliver'); 
    var request = http.MultipartRequest('POST', uri);
    
    request.fields['package_id'] = widget.package['package_id'].toString();
    request.fields['agent_id'] = widget.agentId.toString();
    request.fields['latitude'] = _position!.latitude.toString();
    request.fields['longitude'] = _position!.longitude.toString();
    
    if (kIsWeb) {
      if (_webImageBytes != null) {
         request.files.add(http.MultipartFile.fromBytes(
          'file', 
          _webImageBytes!,
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ));
      }
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _pickedImage!.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String serverAddress = jsonResponse['detected_address'] ?? "Dirección registrada";

        if(mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("¡Entrega Exitosa!"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 50),
                  const SizedBox(height: 10),
                  const Text("El servidor registró la ubicación:"),
                  const SizedBox(height: 10),
                  Text(serverAddress, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("Aceptar"),
                )
              ],
            )
          );
        }
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
      }
    } catch (e) {
       setState(() => _isLoading = false);
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocationAndAddress(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Entregar Paquete #${widget.package['package_id']}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // INFORMACIÓN DEL PAQUETE
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DESTINO FINAL:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(widget.package['destination_address'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const Divider(height: 20),
                    const Text("DETALLES:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(widget.package['description'] ?? "N/A"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // EVIDENCIA FOTOGRÁFICA
            InkWell(
              onTap: _takePhoto,
              child: Container(
                height: 220, 
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: _pickedImage == null && _webImageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 60, color: Colors.indigo.shade200),
                          const SizedBox(height: 10),
                          const Text("Toca para tomar foto de evidencia", style: TextStyle(color: Colors.grey))
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (kIsWeb && _webImageBytes != null)
                            ? Image.memory(_webImageBytes!, width: double.infinity, height: 220, fit: BoxFit.cover)
                            : Image.file(File(_pickedImage!.path), width: double.infinity, height: 220, fit: BoxFit.cover),
                      ),
              ),
            ),
            
            const SizedBox(height: 20),

            // UBICACIÓN ACTUAL DETECTADA
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
                border: Border.all(color: _position != null ? Colors.green.shade200 : Colors.orange.shade200)
              ),
              child: _isGettingLocation 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 15),
                      Text("Consultando satélite...")
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on, color: Colors.green[700]),
                          const SizedBox(width: 5),
                          const Text("Ubicación de Entrega", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // MUESTRA LA DIRECCIÓN REAL DE NOMINATIM O NATIVO
                      Text(
                        _currentAddress ?? "Ubicación desconocida",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
            ),
            
            const SizedBox(height: 30),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.indigo, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5
                  ),
                  onPressed: _completeDelivery,
                  child: const Text("CONFIRMAR ENTREGA", style: TextStyle(fontSize: 18, letterSpacing: 1)),
                )
          ],
        ),
      ),
    );
  }
}