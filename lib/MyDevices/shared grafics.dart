import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:pianta/Home/template_model.dart';
import 'package:pianta/MyDevices/My_Devices.dart';
import 'dart:math';

import '../Funciones/constantes.dart';
import '../Home/graphics_model.dart';
import '../Home/proyecto.dart';
import '../Home/templates.dart';
import '../UrlBackend.dart';
import '../constants.dart';
import 'Dashboard.dart';
import 'New_Devices.dart';

//ignore: camel_case_types
//grafica circular



class SensorData {
  final String name;
  final DateTime createdAt;
  final double? v12;
  final double? v11;
  final double? v10;
  final double? v9;
  final double? v8;
  final double? v7;
  final double? v6;
  final double? v5;
  final double? v4;
  final double? v3;
  final double? v2;
  final double? v1;

  SensorData({
    required this.name,
    required this.createdAt,
    required this.v12,
    required this.v11,
    required this.v10,
    required this.v9,
    required this.v8,
    required this.v7,
    required this.v6,
    required this.v5,
    required this.v4,
    required this.v3,
    required this.v2,
    required this.v1,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      v12: json['v12'],
      v11: json['v11'],
      v10: json['v10'],
      v9: json['v9'],
      v8: json['v8'],
      v7: json['v7'],
      v6: json['v6'],
      v5: json['v5'],
      v4: json['v4'],
      v3: json['v3'],
      v2: json['v2'],
      v1: json['v1'],
    );
  }
}


class Device {
  int id;
  final String name;
  final String location;
  final String template;
  Device({
    required this.id,
    required this.name,
    required this.location,
    required this.template,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      template: json['template'],
    );
  }
}

List<Device> devices = <Device>[];

List<SensorData> device = [];

class SharedGraphics extends StatefulWidget {
  final String template;
  final String nameTemplate;
  final int idproject;
  final int iddevice;
  final String nombreDevice;
  final String locationDevice;
  const SharedGraphics(
      {required this.template, required this.nameTemplate, required this.iddevice, required this.idproject, required this.nombreDevice, required this.locationDevice, super.key});

  @override
  State<SharedGraphics> createState() => _SharedGraphicsState();
}

