import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pianta/Graficas/VitualPinDatastream.dart';
import 'package:pianta/MyDevices/Dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../Home/graphics_model.dart';
import '../UrlBackend.dart';
import '../constants.dart';



class DataPoint {
  int id;
  final String titlegraphics;
  final String namegraphics;
  final String aliasgraphics;
  final String location;
  //bool is_circular;
  final String ports;
  final String color;


  DataPoint({required this.titlegraphics, required this.namegraphics, required this.aliasgraphics,     required this.ports, required this.id, required this.location, required this.color});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      id: json['id'],
      titlegraphics: json['titlegraphics'],
      namegraphics: json['namegraphics'],
      aliasgraphics: json['aliasgraphics'],
      location: json['location'],
      //is_circular: json['is_circular'],
      ports: json['ports'],
      color: json['color'],
    );
  }
}

class TempCreateGrafics extends StatefulWidget {
  final int id;
  final String nameTemplate;
  const TempCreateGrafics({Key? key, required this.id, required this.nameTemplate}) : super(key: key);

  @override
  State<TempCreateGrafics> createState() => _TempCreateGraficsState();
}

class _TempCreateGraficsState extends State<TempCreateGrafics> {

  final TextEditingController titleController = TextEditingController();

  final _keyForm = GlobalKey<FormState>();

  void _saveTitle(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('title', title);
  }
  bool isGraphSelected = false;

  List<DataPoint> selectedGraphData = [];
  List<DataPoint> graphics = [];
  late Future<List<DataPoint>> futureGraphics;

  @override
  void initState() {
    super.initState();
    futureGraphics = fetchGraphics(); // Obtener las gráficas disponibles al cargar la página
  }

  Future<List<DataPoint>> fetchGraphics() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;
    final response = await http.get(
      Uri.parse('$urlpianta/user/graphics/${widget.id}'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<DataPoint> projects =
      jsonList.map((json) => DataPoint.fromJson(json)).toList();

      setState(() {
        graphics = projects;
      });

      return projects;
    } else {
      throw Exception('Failed to load project list');
    }
  }

  Future<dynamic> crearGrafico(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storedTitle = prefs.getString('title');
    final selectedGraph = selectedGraphData[0]; // Obtener la gráfica seleccionada
    final storedIsCircular = prefs.getBool('is_circular') ?? false;
    try {
      final response = await http.post(


        Uri.parse('$urlpianta/user/graphics/${widget.id}/'),
        body: {
          'titlegraphics': storedTitle,
          'namegraphics': selectedGraph.namegraphics,
          'aliasgraphics': selectedGraph.aliasgraphics,
          'location': selectedGraph.location,
          'is_circular': storedIsCircular.toString(),
          'ports':selectedGraph.ports,
          'color': selectedGraph.color.toString(),
        },
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Graph created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('An error occurred while creating the graph: ${response.body}')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    await prefs.remove('title');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          key: _keyForm,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: 900,
              height: 500,
              child: Form(
                key: _keyForm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Tooltip(
                              message: 'Return to the previous page',
                              child: IconButton(
                                  onPressed: () {
                                    Navigator.pop(
                                        context, 'Value page previous');
                                  },
                                  icon: const Icon(Icons.exit_to_app))),
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Gauge Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        const SizedBox(height: 18.0),
                        const Text(
                          'TITLE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            hintText: 'Enter title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the title';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 50.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Datastream',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                              DropdownButtonFormField(
                                items: graphics.map((graph) {
                                  print(graph);
                                  return DropdownMenuItem(
                                    value: graph,
                                    child: Text(graph.titlegraphics),
                                  );
                                }).toList(),
                                onChanged: (DataPoint? selectedGraph) {
                                  if (selectedGraph != null) {
                                    setState(() {
                                      selectedGraphData = [selectedGraph];// Actualiza la lista de datos de la gráfica seleccionada
                                      isGraphSelected = true; // Un gráfico ha sido seleccionado
                                    });
                                  } else{
                                    setState(() {
                                      selectedGraphData = [];
                                      isGraphSelected = false; // No se ha seleccionado ningún gráfico
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16.0),
                Flexible(
                  child: isGraphSelected
                      ? Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_keyForm.currentState!.validate()){
                            _saveTitle(titleController.text);
                            await crearGrafico(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  WebDashboard(idTemplate: widget.id, nameTemplate: widget.nameTemplate),
                              ),
                            );
                          }
                          // Lógica para guardar el datastream
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(90, 40),
                          backgroundColor: Color.fromRGBO(0, 191, 174, 1),
                        ),
                        child: Text('Save'),
                      ),
                      SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  WebDashboard(idTemplate: widget.id, nameTemplate: widget.nameTemplate),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(90, 40),
                          backgroundColor: Color.fromRGBO(0, 191, 174, 1),
                        ),
                        child: Text('Cancel'),
                      ),
                    ],
                  )
                      : ElevatedButton(
                    onPressed: () {
                      if (_keyForm.currentState!.validate()) {
                        _saveTitle(titleController.text);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VirtualPinDatastream(id: widget.id, nameTemplate: widget.nameTemplate,
                            ))
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(90, 40),
                      backgroundColor: Color.fromRGBO(0, 191, 174, 1),
                    ),
                    child: const Text('or Create Datastream'),
                  ),
                ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}