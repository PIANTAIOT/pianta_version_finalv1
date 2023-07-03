import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:pianta/Home/graphics_model.dart';
import 'package:pianta/Home/template_model.dart';
import 'package:pianta/Home/templates.dart';
import 'package:pianta/MyDevices/DeviceGrafics.dart';
import 'dart:convert';
import 'package:pianta/MyDevices/New_Devices.dart';
import 'package:pianta/Funciones/constantes.dart';
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

class MyDevice extends StatefulWidget {
  final int id;

  const MyDevice({Key? key, required this.id}) : super(key: key);

  @override
  State<MyDevice> createState() => _MyDeviceState();
}

class _MyDeviceState extends State<MyDevice> {
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
      Uri.parse('$urlpianta/user/template/'),
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

  void _deleteDevice(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm the Deletion'),
          content: const Text('Are you sure you want to delete this device?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      final response = await http.delete(Uri.parse('$urlpianta/user/devices/$id/${widget.id}/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _devices.removeWhere((device) => device.id == id);
        });
        print('Device deleted successfully');
      } else {
        throw Exception('Failed to delete device');
      }
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
                          'My Devices',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black),
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              primary: const Color.fromRGBO(0, 191, 174, 1),
                            ),
                            onPressed: () async {
                              var box = await Hive.openBox(tokenBox);
                              final token = box.get("token") as String?;
                              final url = Uri.parse('$urlpianta/user/template/');
                              final response = await http.get(url, headers:  {'Authorization': 'Token $token'},);
                              if (response.statusCode == 200 &&
                                  json.decode(response.body).isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Container(
                                          width: MediaQuery.of(context).size.width * 0.7,
                                          height: MediaQuery.of(context).size.height * 0.9,
                                          child: Column(
                                            children:  [
                                              Expanded(child: NewDevice(id: widget.id)),
                                            ],
                                          )
                                      ),
                                    );
                                  },
                                ).then((value) => _getDevices());
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Create a template first'),
                                      content: const Text(
                                          'Please create a template before adding a device.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => Templates())),
                                          child: const Text('OK'),
                                        )
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            child: const Text(
                              '+New Device',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ],
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
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteDevice(device.id);
                                },
                              ),
                              onTap: () async {
                                var box = await Hive.openBox(tokenBox);
                                final token = box.get("token") as String?;

                                final url = Uri.parse('$urlpianta/user/template/');
                                final response = await http.get(url, headers: {'Authorization': 'Token $token'});

                                if (response.statusCode == 200 && json.decode(response.body).isNotEmpty) {
                                  final selectedTemplate = _templates.firstWhereOrNull((template) => template.id.toString() == device.template);
                                  final templateName = selectedTemplate?.name ?? "No template selected";
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DeviceGrafics(template: device.template, nameTemplate: templateName, iddevice: device.id, idproject: widget.id, nombreDevice: device.name, locationDevice: device.location, )),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Create a template first'),
                                        content: const Text('Please create a template before adding a device.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => Templates()),
                                            ),
                                            child: const Text('OK'),
                                          )
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

