import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'app_scaffold.dart';
import 'theme_provider.dart';
import 'agregar_ciudades_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'clima_carousel_view.dart';
import 'creditos_page.dart';
import 'data_service.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final GoRouter router = GoRouter(routes:  [
      GoRoute(path: '/', builder: (context, state) => const MyHomePage(title:'Inicio')),
      GoRoute(path: '/agregar_ciudades', builder: (context, state) => const AgregarCiudadesPage()),
      GoRoute(path: '/creditos_page', builder: (context, state) => const CreditosPage()), 
    ]);
    return MaterialApp.router( title: 'Weather App',
      routerConfig: router,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode, 
      );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Map<String, dynamic>>> ciudadesGuardadas = Future<List<Map<String, dynamic>>>.value([]);
// Cargamos url, user  y pass desde el archivo .env
  static String get apiTokenUrl => dotenv.env['meteomatics_api_url'] ?? 'https://login.meteomatics.com/api/v1/token';
  static String get username => dotenv.env['meteomatics_user'] ?? '';
  static String get password => dotenv.env['meteomatics_pwd'] ?? '';
  Map<String, dynamic> city = {};
  String apiToken = '';
  int? selectedIndex;
  int _currentIndex = 0; 

@override
  void initState() {
    super.initState();
    debugPrint('API URL: $apiTokenUrl');
    debugPrint('Username: $username');
    // imprime la contraseña de forma segura sin mostrarla completa
    debugPrint('Password: ${'*' * password.length}');
    
    // Obtenemos el token, y luego cargamos el clima
    obtenToken().then((_) {
      _cargarYActualizarPrimeraCiudad();
    });
    
    ciudadesGuardadas = _ciudadesGuardadas();
  }
  
  Future<void> _cargarYActualizarPrimeraCiudad() async {
    final ciudades = await _ciudadesGuardadas();
    setState(() {
      ciudadesGuardadas = Future.value(ciudades);
    });
    
    if (ciudades.isNotEmpty) {
      city = ciudades[0];
      debugPrint('Primera ciudad cargada: ${city['nombre']}');
      await _actualizaClima(city);
    } else {
      debugPrint('No hay ciudades guardadas para actualizar el clima');
    }
  }


Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    return ciudadesString.map((ciudad) => json.decode(ciudad) as Map<String, dynamic>).toList();
  }

  Future<void> obtenToken() async {
    // Si ya tenemos el token, no hacemos nada
    if (apiToken.isNotEmpty) return;
    
    String url = apiTokenUrl;
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    });
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        apiToken = data['access_token'];
      });
      debugPrint('Token obtenido: $apiToken');
    } else {
      debugPrint('Error al obtener el token: ${response.statusCode}');
    }
  }

Future<void> _actualizaClima(Map<String, dynamic> ciudad) async {
  debugPrint('Actualizando clima para ${ciudad['nombre']} con token $apiToken');
  
  if (apiToken.isEmpty) {
    debugPrint('No se puede actualizar el clima sin un token válido. Intentando obtener token de nuevo...');
    await obtenToken();
    if (apiToken.isEmpty) {
      debugPrint('Fallo al obtener el token después del reintento.');
      return; 
    }
  }

  bool actualizar = false;
  String nombreCiudad = ciudad['nombre'] ?? 'Desconocida';
  double latitud = ciudad['latitud'] ?? 0.0;
  double longitud = ciudad['longitud'] ?? 0.0;
  
  String ultimaActualizacion = '';
  if (ciudad['ultima_actualizacion'] == null) {
    actualizar = true;
  } else {
    ultimaActualizacion = ciudad['ultima_actualizacion'];
    try {
      // Aseguramos que la comparación sea entre UTC
      DateTime ultimaActualizacionDT = DateTime.parse(ultimaActualizacion).toUtc(); 
      DateTime ahoraZ = DateTime.now().toUtc();
      Duration diferencia = ahoraZ.difference(ultimaActualizacionDT);
      if (diferencia.inMinutes >= 60) {
        actualizar = true;  
      }
    } catch (e) {
      debugPrint('Error al parsear última actualización: $e');
      actualizar = true; // Forzar actualización si hay error de formato de fecha
    }
  }


  if (actualizar) {
    String hora_actualZ = DateTime.now().toUtc().toIso8601String().split('.')[0] + 'Z';
    String url = 'https://api.meteomatics.com/$hora_actualZ/t_2m:C,wind_speed_10m:ms,weather_symbol_1h:idx/$latitud,$longitud/json?access_token=$apiToken';
    debugPrint('URL de la API: $url');
    
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final climaData = json.decode(response.body);
        final data = climaData['data']; 
        
        // Obtenemos los datos del clima
        final t2m = data[0]['coordinates'][0]['dates'][0]['value'];
        final windSpeed = data[1]['coordinates'][0]['dates'][0]['value'];
        final weatherSymbol = data[2]['coordinates'][0]['dates'][0]['value'];
        ultimaActualizacion = data[0]['coordinates'][0]['dates'][0]['date'];
        
        debugPrint('Clima para $nombreCiudad - Temp: $t2m, Viento: $windSpeed, Símbolo: $weatherSymbol');
        
        // Actualizamos el mapa de la ciudad con los nuevos datos
        ciudad['temperatura'] = t2m;
        ciudad['velocidad_viento'] = windSpeed;
        ciudad['simbolo_clima'] = weatherSymbol;
        ciudad['ultima_actualizacion'] = ultimaActualizacion;

        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> ciudadesActualizadas = await _ciudadesGuardadas();
          
        final index = ciudadesActualizadas.indexWhere((c) => 
            c['latitud'] == latitud && c['longitud'] == longitud
        );
        
        if (index != -1) {
            ciudadesActualizadas[index] = ciudad;
            debugPrint('Ciudad ${ciudad['nombre']} actualizada en el índice: $index');
        } else {
            debugPrint('Advertencia: Ciudad ${ciudad['nombre']} no encontrada por Lat/Lon para guardar.');
        }

        final ciudadesString = ciudadesActualizadas.map((c) => json.encode(c)).toList();
        await prefs.setStringList('ciudades', ciudadesString);
        
        // Actualizamos el estado para refrescar el carrusel
        if(mounted) {
            setState(() {
                // Asignamos un nuevo Future con la lista recién actualizada
                ciudadesGuardadas = Future.value(ciudadesActualizadas);
            });
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$nombreCiudad: ${t2m.toStringAsFixed(0)} °C, Viento: ${windSpeed.toStringAsFixed(1)} m/s')),
            );
        }
        
      } else {
        // Manejo de errores de API (401, 403, 404, etc.)
        // IMPRIMIR CÓDIGO DE ESTADO Y MENSAJE DE LA API
        debugPrint('Error de API al obtener el clima: CÓDIGO ${response.statusCode}. Mensaje: ${response.body}');  
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error ${response.statusCode}: No se pudo obtener el clima de $nombreCiudad.')),
            );
        }
      }
    } catch (e) {
      // Manejo de errores de red o de parseo JSON
      debugPrint('ERROR de Red/Parseo: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fallo de conexión al buscar clima para $nombreCiudad.')),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      body: ClimaCarouselView(
        ciudadesGuardadas: ciudadesGuardadas,
        actualizaClima: _actualizaClima,
      ),
    );
  }
}