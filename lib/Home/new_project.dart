import 'dart:convert';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:pianta/Home/model_proyect.dart';
import 'package:pianta/Home/proyecto.dart';
import 'package:pianta/maps/maps.dart';

import '../UrlBackend.dart';
import '../constants.dart';

class Projects {
  String name;
  String location;
  String description;

  Projects({
    required this.name,
    required this.location,
    required this.description,
  });
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'description': description,
    };
  }
}

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({Key? key}) : super(key: key);

  @override
  _AddProjectScreenState createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addProject(Projects project) async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;
    final url = Uri.parse('$urlpianta/user/project/');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token'
    };
    final body = json.encode(project.toMap());

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Proyectos()));
      //Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding project'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 900,
          height: 500,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Project',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(12, 16, 12, 16),
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  textAlign: TextAlign.left,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                  controller: _nameController,
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(12, 16, 12, 16),
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  textAlign: TextAlign.left,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                  controller: _descriptionController,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(70, 20),
                      backgroundColor: const Color.fromRGBO(0, 191, 174, 1),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Localization()),
                      ).then((value) {
                        if (value != null && value.isNotEmpty) {
                          updateLocation(value);
                        } else {
                          // El usuario no seleccionó ninguna ubicación, muestra un mensaje de error o realiza la acción apropiada
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Error'),
                                content: const Text('Please select location.'),
                                actions: <Widget>[
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
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
                    label:
                        const Text('Location', style: TextStyle(fontSize: 12))),
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
                    SizedBox(width: 12), // Agregar espacio horizontal
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final project = Projects(
                            name: _nameController.text,
                            location: _locationController.text,
                            description: _descriptionController.text,
                          );
                          _addProject(project);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromRGBO(0, 191, 174, 1),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )));
  }

  updateLocation(value) {
    setState(() {
      _locationController.text = value.toString();
    });
  }
}
