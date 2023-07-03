import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pianta/Home/model_proyect.dart';
import 'package:pianta/MyDevices/Dashboard.dart';
import 'package:http/http.dart' as http;
import '../Home/graphics_model.dart';
import '../Home/template_model.dart';
import '../Home/templates.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../UrlBackend.dart';
import '../constants.dart';
import '../maps/mapasensor.dart';
import '../maps/maps.dart';

class Sensor {
  final double v1;
  final double v2;
  final double v3;
  final double v4;
  final double v5;
  final double v6;
  final double v7;
  final double v8;
  final double v9;
  final double v10;
  final double v11;
  final double v12;

  Sensor({
    required this.v1,
    required this.v2,
    required this.v3,
    required this.v4,
    required this.v5,
    required this.v6,
    required this.v7,
    required this.v8,
    required this.v9,
    required this.v10,
    required this.v11,
    required this.v12,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      v1: json['v1'].toDouble(),
      v2: json['v2'].toDouble(),
      v3: json['v3'].toDouble(),
      v4: json['v4'].toDouble(),
      v5: json['v5'].toDouble(),
      v6: json['v6'].toDouble(),
      v7: json['v7'].toDouble(),
      v8: json['v8'].toDouble(),
      v9: json['v9'].toDouble(),
      v10: json['v10'].toDouble(),
      v11: json['v11'].toDouble(),
      v12: json['v12'].toDouble(),
    );
  }
}

class VirtualPinDatastream extends StatefulWidget {
  final int id;
  final String nameTemplate;
  const VirtualPinDatastream({
    Key? key,
    required this.id,
    required this.nameTemplate,
  }) : super(key: key);

  @override
  State<VirtualPinDatastream> createState() => _VirtualPinDatastreamState();
}

class _VirtualPinDatastreamState extends State<VirtualPinDatastream> {
  final graphicstemplate = graphics = [];
  late Future<List<GrapchisTemplate>> futureGraphics;

  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final _locationController = TextEditingController();

  double? _selectedValue;
  final List<double> _vValues = [
    1.0,
    2.0,
    3.0,
    4.0,
    5.0,
    6.0,
    7.0,
    8.0,
    9.0,
    10.0,
    11.0,
    12.0,
  ];

  @override
  void initState() {
    super.initState();
    futureGraphics = fetchGraphics();
    futureProjects = fetchProjects();
  }

  final TextEditingController nameGraphicscontroller = TextEditingController();
  final TextEditingController aliasgraphicscontroller = TextEditingController();

  Future<List<ProjectTemplate>> fetchProjects() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;
    final response = await http.get(
      Uri.parse('$urlpianta/user/template/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<ProjectTemplate> projects =
          jsonList.map((json) => ProjectTemplate.fromJson(json)).toList();
      //esto refresca el proyecto para ver los cambios
      //await refreshProjects();
      return projects;
    } else {
      throw Exception('Failed to load project list');
    }
  }

  final projects = templateprojects = [];
  late Future<List<ProjectTemplate>> futureProjects;
  ProjectTemplate? project;
  Color _selectedColor = Colors.blue;

  Future<dynamic> crearGrafico(BuildContext context) async {
    await fetchProjects();
    final prefs = await SharedPreferences.getInstance();
    final storedIsCircular = prefs.getBool('is_circular') ??
        false; // Obtener el valor de isCircular desde SharedPreferences
    final storedTitle = prefs.getString('title');
    final storedName = prefs.getString('name');
    final storedAlias = prefs.getString('alias');
    final storedLocation = prefs.getString('location');

    print(storedAlias);
    print(storedName);
    print(storedTitle);
    print(storedLocation);
    print(storedIsCircular);
    try {
      final response = await http.post(
        Uri.parse('$urlpianta/user/graphics/${widget.id}/'),
        body: {
          'titlegraphics': storedTitle,
          'namegraphics': storedName,
          'aliasgraphics': storedAlias,
          'location': storedLocation,
          'is_circular': storedIsCircular.toString(),
          'color': _selectedColor.toString(),
          'ports': _selectedValue.toString(),
        },
      );
      if (response.statusCode == 201) {
        // El gráfico fue creado exitosamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('graphics created successfully')),
        );
      } else {
        // El request falló
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'An error occurred while creating the graphics${response.body}')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    await prefs.remove('title');
    await prefs.remove('name');
    await prefs.remove('alias');
    await prefs.remove('location');
    await prefs.remove('is_circular');
  }

