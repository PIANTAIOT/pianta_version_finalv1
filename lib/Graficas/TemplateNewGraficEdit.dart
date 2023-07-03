import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pianta/Graficas/VitualPinDatastream.dart';
import '../Home/graphics_model.dart';
import 'VitualPinDatastreamEdit.dart';

class TempCreateGraficsEdit extends StatefulWidget {
  final String title;
  final String name;
  final String alias;
  final String port;
  final int idTemplate;
  final String nameTemplate;

  const TempCreateGraficsEdit({Key? key, required this.title, required this.nameTemplate, required this.idTemplate, required this.port, required this.name, required this.alias}) : super(key: key);

  @override
  State<TempCreateGraficsEdit> createState() => _TempCreateGraficsEditState();
}

class _TempCreateGraficsEditState extends State<TempCreateGraficsEdit> {

  final graphicstemplate = graphics = [];
  List<String> listaDeOpciones = <String>["Temperatura", "Humedad"];
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
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: 900,
              height: 500,
              child: Form(

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
                        Text(
                          widget.title, // Mostrar el título pasado como parámetro
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
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
                                items: listaDeOpciones.map((e) {
                                  return DropdownMenuItem(child: Text(e), value: e);
                                }).toList(),
                                onChanged: (String? value) {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>  VirtualPinDatastreamEdit(name: widget.name, alias: widget.alias, port: widget.port, idTemplate: widget.idTemplate, nameTemplate: widget.nameTemplate,),
                                  ),
                                );
                              },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(90, 40),
                              backgroundColor: const Color.fromRGBO(0, 191, 174, 1),
                            ),
                            child: const Text('Next'),
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