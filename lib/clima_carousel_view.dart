import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';

class CarouselView extends StatelessWidget {
  final double itemExtent;
  final double shrinkExtent;
  final Function(int) onTap;
  final List<Widget> children;

  const CarouselView({
    Key? key,
    required this.itemExtent,
    required this.shrinkExtent,
    required this.onTap,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: children.length,
      onPageChanged: (index) => onTap(index),
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }
}

class ClimaCarouselView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> ciudadesGuardadas;
  final Function(Map<String, dynamic>) actualizaClima;

  
  const ClimaCarouselView({
    Key? key,
    required this.ciudadesGuardadas,
    required this.actualizaClima,
  }) : super(key: key);
  
  @override
  State<ClimaCarouselView> createState() => _ClimaCarouselViewState();
}

class _ClimaCarouselViewState extends State<ClimaCarouselView> {
  int _currentIndex = 0; // Índice de la página actual en el PageView


  List<Color> _obtenerGradienteClima(int simbolo) {
    // Simbolos 101, 102, 103, 104 son para la noche
    if (simbolo >= 101 && simbolo <= 104) {
      return [
        Colors.indigo.shade900,
        Colors.blue.shade900,
      ];
    } else if (simbolo == 1) {
      return [
        Colors.lightBlue.shade600,
        Colors.blue.shade400,
      ];
    } else if (simbolo >= 2 && simbolo <= 4) {
      return [
        Colors.blueGrey.shade600,
        Colors.blueGrey.shade800,
      ];
    } else {
      return [
        Colors.blue.shade700,
        Colors.blue.shade900,
      ];
    }
  }

  // Mapa de íconos del clima
  IconData _obtenerIconoClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return WeatherIcons.na;
      case 1:
        return WeatherIcons.day_sunny;
      case 2:
        return WeatherIcons.day_sunny_overcast;
      case 3:
        return WeatherIcons.day_cloudy;
      case 4:
        return WeatherIcons.cloud;
      case 101:
        return WeatherIcons.night_clear;
      case 102:
        return WeatherIcons.night_alt_cloudy_gusts;
      case 103:
        return WeatherIcons.night_partly_cloudy;
      case 104:
        return WeatherIcons.night_cloudy;
      default:
        return WeatherIcons.na;
    }
  }

  String _obtenerDescripcionClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return 'Sin datos';

      case 1:
        return 'Despejado';
      case 2:
        return 'Mayormente despejado';
      case 3:
        return 'Parcialmente Nublado';
      case 4:
        return 'Nublado';
      case 101:
        return 'Despejado (noche)';
      case 102:
        return 'Mayormente despejado (noche)';
      case 103:
        return 'Parcialmente nublado (noche)';
      case 104:
        return 'Nublado (noche)';
      default:
        return 'Desconocido';
    }
  }

  String _formatearHora(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Desconocido';
    try {
      final fecha = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(fecha.toLocal());
    } catch (e) {
      return 'Desconocido';
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.ciudadesGuardadas,
      builder: (context, snapshot) {
        // Mostrar 'Loading' mientras se cargan los datos
        final gradientDefault = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(gradient: gradientDefault),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        // Manejar errores
        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(gradient: gradientDefault),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 50),
                  const SizedBox(height: 10),
                  Text('Error al cargar ciudades: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        // Acceder a la lista de ciudades
        final ciudades = snapshot.data ?? [];
        if (ciudades.isEmpty) {
          return Container(
            decoration: BoxDecoration(gradient: gradientDefault),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'No hay ciudades guardadas',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }
        // Mostrar el Carousel de ciudades
        return _buildCarousel(ciudades);
      },
    );
  }

  Widget _buildCarousel(List<Map<String, dynamic>> ciudades) {
    
  return Stack(
    children: [
      // CarouselView (El carrusel principal)
      CarouselView(
        itemExtent: MediaQuery.of(context).size.width,
        shrinkExtent: MediaQuery.of(context).size.width,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Al cambiar de ciudad, actualiza el clima
          widget.actualizaClima(ciudades[index]);
        },
        children: List.generate(
          ciudades.length,
          (index) {
            final ciudad = ciudades[index];
            return _buildCiudadCard(ciudad);
          },
        ),
      ),
      
      // Botón de Refrescar (Parte superior derecha)
      Positioned(
        top: 50,
        right: 20,
        child: IconButton(
          icon: const Icon(
            Icons.refresh,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            if (_currentIndex < ciudades.length) {
              widget.actualizaClima(ciudades[_currentIndex]);
            }
          },
        ),
      )
    ] 
  );
}

  Widget _buildCiudadCard(Map<String, dynamic> ciudad) {
    final temperatura = ciudad['temperatura'] ?? 0.0;
    final simoboloClima = ciudad['simbolo_clima'] ?? 0;
    final velocidadViento = ciudad['velocidad_viento'] ?? 0.0;
    final nombre = ciudad['nombre'] ?? 'Desconocido';
    final ultimaActualizacion = ciudad['ultima_actualizacion'] ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _obtenerGradienteClima(simoboloClima),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Nombre de la ciudad
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Icono del clima
              Icon(
                _obtenerIconoClima(simoboloClima),
                color: Colors.white,
                size: 100,
              ),
              const SizedBox(height: 10),

              // Descripción del clima
              Text(
                _obtenerDescripcionClima(simoboloClima),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 10),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${temperatura.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 100,
                          fontWeight: FontWeight.w200),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '°C',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w300),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Detalles del Viento (Lado Izquierdo)
                    _buildInfoItem(
                      WeatherIcons.strong_wind,
                      '${velocidadViento.toStringAsFixed(1)} m/s',
                      'Viento',
                      alignLeft: true,
                    ),
                    // 2. Detalles de Actualización (Lado Derecho)
                    _buildInfoItem(
                      Icons.access_time,
                      _formatearHora(ultimaActualizacion),
                      'Actualizado',
                      alignLeft: false,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, {required bool alignLeft}) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignLeft)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            if (alignLeft)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300),
        ),
      ],
    );
  }
}