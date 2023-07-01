import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:pianta/api_maps.dart';
import 'package:pianta/modelmaps.dart';
import '../Funciones/constantes.dart';
import '../constants.dart';

const MAPBOX_ACCESS_TOKEN =
    'pk.eyJ1IjoiZGFuaWVsc2cxOCIsImEiOiJjbGZ1N3F6ZWcwNDByM2Vtamo1OTNoc3hrIn0.5dFY3xEDB7oLtMbCWDdW9A';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  List<LatLng> polylineCoordinates = [];
  List<Marker> markers = [];
  bool showMarker = false;
  String polylineString = '';
  Position? currentLocation;
  Locationes? locationes;

  List<LatLng> locationArray = [];

  @override
  void initState() {
    super.initState();
    getLocation();
    _loadData();
  }

  Future<void> _loadData() async {
    // Código para cargar tus datos existentes

    await _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      var box = await Hive.openBox(tokenBox);
      final token = box.get("token") as String?;
      final fetchedLocation = await getLocationes(token!);
      setState((){
        locationes = fetchedLocation;
      });

      print('Location: ${locationes?.locationes}');
      String? drawlocation = locationes?.locationes;
      locationArray = drawlocation?.split('|').map((location) {
            List<String> coordinates = location.split(',');
            double latitude = double.parse(coordinates[0]);
            double longitude = double.parse(coordinates[1]);
            return LatLng(latitude, longitude);
          }).toList() ??
          [];

      if (locationArray.isNotEmpty) {
        locationArray.add(locationArray.first);
        LatLng defaultCenter = locationArray.first;
        // Use the default center location in case locationArray is empty
        LatLng center =
            locationArray.isNotEmpty ? locationArray.first : defaultCenter;
        mapController.move(center, 10.0);
      } else {
        // Handle the case when locationArray is empty
        // For example, you can set a default center location or show an error message
        LatLng defaultCenter = LatLng(0.0, 0.0); // Default center location
        mapController.move(defaultCenter, 10.0);
        print('Location array is empty.');
      }
    } catch (e) {
      print('Failed to load location: $e');
    }
  }

  Future<void> getLocation() async {
    // Obtener la ubicación actual
    // Resto del código...
  }

  @override
  Widget build(BuildContext context) {
    polylineString = polylineCoordinates
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');
    print(polylineString);

    LatLng? initialLocation;

    if (locationArray.isNotEmpty) {
      // Si la lista de ubicaciones no está vacía, establece la ubicación inicial en la primera coordenada
      initialLocation = locationArray.first;
    }

    return Scaffold(
      body: Row(children: [
        const SizedBox(
          width: 100,
          child: Navigation(title: 'nav', selectedIndex: 0),
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Location',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                          context, 'Valor enviado a la página anterior');
                    },
                    icon: const Icon(Icons.exit_to_app),
                  )
                ],
              ),
              const Divider(
                color: Colors.black26,
                height: 2,
                thickness: 1,
                indent: 15,
                endIndent: 0,
              ),
              Expanded(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center:
                        initialLocation, // Establecer el centro del mapa en la ubicación inicial
                    zoom: 13.0,
                    onTap: _handleTap,
                  ),
                  nonRotatedChildren: [
                    TileLayer(
                      urlTemplate:
                          'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                      additionalOptions: const {
                        'accessToken': MAPBOX_ACCESS_TOKEN,
                        'id': 'mapbox/satellite-v9'
                      },
                    ),
                    MarkerLayer(markers: markers),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: locationArray,
                          strokeWidth: 2.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    MarkerLayer(markers: markers),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            color: Color.fromARGB(255, 58, 57, 57),
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.location_on),
                                color: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    showMarker = true;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ]),
    );
  }

  void _handleTap(TapPosition, LatLng location) async {
    if (showMarker) {
      setState(() {
        // Limpiar la lista de markers
        markers.clear();

        // Agregar el nuevo marker con las coordenadas dadas
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: location,
            builder: (ctx) => Container(
              child: Icon(Icons.location_pin,
                  color: Color.fromARGB(255, 249, 5, 5)),
            ),
          ),
        );
        // Imprimir coordenada

        // Mostrar el diálogo para guardar la ubicación
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Guardar ubicación'),
              content: Text('¿Desea guardar esta ubicación?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    // Eliminar el marcador y cerrar el diálogo
                    setState(() {
                      markers.clear();
                      Navigator.of(context).pop();
                    });
                  },
                ),
                TextButton(
                  child: Text('Guardar'),
                  onPressed: () {
                    // Guardar las coordenadas y cerrar el diálogo
                    polylineCoordinates.add(location);
                    polylineString = polylineCoordinates
                        .map((point) => '${point.latitude},${point.longitude}')
                        .join('|'); // Imprimir coordenadas
                    print(polylineString);

                    Navigator.pop(context);
                    Navigator.pop(context, polylineString);
                  },
                ),
              ],
            );
          },
        );

        // Ocultar el botón de ubicación
        showMarker = false;
      });
    }
  }
}