  void _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
  }

  void _saveAlias(String alias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alias', alias);
  }

  void _saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location', location);
  }

  Future<List<GrapchisTemplate>> fetchGraphics() async {
    final response = await http.get(
      Uri.parse('$urlpianta/user/graphics/${widget.id}/'),
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
  Widget build(BuildContext context) {
    return Scaffold(
        //aaaaa
        body: Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(29.0),
          child: SizedBox(
              width: 900,
              height: 500,
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Tooltip(
                          message: 'Return to the previous page',
                          child: IconButton(
                              onPressed: () {
                                Navigator.pop(context, 'Value page previous');
                              },
                              icon: const Icon(Icons.exit_to_app))),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16.0),
                        const Text(
                          'Virtual Pin Datastream',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        const SizedBox(height: 25.0),
                        Row(
                          children: [
                            Flexible(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const Text(
                                      'NAME',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    TextFormField(
                                      controller: nameGraphicscontroller,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter name',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                )),
                            const SizedBox(width: 16.0),
                            Flexible(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const Text(
                                      'ALIAS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    TextFormField(
                                      controller: aliasgraphicscontroller,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter title',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        const SizedBox(width: 25.0),
                        Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 18.0),
                                  Row(
                                    children: const [
                                      Text(
                                        'Elegir PIN',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      SizedBox(width: 16.0),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  DropdownButtonFormField<double>(
                                    value: _selectedValue,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedValue = value!;
                                      });
                                    },
                                    items: _vValues
                                        .map<DropdownMenuItem<double>>((value) {
                                      return DropdownMenuItem<double>(
                                        value: value,
                                        child: Text('$value'),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Text(
                                      'Elegir color',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Seleccione un color'),
                                          content: SingleChildScrollView(
                                            child: ColorPicker(
                                              pickerColor: _selectedColor,
                                              onColorChanged: (color) {
                                                setState(() {
                                                  _selectedColor = color;
                                                });
                                              },
                                              showLabel: true,
                                              pickerAreaHeightPercent: 0.8,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('OK'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    height: 36.0,
                                    width: 36.0,
                                    decoration: BoxDecoration(
                                      color: _selectedColor,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: _selectedColor == Colors.transparent
                                        ? Icon(
                                            Icons.color_lens,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                Text(
                                  'RGB: ${_selectedColor.red}, ${_selectedColor.green}, ${_selectedColor.blue}',
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Flexible(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 30),
                                    const Text(
                                      'LOCATION',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(70, 20),
                                          backgroundColor: const Color.fromRGBO(
                                              0, 191, 174, 1),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MapSensor(_selectedColor)),
                                          ).then((value) {
                                            if (value != null &&
                                                value.isNotEmpty) {
                                              updateLocation(value);
                                            } else {
                                              // El usuario no seleccionó ninguna ubicación, muestra un mensaje de error o realiza la acción apropiada
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('Error'),
                                                    content: const Text(
                                                        'Please select location.'),
                                                    actions: <Widget>[
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                        ),
                                        label: const Text('Location',
                                            style: TextStyle(fontSize: 12))),
                                  ],
                                )),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(width: 20),
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
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () async {
                                _saveName(nameGraphicscontroller.text);
                                _saveAlias(aliasgraphicscontroller.text);
                                _saveLocation(_locationController.text);
                                await crearGrafico(context);
                                await fetchGraphics();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WebDashboard(
                                        idTemplate: widget.id,
                                        nameTemplate: widget.nameTemplate),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Color.fromRGBO(0, 191, 174, 1),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              )),
        ),
      ),
    ));
  }

  updateLocation(value) {
    setState(() {
      _locationController.text = value.toString();
      print(_locationController.text);
    });
  }
}