class _SharedGraphicsState extends State<SharedGraphics>
    with SingleTickerProviderStateMixin {

  String lastData = 'v12';

  Device? selectedDevices;
  //late List<Device> devices;
  bool isLoading = false;
  //final FirebaseDatabase _database = FirebaseDatabase.instance;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final maxProgress = 100.0;
  late Future<List<SensorData>> _fetchDevicesFuture;
  Map<String, dynamic>? apiData;
  SensorData? selectedDevice;
  List<SensorData> device = [];

  List<Device> devices = <Device>[];
  final _formKey = GlobalKey<FormState>();
  String? _selectedTemplate;
  List<dynamic> _templates = [];
  late Future<List<GrapchisTemplate>> futureGraphics;



  Future<void> _getTemplates() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;

    final url = Uri.parse('$urlpianta/user/template/shared/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _templates = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load templates');
    }
  }

  Future<List<GrapchisTemplate>> fetchGraphics() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;

    final response = await http.get(
      Uri.parse('$urlpianta/user/graphics/${widget.template}/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<GrapchisTemplate> projects =
      jsonList.map((json) => GrapchisTemplate.fromJson(json)).toList();
      //esto refresca el proyecto para ver los cambios
      //await refreshProjects();
      return projects;
    } else {
      throw Exception('Failed to load project list');
    }
  }
  @override
  void initState() {
    futureGraphics = fetchGraphics();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _animation =
    Tween<double>(begin: 0, end: maxProgress).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    _fetchData(lastData);
    _fetchDevicesFuture = fetchDevices(lastData);
    super.initState();

    Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _fetchDevicesFuture = fetchDevices(lastData);
        _fetchData(lastData);
      });
    });
    _getTemplates();
  }


  @override
  void dispose() {
    // Cancelamos el timer cuando se destruye el widget
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _fetchData(lastData);
    fetchDevices(lastData);
  }

  Future<void> _fetchData(String lastData) async {
    try {
      final response = await http.get(Uri.parse(
          '$urlpianta/user/datos-sensores/$lastData/${widget.template}/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          apiData = data;
        });
      } else {
        // Handle the error
      }
    } catch (e) {
      // Handle the error
    }
  }


  Future<List<SensorData>> fetchDevices(String lastData) async {
    final response = await http.get(Uri.parse(
        '$urlpianta/user/datos-sensores/$lastData/${widget.template}/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<SensorData> devices = [];
      for (var item in data) {
        devices.add(SensorData.fromJson(item));
      }
      setState(() {
        device = devices;
      });
      return devices;
    } else {
      throw Exception('Failed to load devices');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastData = device.isNotEmpty ? device.last : null;
    return SafeArea(
        child: Scaffold(
            body: Container(
                child: Row(children: [
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
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Tooltip(
                                      message: 'Return to the previous page',
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.pop(context, 'Value page previous');
                                        },
                                        icon: const Icon(Icons.exit_to_app),
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Graphics ',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 30),
                                  ),
                                  Text(
                                    'Name Template: ${widget.nameTemplate}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 30),
                                  ),
                                ],
                              ),
                            ), //fin modulo
                            SizedBox(height: 35),
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
                          child: Card(
                            child: FutureBuilder<List<GrapchisTemplate>>(
                              future: futureGraphics,
                              builder: (context, snapshot) {
                                final formKey = GlobalKey<FormState>();
                                if (snapshot.hasData) {
                                  final projects = snapshot.data!;
                                  return GridView.builder(
                                    gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 950 / 400,
                                    ),
                                    itemCount: projects.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final project = projects[index];
                                      final lastData = 'v${project.ports}';
                                      print(lastData);
                                      final lastDatadates = device.isNotEmpty ? device.last : null;
                                      double? valueToDisplay = 0.0;
                                      print(valueToDisplay);
                                      // Comparar el valor de lastData con los campos de SensorData
                                      if (lastData == 'v12') {
                                        valueToDisplay = lastDatadates?.v12;
                                      } else if (lastData == 'v11') {
                                        valueToDisplay = lastDatadates?.v11;
                                      } else if (lastData == 'v10') {
                                        valueToDisplay = lastDatadates?.v10;
                                      } else if (lastData == 'v9') {
                                        valueToDisplay = lastDatadates?.v9;
                                      } else if (lastData == 'v8') {
                                        valueToDisplay = lastDatadates?.v8;
                                      } else if (lastData == 'v7') {
                                        valueToDisplay = lastDatadates?.v7;
                                      }else if (lastData == 'v6') {
                                        valueToDisplay = lastDatadates?.v6;
                                      }else if (lastData == 'v5') {
                                        valueToDisplay = lastDatadates?.v5;
                                      }else if (lastData == 'v4') {
                                        valueToDisplay = lastDatadates?.v4;
                                      }else if (lastData == 'v3') {
                                        valueToDisplay = lastDatadates?.v3;
                                      }else if (lastData == 'v2') {
                                        valueToDisplay = lastDatadates?.v2;
                                      }else if (lastData == 'v1') {
                                        valueToDisplay = lastDatadates?.v1;
                                      } else {
                                        valueToDisplay = 0.0;
                                      }
                                      final title = project.titlegraphics;
                                      if (project.is_circular == true) {
                                        return Container(
                                          height: 1200,
                                          child: GestureDetector(
                                            child: Card(
                                              child: SizedBox(
                                                width: 250,
                                                height: 250,
                                                child: Stack(
                                                  children: [
                                                    Center(
                                                      child: CustomPaint(
                                                        painter: Circular_graphics(
                                                            valueToDisplay ?? 0.0),
                                                        child: SizedBox(
                                                          width: 200,
                                                          height: 200,
                                                          child: Center(
                                                            child: valueToDisplay == null
                                                                ? const Text(' 0 °C',
                                                              style: TextStyle(
                                                                fontSize: 30,
                                                              ),
                                                            )
                                                                : Text(
                                                              '$valueToDisplay °C',
                                                              style: const TextStyle(
                                                                fontSize: 30,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Wrap(
                                                      spacing:
                                                      16.0, // Espacio horizontal entre los elementos del Wrap
                                                      runSpacing:
                                                      8.0, // Espacio vertical entre las líneas de texto
                                                      children: [
                                                        Text(
                                                          title,
                                                          style:
                                                          const TextStyle(
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            fontSize:
                                                            20,
                                                          ),
                                                          textAlign:
                                                          TextAlign.left,
                                                        ),
                                                        Text(
                                                          'Port: ${project.ports}',
                                                          style:
                                                          TextStyle(
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            fontSize:
                                                            20,
                                                          ),
                                                          textAlign:
                                                          TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      } else if(project.is_circular == false){
                                        return Container(
                                          height: 1200,
                                          child: GestureDetector(
                                            child: Card(
                                              child: SizedBox(
                                                width: 250,
                                                height: 250,
                                                child: Stack(
                                                  children: [
                                                    Center(
                                                      child: SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Linea_Graphicss(),
                                                      ),
                                                    ),
                                                    Wrap(
                                                      spacing:
                                                      16.0, // Espacio horizontal entre los elementos del Wrap
                                                      runSpacing:
                                                      8.0, // Espacio vertical entre las líneas de texto
                                                      children: [
                                                        Text(
                                                          title,
                                                          style:
                                                          const TextStyle(
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            fontSize:
                                                            20,
                                                          ),
                                                          textAlign:
                                                          TextAlign.left,
                                                        ),
                                                        Text(
                                                          'Port: ${project.ports}',
                                                          style:
                                                          TextStyle(
                                                            fontWeight:
                                                            FontWeight.bold,
                                                            fontSize:
                                                            20,
                                                          ),
                                                          textAlign:
                                                          TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                } else if (snapshot.hasError) {
                                  return Scaffold(
                                    body: Center(
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${snapshot.error}",
                                            ),
                                            Card(
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 250,
                                                      height: 250,
                                                      child: Center(
                                                        child: const Text(
                                                          'Not template available',
                                                          style: TextStyle(fontSize: 16),
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            Navigator.of(context).pop();
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            primary: Colors.white,
                                                          ),
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(color: Colors.black),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12), // Agregar espacio horizontal
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color.fromRGBO(0, 191, 174, 1),
                                                          ),
                                                          onPressed: () {
                                                          },
                                                          child: const Text('Save'),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                // By default, show a loading spinner
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]))));
  }
}

class CircularGraphicsPainter extends CustomPainter {
  final double currentProgress;

  CircularGraphicsPainter(this.currentProgress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint circle = Paint()
      ..strokeWidth = 5
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );
    double radius = 150;
    canvas.drawCircle(center, radius, circle);

    Paint animationArc = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (currentProgress > 30) {
      animationArc.color = Colors.red;
    } else if (currentProgress > 27) {
      animationArc.color = Colors.orange;
    } else if (currentProgress > 20) {
      animationArc.color = Colors.yellow;
    } else {
      animationArc.color = Colors.blue;
    }

    double angle = 2 * pi * (currentProgress / 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi / 2,
        angle, false, animationArc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

//grafica dias. lineal
class Linea_Graphicss extends StatelessWidget {
  const Linea_Graphicss({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SensorData>>(
      future: fetchSensorData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final series = [
            charts.Series(
              id: 'Sensor Data',
              data: data,
              domainFn: (SensorData sensorData, _) => sensorData.createdAt,
              measureFn: (SensorData sensorData, _) => sensorData.v12,
              colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
              labelAccessorFn: (SensorData sensorData, _) =>
              '${sensorData.createdAt}: ${sensorData.v12}',
            ),
          ];
          final chart = charts.TimeSeriesChart(
            series,
            animate: true,
          );
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: chart,
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

Future<List<SensorData>> fetchSensorData() async {
  final response = await http
      .get(Uri.parse('$urlpianta/user/datos-sensores/v12/33'));
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final sensorDataList =
    List<SensorData>.from(jsonData.map((x) => SensorData.fromJson(x)));
    return sensorDataList;
  } else {
    throw Exception('Failed to load sensor data');
  }
}
