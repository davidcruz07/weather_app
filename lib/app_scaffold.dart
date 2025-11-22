import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  static Future<String?> _getCustomText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('custom_text') ?? 'Menú';
  }

  // --- NUEVA FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE CONFIRMACIÓN ---
  void _confirmarBorrado(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Confirmar Borrado'),
          content: const Text('¿Estás seguro de que deseas eliminar TODAS las ciudades guardadas? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // Resaltar el botón de acción
              ),
              child: const Text('Eliminar Todo'),
              onPressed: () async {
                // 1. Realiza el borrado
                await borrarTodasLasCiudadesGuardadas(); 

                // 2. Cierra el diálogo y el Drawer
                if (!context.mounted) return;
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pop(); // Cierra el Drawer

                // 3. Muestra SnackBar y Recarga
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Ciudades guardadas borradas')),
                );
                
                // 4. Fuerza la recarga de la pantalla principal
                context.go('/'); 
              },
            ),
          ],
        );
      },
    );
  }
  // --- FIN NUEVA FUNCIÓN ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
             DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: FutureBuilder<String?>(
                future: _getCustomText(),
              builder: (context, snapshot) {
                final drawerText = snapshot.data ?? 'Menú';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(drawerText, style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                );
              },
            ),
            ),
            ListTile(
              leading: const Icon(Icons.sunny),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.of(context).pop(); 
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Agregar Ciudades'),
              onTap: () {
                Navigator.of(context).pop(); 
                context.go('/agregar_ciudades');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Créditos'),
              onTap: () {
                Navigator.of(context).pop(); 
                context.go('/creditos_page');
              },
            ),
            const Divider(),
            // BOTÓN DE BORRADO DE CIUDADES
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Borrar Todas las Ciudades'),
              onTap: () {
                // Llama a la nueva función de confirmación
                _confirmarBorrado(context); 
              },
            ),    
          ],
        ),
      ),
    );
  }
}