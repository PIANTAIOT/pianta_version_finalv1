import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:pianta/Home/template_model.dart';
import 'package:pianta/Home/templates.dart';
import 'package:pianta/MyDevices/DeviceGrafics.dart';
import 'dart:convert';
import 'package:pianta/MyDevices/New_Devices.dart';
import 'package:pianta/Funciones/constantes.dart';
import 'package:pianta/MyDevices/shared%20grafics.dart';
import '../UrlBackend.dart';
import '../maps/mapavisualizar.dart';
import 'package:collection/collection.dart';
import '../constants.dart';


class Devices {
  int id;
  final String name;
  final String location;
  final String template;
  Devices({
    required this.id,
    required this.name,
    required this.location,
    required this.template,
  });

  factory Devices.fromJson(Map<String, dynamic> json) {
    return Devices(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      template: json['template'],
    );
  }
}

class SharedDevices extends StatefulWidget {
  final int id;

  const SharedDevices({Key? key, required this.id}) : super(key: key);

  @override
  State<SharedDevices> createState() => _SharedDevices();
}

class _SharedDevices extends State<SharedDevices> {
  List<Devices> _devices = [];
  List<ProjectTemplate> _templates = [];
  late Future<List<ProjectTemplate>> futureProjects;



  @override
  void initState() {
    super.initState();
    _getDevices();
    futureProjects = fetchProjects();

  }

  Future<List<ProjectTemplate>> fetchProjects() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;
    final response = await http.get(
      Uri.parse('$urlpianta/user/template/shared/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<ProjectTemplate> projects =
      jsonList.map((json) => ProjectTemplate.fromJson(json)).toList();
      _templates = projects; // Asignar el resultado a _templates
      return projects;
    } else {
      throw Exception('Failed to load project list');
    }
  }


  Future<void> _getDevices() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;
    final response =
    await http.get(Uri.parse('$urlpianta/user/project/${widget.id}/devices/'),
      headers: {'Authorization': 'Token $token'},);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final List<Devices> devices =
      jsonList.map((json) => Devices.fromJson(json)).toList();
      setState(() {
        _devices = devices;
      });
      print('Devices list updated successfully');
    } else {
      throw Exception('Failed to load devices');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Row(
        children: [
          const SizedBox(
            width: 100,
            child: Navigation(title: 'nav', selectedIndex: 0 /* Fundamental SelectIndex para que funcione el selector*/),
          ),
          Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Shared Devices',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Colors.black26, //color of divider
                    height: 4, //height spacing of divider
                    thickness: 1, //thickness of divier line
                    indent: 15, //spacing at the start of divider
                    endIndent: 0,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Card(
                            child: ListTile(
                              title: Text(device.name),
                              subtitle: Text(device.location),
                              onTap: () async {
                                var box = await Hive.openBox(tokenBox);
                                final token = box.get("token") as String?;

                                final url = Uri.parse('$urlpianta/user/template/shared/');
                                final response = await http.get(url, headers: {'Authorization': 'Token $token'});

                                if (response.statusCode == 200 && json.decode(response.body).isNotEmpty) {
                                  final selectedTemplate = _templates.firstWhereOrNull((template) => template.id.toString() == device.template);
                                  final templateName = selectedTemplate?.name ?? "No template selected";
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SharedGraphics(template: device.template, nameTemplate: templateName, iddevice: device.id, idproject: widget.id, nombreDevice: device.name, locationDevice: device.location, )),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Not create template'),
                                        content: const Text('Not template available.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, 'Value page previous');
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
          ),
          ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(70, 20),
                backgroundColor: const Color.fromRGBO(0, 191, 174, 1),
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ViewLocalization(id: widget.id,)));
              },
              icon: const Icon(
                Icons.location_on,
                color: Colors.white,
              ),
              label: const Text('Location',
                  style: TextStyle(fontSize: 12))),// segundo widget// segundo widget
        ],
      ),

    );
  }
}

