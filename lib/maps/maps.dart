import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

import 'dart:math';

import '../Funciones/constantes.dart';
import '../Home/new_project.dart';

class Localization extends StatefulWidget {
  const Localization({Key? key}) : super(key: key);

  @override
  State<Localization> createState() => _LocalizationState();
}

double distanceBetween(LatLng latLng1, LatLng latLng2) {
  const double earthRadius = 6371000; // meters
  double lat1 = latLng1.latitude * pi / 180;
  double lat2 = latLng2.latitude * pi / 180;
  double lon1 = latLng1.longitude * pi / 180;
  double lon2 = latLng2.longitude * pi / 180;
  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

const MAPBOX_ACCESS_TOKEN =
    'pk.eyJ1IjoiZGFuaWVsc2cxOCIsImEiOiJjbGZ1N3F6ZWcwNDByM2Vtamo1OTNoc3hrIn0.5dFY3xEDB7oLtMbCWDdW9A';

class _LocalizationState extends State<Localization> {
  final MapController mapController = MapController();
  List<LatLng> polylineCoordinates = [];
  bool canAddPolylines = true;
  bool isAddingPolylines = false;
  double circleRadius = 10.0;
  bool showCircle = true;
  Position? currentLocation;
  LatLng initialCoordinate = LatLng(0, 0); // Valor inicial temporal

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    geolocator.Position position =
        await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.high,
    );

    setState(() {
      currentLocation = position;
      initialCoordinate = LatLng(
        currentLocation!.latitude,
        currentLocation!.longitude,
      );
      mapController.move(
        initialCoordinate,
        13.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String polylineString = polylineCoordinates
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');
    return Scaffold(
      body: Row(
        children: [
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
                            fontWeight: FontWeight.bold, fontSize: 30),
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
                      onTap: (point, latLng) {
                        if (canAddPolylines && isAddingPolylines) {
                          setState(() {
                            if (polylineCoordinates.isEmpty) {
                              initialCoordinate = latLng;
                              polylineCoordinates.add(latLng);
                            } else {
                              polylineCoordinates.add(latLng);
                              double distance =
                                  distanceBetween(latLng, initialCoordinate);
                              if (distance < circleRadius * 1) {
                                polylineCoordinates.add(initialCoordinate);
                                canAddPolylines = false;
                                isAddingPolylines = false;

                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text(
                                        '¿Desea guardar la ubicación?'),
                                    actions: [
                                      TextButton(
                                        child: const Text('No'),
                                        onPressed: () {
                                          setState(() {
                                            polylineCoordinates.clear();
                                            canAddPolylines = true;
                                            isAddingPolylines = true;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Sí'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pop(
                                              context, polylineString);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          });
                        }
                      },
                    ),
                    nonRotatedChildren: [
                      TileLayer(
                        urlTemplate:
                            'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                        additionalOptions: const {
                          'accessToken': MAPBOX_ACCESS_TOKEN,
                          'id': 'mapbox/satellite-v9',
                        },
                      ),
                      if (currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: circleRadius * 2,
                              height: circleRadius * 2,
                              point: LatLng(
                                currentLocation!.latitude,
                                currentLocation!.longitude,
                              ),
                              builder: (ctx) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: polylineCoordinates,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              color: const Color.fromARGB(255, 58, 57, 57),
                              child: Ink(
                                decoration: ShapeDecoration(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.polyline_rounded),
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      canAddPolylines = true;
                                      isAddingPolylines = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
