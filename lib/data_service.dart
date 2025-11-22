import 'package:shared_preferences/shared_preferences.dart';

/// Borra completamente la lista de ciudades guardadas del almacenamiento local.
Future<void> borrarTodasLasCiudadesGuardadas() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // La clave que usamos para guardar las ciudades es 'ciudades'.
  final bool exito = await prefs.remove('ciudades');

  if (exito) {
    print('✅ Lista de ciudades borrada exitosamente.');
  } else {
    print('❌ Error al intentar borrar la lista de ciudades.');
  }
}