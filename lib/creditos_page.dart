import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_scaffold.dart'; 

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir el enlace: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Créditos y Atribuciones",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Esta aplicación de clima utiliza la siguiente tecnología y datos:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 30),

            const Text(
              "Servicio de Geocodificación (Búsqueda de Ciudades)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Text(
              "Los datos geográficos utilizados para la búsqueda de ciudades y el mapa interactivo provienen de Nominatim y OpenStreetMap.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => _launchUrl('https://operations.osmfoundation.org/policies/attribution/'),
              child: const Text(
                "Datos © Colaboradores de OpenStreetMap (Licencia ODbL)",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => _launchUrl('https://nominatim.org/'),
              child: const Text(
                "API de Nominatim",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const Divider(height: 40),

            const Text(
              "Servicio de Datos Meteorológicos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Text(
              "La información sobre temperatura, viento y símbolos del clima es proporcionada por Meteomatics.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => _launchUrl('https://www.meteomatics.com/'),
              child: const Text(
                "Visitar el sitio web de Meteomatics",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const Divider(height: 40),

             const Text(
              "Iconografía",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            Text(
              "Los íconos del clima provienen del paquete 'weather_icons'.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
          ],
        ),
      ),
    );
  }
}