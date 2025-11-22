import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'app_scaffold.dart';

class AgregarCiudadesPage extends StatefulWidget {
  const AgregarCiudadesPage({super.key});
  @override
  State<AgregarCiudadesPage> createState() => _AgregarCiudadesPageState();
}

class _AgregarCiudadesPageState extends State<AgregarCiudadesPage> {
  final TextEditingController _cityController = TextEditingController();
  final MapController _mapController = MapController();
  List ciudadData = [];
  double dLat = 29.0948207;
  double dLon = -110.9692202;
  double selectedLat = 29.0948207;
  double selectedLon = -110.9692202;
  int? selectedIndex;
  Future<List<Map<String, dynamic>>> ciudadesGuardadas =
      Future<List<Map<String, dynamic>>>.value([]);

  @override
  void initState() {
    super.initState();
    ciudadesGuardadas = _ciudadesGuardadas();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Agregar Ciudades",
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Aquí puedes agregar nuevas ciudades",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const Text("Ciudad"),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa el nombre de la ciudad',
                ),
              ),
              // Agregar botón para buscar y agregar ciudad
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text("Buscar Ciudad"),
                onPressed: () async {
                  final ciudad = _cityController.text;
                  if (ciudad.isNotEmpty) {
                    final resultados = await _buscarCiudad(ciudad);
                    if (!mounted) return;
                    setState(() {
                      ciudadData = resultados;
                      selectedIndex = null; // Reiniciar selección al buscar
                      // Centrar el mapa en la primera coincidencia si existe
                      if (ciudadData.isNotEmpty) {
                        final firstLat = double.tryParse(ciudadData.first['lat']) ?? dLat;
                        final firstLon = double.tryParse(ciudadData.first['lon']) ?? dLon;
                        _mapController.move(LatLng(firstLat, firstLon), 10);
                      }
                    });
                    debugPrint(ciudadData.toString());
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: ciudadData.length,
                  itemBuilder: (context, index) {
                    final ciudadInfo = ciudadData[index];
                    return ListTile(
                      title: Text(ciudadInfo['display_name']),
                      subtitle: Text(
                          'Lat: ${ciudadInfo['lat']}, Lon: ${ciudadInfo['lon']}'),
                      selected: selectedIndex == index,
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          // Al hacer tap, se actualiza el campo de texto con el nombre de búsqueda
                          _cityController.text = ciudadInfo['address']['town'] ?? ciudadInfo['name'] ?? ciudadInfo['display_name'].split(',')[0];
                          
                          // Parseo robusto de String a double
                          selectedLat = double.tryParse(ciudadInfo['lat'].toString()) ?? 0.0;
                          selectedLon = double.tryParse(ciudadInfo['lon'].toString()) ?? 0.0;
                          
                          _mapController.move(LatLng(selectedLat, selectedLon), 10);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              //aqui va la lista
              SizedBox(
                height: 200,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: ciudadesGuardadas,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error ${snapshot.error}');
                    }
                    final data = snapshot.data ?? const <Map<String, dynamic>>[];
                    if (data.isEmpty) {
                      return const Center(
                          child: Text('No hay ciudades guardadas.'));
                    }
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final ciudad = data[index];
                        return ListTile(
                          title: Text(ciudad['nombre'].toString()),
                          subtitle: Text(
                              'Lat: ${ciudad["latitud"]} Lon: ${ciudad["longitud"]}'),
                          // Agregar funcionalidad para eliminar ciudad (Opcional)
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              //aqui va el boton de agegar ciudades
              SizedBox(
                child: ElevatedButton(
                  child: const Text("Agregar ciudad"),
                  onPressed: () {
                    // Usamos el texto del controlador (el nombre corto) y las coordenadas seleccionadas
                    _agregarCiudad(_cityController.text, selectedLat, selectedLon);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                // Agregar mapa con flutter_map con control de zoom.
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(selectedLat, selectedLon),
                    initialZoom: 10,
                    maxZoom: 18,
                    minZoom: 3,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.weather_app',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(selectedLat, selectedLon),
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40,),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List> _buscarCiudad(String nombreCiudad) async {
    // Aquí iría la lógica para buscar la ciudad en una base de datos o API
    // Se usa Nominatim con el nombreCiudad.
    final url =
        'https://nominatim.openstreetmap.org/search?q=$nombreCiudad&format=json&addressdetails=1';
    debugPrint('URL de búsqueda: $url');
    // Hacemos la peticion a Nominatim con el url formado
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MiAppDeClima/1.0 (josedcm9@gmail.com)', 
        },
      );
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data;
        }
      } else {
         debugPrint('Error en la API de Nominatim: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al realizar la petición de búsqueda: $e');
    }
    return [];
  }

  void _agregarCiudad(String nombre, double lat, double lon) async {
    // Verificación básica de que la ciudad ha sido seleccionada
    if (nombre.isEmpty || (lat == dLat && lon == dLon)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, busca y selecciona una ciudad primero.')),
      );
      return;
    }
    
    debugPrint('=== Iniciando _agregarCiudad ===');
    final prefs = await SharedPreferences.getInstance();
    
    // 1. CARGA LA LISTA ACTUAL DE STRINGS
    List<String> listaciudadesString = prefs.getStringList('ciudades') ?? [];
    
    // 2. CONVIERTE LA LISTA ACTUAL A OBJETOS PARA VERIFICAR DUPLICADOS
    final List<Map<String, dynamic>> ciudadesActuales = listaciudadesString
        .map((ciudadStr) => json.decode(ciudadStr) as Map<String, dynamic>)
        .toList();

    // 3. VERIFICACIÓN DE DUPLICADOS (Por nombre o por latitud/longitud)
    final nombreLimpio = nombre.split(',')[0].trim();

    final yaExiste = ciudadesActuales.any((ciudad) {
      // Compara por nombre (ignorando mayúsculas/minúsculas)
      final nombreGuardadoLimpio = ciudad['nombre'].toString().toLowerCase();
      final nombreNuevoLimpio = nombreLimpio.toLowerCase();
      
      // Compara por coordenadas (exactamente)
      final latMatch = ciudad['latitud'] == lat;
      final lonMatch = ciudad['longitud'] == lon;
      
      return nombreGuardadoLimpio == nombreNuevoLimpio || (latMatch && lonMatch);
    });

    if (yaExiste) {
      debugPrint('Ciudad duplicada detectada: $nombreLimpio');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta ciudad ya ha sido agregada.')),
      );
      return; // Detiene la ejecución si es duplicada
    }

    // 4. PREPARA EL NUEVO OBJETO y lo añade a la lista de strings
    String nuevaCiudadString = json.encode({
      'nombre': nombreLimpio, 
      'latitud': lat,
      'longitud': lon,
      // No es necesario 'id' si buscamos por lat/lon en _actualizaClima
    });

    listaciudadesString.add(nuevaCiudadString);
    await prefs.setStringList('ciudades', listaciudadesString);
    debugPrint('Ciudad agregada: $nombreLimpio. Total: ${listaciudadesString.length}');

    // 5. NOTIFICACIÓN Y RECARGA
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Ciudad agregada: $nombreLimpio')),
    );
    
    // Forzamos la reconstrucción de la lista de ciudades guardadas
    setState(() {
      ciudadesGuardadas = _ciudadesGuardadas();
      ciudadData = []; 
      _cityController.clear(); 
      selectedIndex = null; 
    });
    
    // Navegar a la pantalla principal para recargar el carrusel
    context.go('/');
    
    debugPrint('=== Fin _agregarCiudad ===');
  }

  Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    debugPrint('=== Cargando ciudades guardadas (AgregarCiudadesPage) ===');
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    debugPrint('Total ciudades en SharedPreferences: ${ciudadesString.length}');

    final resultado = ciudadesString
        .map((ciudadStr) => json.decode(ciudadStr) as Map<String, dynamic>)
        .toList();
    debugPrint('=== Fin carga ciudades ===');
    return resultado;
  }
}