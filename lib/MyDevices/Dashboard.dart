import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:pianta/Graficas/TemplateNewGraficEdit.dart';
import 'package:pianta/MyDevices/DeviceGrafics.dart';
import 'package:pianta/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Funciones/constantes.dart';
import '../Graficas/TemplateNewGrafic.dart';
import '../Home/graphics_model.dart';
import '../Home/template_model.dart';
import '../UrlBackend.dart';

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

class WebDashboard extends StatefulWidget {
  final int idTemplate;
  final String nameTemplate;
  const WebDashboard(
      {Key? key, required this.idTemplate, required this.nameTemplate})
      : super(key: key);

  @override
  _WebDashboardState createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard>
    with SingleTickerProviderStateMixin {
  String lastData = 'v12';
  final graphicstemplate = graphics = [];
  late Future<List<GrapchisTemplate>> futureGraphics;

  late List<ProjectTemplate> projects;
  late Future<List<ProjectTemplate>> futureProjects;
  ProjectTemplate? projecto;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final maxProgress = 40.0;
  ProjectTemplate? project;
  late Future<List<SensorData>> _fetchDevicesFuture;
  Map<String, dynamic>? apiData;
  SensorData? selectedDevice;
  List<SensorData> device = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    futureProjects = fetchProjects();
    futureGraphics = fetchGraphics();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _animation = Tween<double>(
      begin: 0,
      end: maxProgress,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
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
          '$urlpianta/user/datos-sensores/$lastData/${widget.idTemplate}/'));
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
        '$urlpianta/user/datos-sensores/$lastData/${widget.idTemplate}/'));

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

  void fetchData() async {
    await fetchDevices(lastData);
    await _fetchData(lastData);
    setState(() {
      // Actualiza el estado para reflejar los cambios en los datos obtenidos
    });
  }

  Offset? finalPosition;
  List<Widget> duplicatedCards = [];

//esto es para mostrar la card
  Future<List<GrapchisTemplate>> fetchGraphics() async {
    var box = await Hive.openBox(tokenBox);
    final token = box.get("token") as String?;
    final response = await http.get(
      Uri.parse('$urlpianta/user/graphics/${widget.idTemplate}'),
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
      setState(() {
        this.projects = projects;
        projecto = projects.first;
      });
      return projects;
    } else {
      throw Exception('Failed to load project list');
    }
  }

  void _isCircularorLinealGraphic(bool isCircular) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_circular', isCircular);
  }

  bool isLoading = false;
  bool isCircular = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: 100,
            child: Navigation(
              title: 'nav',
              selectedIndex: 1,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nameTemplate,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Info',
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.black),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Acción a realizar al presionar el botón "Dashboard"
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WebDashboard(
                                        idTemplate: widget.idTemplate,
                                        nameTemplate: widget.nameTemplate,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Web Dashboard',
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                  child: Stack(
                    children: [
                      Positioned.fill(
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                              transform: Matrix4.translationValues(
                                  0, _animationController.value * 100, 0),
                              child: Column(
                                children: [
                                  Text(
                                    widget.nameTemplate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          fit: FlexFit.loose,
                                          child: Card(
                                            elevation: 8,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                            child: InkWell(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  InkWell(
                                                    onTap: () {},
                                                    child: Draggable<double>(
                                                      feedback: CustomPaint(
                                                        foregroundPainter:
                                                            Circular_graphics(
                                                                _animation
                                                                    .value),
                                                        child: const SizedBox(
                                                          width: 100,
                                                          height: 250,
                                                          child: Center(
                                                            child: Text(
                                                              '0 °C',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      30), //tamaño del numero de la circular al hacer la animacion de movimiento
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: CustomPaint(
                                                        foregroundPainter:
                                                            Circular_graphics(
                                                                _animation
                                                                    .value),
                                                        child: const SizedBox(
                                                          width:
                                                              200, //tamaño del recuadro de click en card principal
                                                          height:
                                                              200, //tamaño del recuadro de click en card principal
                                                          child: Center(
                                                            child: Text(
                                                              '0 °C',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      30), //tamaño de nuemro en card circular en la card principal de selección
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      childWhenDragging:
                                                          const SizedBox(),
                                                      onDraggableCanceled:
                                                          (Velocity velocity,
                                                              Offset offset) {
                                                        setState(() {
                                                          finalPosition =
                                                              offset;
                                                          duplicatedCards.add(
                                                            Positioned(
                                                              top:
                                                                  finalPosition!
                                                                      .dy,
                                                              left:
                                                                  finalPosition!
                                                                      .dx,
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  isCircular =
                                                                      true;
                                                                  _isCircularorLinealGraphic(
                                                                      isCircular);
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              TempCreateGrafics(
                                                                        id: widget
                                                                            .idTemplate,
                                                                        nameTemplate:
                                                                            widget.nameTemplate,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                child: Card(
                                                                  child:
                                                                      SizedBox(
                                                                    width:
                                                                        250, //tamaño card que se duplica
                                                                    height:
                                                                        250, //tamaño card que se duplica
                                                                    child:
                                                                        Stack(
                                                                      children: [
                                                                        Center(
                                                                          child:
                                                                              CustomPaint(
                                                                            painter:
                                                                                Circular_graphics(_animation.value),
                                                                            child:
                                                                                SizedBox(
                                                                              width: 200,
                                                                              height: 500,
                                                                              child: Center(
                                                                                child: Text(
                                                                                  '0 °C',
                                                                                  style: TextStyle(
                                                                                    fontSize: 30, //tamaño del numero dentro de la grafica circular duplicada
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {},
                                                    child: Draggable<double>(
                                                      feedback: SizedBox(
                                                        height: 200,
                                                        width: 200,
                                                        child: Linea_Graphics(),
                                                      ),
                                                      child: SizedBox(
                                                        height:
                                                            180, //Tamaño de la grafica lineal en la card de eleccion pricipal
                                                        width:
                                                            180, //Tamaño de la grafica lineal en la card de eleccion pricipal
                                                        child: Linea_Graphics(),
                                                      ),
                                                      childWhenDragging:
                                                          SizedBox(),
                                                      onDraggableCanceled:
                                                          (Velocity velocity,
                                                              Offset offset) {
                                                        setState(() {
                                                          finalPosition =
                                                              offset;
                                                          duplicatedCards.add(
                                                            Positioned(
                                                              top:
                                                                  finalPosition!
                                                                      .dy,
                                                              left:
                                                                  finalPosition!
                                                                      .dx,
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  isCircular =
                                                                      false;
                                                                  _isCircularorLinealGraphic(
                                                                      isCircular);
                                                                  // Acción a realizar al tocar la gráfica lineal duplicada
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (context) => TempCreateGrafics(
                                                                          id: widget
                                                                              .idTemplate,
                                                                          nameTemplate:
                                                                              widget.nameTemplate),
                                                                    ),
                                                                  );
                                                                },
                                                                child: SizedBox(
                                                                  height: 200,
                                                                  width: 200,
                                                                  child:
                                                                      Linea_Graphics(),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Card(
                                            child: FutureBuilder<
                                                List<GrapchisTemplate>>(
                                              future: futureGraphics,
                                              builder: (context, snapshot) {
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

                                                TextEditingController
                                                    titleController =
                                                    TextEditingController();
                                                TextEditingController
                                                    nameController =
                                                    TextEditingController();
                                                TextEditingController
                                                    aliasController =
                                                    TextEditingController();
                                                final _formKey =
                                                    GlobalKey<FormState>();

                                                if (snapshot.hasData) {
                                                  final projects =
                                                      snapshot.data!;
                                                  return GridView.builder(
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: MediaQuery
                                                                      .of(
                                                                          context)
                                                                  .size
                                                                  .width >
                                                              1200
                                                          ? 2
                                                          : MediaQuery.of(context)
                                                                      .size
                                                                      .width >
                                                                  800
                                                              ? 3
                                                              : MediaQuery.of(context)
                                                                          .size
                                                                          .width >
                                                                      600
                                                                  ? 3
                                                                  : 3,
                                                      mainAxisSpacing: 16,
                                                      crossAxisSpacing: 16,
                                                      childAspectRatio: 1.0,
                                                    ),
                                                    itemCount: projects.length,
                                                    itemBuilder:
                                                        (BuildContext context,
                                                            int index) {
                                                      final project =
                                                          projects[index];
                                                      lastData =
                                                          'v${project.ports}';
                                                      print(lastData);
                                                      final lastDatadates =
                                                          device.isNotEmpty
                                                              ? device.last
                                                              : null;
                                                      double? valueToDisplay =
                                                          0.0;
                                                      print(valueToDisplay);
                                                      // Comparar el valor de lastData con los campos de SensorData
                                                      if (lastData == 'v12') {
                                                        valueToDisplay =
                                                            lastDatadates?.v12;
                                                      } else if (lastData ==
                                                          'v11') {
                                                        valueToDisplay =
                                                            lastDatadates?.v11;
                                                      } else if (lastData ==
                                                          'v10') {
                                                        valueToDisplay =
                                                            lastDatadates?.v10;
                                                      } else if (lastData ==
                                                          'v9') {
                                                        valueToDisplay =
                                                            lastDatadates?.v9;
                                                      } else if (lastData ==
                                                          'v8') {
                                                        valueToDisplay =
                                                            lastDatadates?.v8;
                                                      } else if (lastData ==
                                                          'v7') {
                                                        valueToDisplay =
                                                            lastDatadates?.v7;
                                                      } else if (lastData ==
                                                          'v6') {
                                                        valueToDisplay =
                                                            lastDatadates?.v6;
                                                      } else if (lastData ==
                                                          'v5') {
                                                        valueToDisplay =
                                                            lastDatadates?.v5;
                                                      } else if (lastData ==
                                                          'v4') {
                                                        valueToDisplay =
                                                            lastDatadates?.v4;
                                                      } else if (lastData ==
                                                          'v3') {
                                                        valueToDisplay =
                                                            lastDatadates?.v3;
                                                      } else if (lastData ==
                                                          'v2') {
                                                        valueToDisplay =
                                                            lastDatadates?.v2;
                                                      } else if (lastData ==
                                                          'v1') {
                                                        valueToDisplay =
                                                            lastDatadates?.v1;
                                                      } else {
                                                        valueToDisplay = 0.0;
                                                      }
                                                      final title =
                                                          project.titlegraphics;
                                                      if (project.is_circular ==
                                                          true) {
                                                        return Container(
                                                          height: 1200,
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          TempCreateGraficsEdit(
                                                                    title: project
                                                                        .titlegraphics,
                                                                    name: project
                                                                        .namegraphics,
                                                                    alias: project
                                                                        .aliasgraphics,
                                                                    port: project
                                                                        .ports,
                                                                    nameTemplate:
                                                                        widget
                                                                            .nameTemplate,
                                                                    idTemplate:
                                                                        widget
                                                                            .idTemplate,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Card(
                                                              child: SizedBox(
                                                                width: 250,
                                                                height: 250,
                                                                child: Stack(
                                                                  children: [
                                                                    Center(
                                                                      child:
                                                                          CustomPaint(
                                                                        painter:
                                                                            Circular_graphics(valueToDisplay ??
                                                                                0.0),
                                                                        child:
                                                                            SizedBox(
                                                                          child:
                                                                              GestureDetector(
                                                                            child:
                                                                                Center(
                                                                              child: valueToDisplay == null
                                                                                  ? const Text(
                                                                                      '0 °C',
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
                                                                    Positioned(
                                                                      top: 10,
                                                                      right: 10,
                                                                      child:
                                                                          IconButton(
                                                                        icon: Icon(
                                                                            Icons.edit),
                                                                        onPressed:
                                                                            () async {
                                                                          titleController.text =
                                                                              project.titlegraphics ?? '';
                                                                          nameController.text =
                                                                              project.namegraphics ?? '';
                                                                          aliasController.text =
                                                                              project.aliasgraphics ?? '';
                                                                          // Acción para editar la tarjeta
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (context) {
                                                                              return AlertDialog(
                                                                                elevation: 4.0,
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(0),
                                                                                ),
                                                                                contentPadding: const EdgeInsets.all(30.0),
                                                                                content: SizedBox(
                                                                                  width: 350,
                                                                                  height: 400,
                                                                                  child: SingleChildScrollView(
                                                                                    child: Form(
                                                                                      key: _formKey,
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          const SizedBox(height: 16.0),
                                                                                          const Text(
                                                                                            'Edit Graphics',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 18.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          Text(
                                                                                            'Chart title: ',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          TextFormField(
                                                                                            //initialValue: _username ?? '',
                                                                                            controller: titleController,
                                                                                            validator: (valor) {
                                                                                              if (valor!.isEmpty || !RegExp(r'^[a-z A-Z]+$').hasMatch(valor)) {
                                                                                                //allow upper and lower case alphabets and space
                                                                                                return "Please enter your name";
                                                                                              } else if (valor?.trim()?.isEmpty ?? true) {
                                                                                                return 'your password must have digits';
                                                                                              } else {
                                                                                                return null;
                                                                                              }
                                                                                            },
                                                                                            keyboardType: TextInputType.text,
                                                                                            //initialValue: _username, // Agregamos el valor inicial aquí
                                                                                            decoration: const InputDecoration(
                                                                                              prefixIcon: Icon(Icons.incomplete_circle_sharp),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  width: 1,
                                                                                                  color: Colors.grey,
                                                                                                ), //<-- SEE HERE
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          const Text(
                                                                                            'Chart Name :',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0, // Se ha cambiado el tamaño a 14.0
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          TextFormField(
                                                                                            //initialValue: _email ?? '',
                                                                                            controller: nameController,
                                                                                            validator: (valor) {
                                                                                              if (valor!.isEmpty || !RegExp(r'^[a-z A-Z]+$').hasMatch(valor)) {
                                                                                                //allow upper and lower case alphabets and space
                                                                                                return "Please enter your name";
                                                                                              } else if (valor?.trim()?.isEmpty ?? true) {
                                                                                                return 'your password must have digits';
                                                                                              } else {
                                                                                                return null;
                                                                                              }
                                                                                            },
                                                                                            keyboardType: TextInputType.text,
                                                                                            decoration: const InputDecoration(
                                                                                              prefixIcon: Icon(Icons.supervised_user_circle_outlined),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  width: 1,
                                                                                                  color: Colors.grey,
                                                                                                ), //<-- SEE HERE
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          Text(
                                                                                            'Chart alias: ',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          TextFormField(
                                                                                            //initialValue: _username ?? '',
                                                                                            controller: aliasController,
                                                                                            validator: (valor) {
                                                                                              if (valor!.isEmpty || !RegExp(r'^[a-z A-Z]+$').hasMatch(valor)) {
                                                                                                //allow upper and lower case alphabets and space
                                                                                                return "Please enter your name";
                                                                                              } else if (valor?.trim()?.isEmpty ?? true) {
                                                                                                return 'your password must have digits';
                                                                                              } else {
                                                                                                return null;
                                                                                              }
                                                                                            },
                                                                                            keyboardType: TextInputType.text,
                                                                                            //initialValue: _username, // Agregamos el valor inicial aquí
                                                                                            decoration: const InputDecoration(
                                                                                              prefixIcon: Icon(Icons.alternate_email_outlined),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  width: 1,
                                                                                                  color: Colors.grey,
                                                                                                ), //<-- SEE HERE
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 20),
                                                                                          Text(
                                                                                            'Elegir PIN',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 20),
                                                                                          DropdownButtonFormField<double>(
                                                                                            value: _selectedValue,
                                                                                            onChanged: (value) {
                                                                                              setState(() {
                                                                                                _selectedValue = value!;
                                                                                              });
                                                                                            },
                                                                                            items: _vValues.map<DropdownMenuItem<double>>((value) {
                                                                                              return DropdownMenuItem<double>(
                                                                                                value: value,
                                                                                                child: Text('v$value'),
                                                                                              );
                                                                                            }).toList(),
                                                                                          ),
                                                                                          const SizedBox(height: 20),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.all(30),
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                              children: [
                                                                                                ElevatedButton(
                                                                                                  onPressed: () {
                                                                                                    Navigator.of(context).pop();
                                                                                                  },
                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                    minimumSize: const Size(90, 30),
                                                                                                    backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
                                                                                                  ),
                                                                                                  child: const Text(
                                                                                                    'Cancel',
                                                                                                    style: TextStyle(fontSize: 12, color: Color.fromRGBO(16, 16, 16, 1)),
                                                                                                  ),
                                                                                                ),
                                                                                                const SizedBox(
                                                                                                  width: 25, // Espacio de 16 píxeles entre los botones
                                                                                                ),
                                                                                                ElevatedButton(
                                                                                                  onPressed: () async {
                                                                                                    if (_formKey.currentState!.validate()) {
                                                                                                      var box = await Hive.openBox(tokenBox);
                                                                                                      final token = box.get("token") as String?;
                                                                                                      final response = await http.put(
                                                                                                        Uri.parse('$urlpianta/user/graphics/${widget.idTemplate}/${project.id}/'),
                                                                                                        headers: {
                                                                                                          'Authorization': 'Token $token',
                                                                                                          'Content-Type': 'application/json',
                                                                                                          // Especifica el tipo de contenido del cuerpo de la solicitud
                                                                                                        },
                                                                                                        body: jsonEncode({
                                                                                                          'titlegraphics': titleController.text,
                                                                                                          'namegraphics': nameController.text,
                                                                                                          'aliasgraphics': aliasController.text,
                                                                                                          'ports': _selectedValue.toString(),
                                                                                                        }),
                                                                                                      );
                                                                                                      if (response.statusCode == 200) {
                                                                                                        print(response.body);
                                                                                                      } else {
                                                                                                        print("Could not update graph: ${response.body}");
                                                                                                      }
                                                                                                      Navigator.push(
                                                                                                        context,
                                                                                                        MaterialPageRoute(builder: (context) => WebDashboard(idTemplate: widget.idTemplate, nameTemplate: widget.nameTemplate)),
                                                                                                      );
                                                                                                    }
                                                                                                  },
                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                    minimumSize: const Size(90, 30),
                                                                                                    backgroundColor: const Color.fromRGBO(0, 191, 174, 1),
                                                                                                  ),
                                                                                                  child: const Text(
                                                                                                    'Done',
                                                                                                    style: TextStyle(
                                                                                                      fontSize: 12,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Positioned(
                                                                      top: 125,
                                                                      right: 10,
                                                                      child:
                                                                          IconButton(
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .fullscreen,
                                                                            color:
                                                                                Colors.black),
                                                                        onPressed:
                                                                            () async {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContext context) {
                                                                              final double graphSize = 400.0;
                                                                              return Dialog(
                                                                                child: Container(
                                                                                  width: 1000,
                                                                                  height: 1000,
                                                                                  child: Card(
                                                                                    child: Column(
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
                                                                                                  icon: const Icon(Icons.exit_to_app))),
                                                                                        ),
                                                                                        // Agrega aquí los elementos que desees mostrar en la tarjeta
                                                                                        // por ejemplo:
                                                                                        Padding(
                                                                                          padding: EdgeInsets.all(16.0),
                                                                                          child: Text(
                                                                                            'Gráfica circular: $title',
                                                                                            style: TextStyle(
                                                                                              fontSize: 30,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        Padding(
                                                                                          padding: EdgeInsets.all(59.0),
                                                                                          child: Container(
                                                                                              child: SizedBox(
                                                                                            height: 250, //tamaño de la grafica lineal en las card duplicadas
                                                                                            width: 250,
                                                                                            child: CustomPaint(
                                                                                              size: Size(graphSize, graphSize),
                                                                                              painter: Circular_Big(valueToDisplay ?? 0.0),
                                                                                              child: SizedBox(
                                                                                                child: GestureDetector(
                                                                                                  child: Center(
                                                                                                    child: valueToDisplay == null
                                                                                                        ? const Text(
                                                                                                            '°C',
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
                                                                                          )),
                                                                                        ),

                                                                                        Wrap(
                                                                                          spacing: 16.0, // Espacio horizontal entre los elementos del Wrap
                                                                                          runSpacing: 8.0, // Espacio vertical entre las líneas de texto
                                                                                          children: [
                                                                                            Text(
                                                                                              title,
                                                                                              style: const TextStyle(
                                                                                                fontWeight: FontWeight.bold,
                                                                                                fontSize: 20,
                                                                                              ),
                                                                                              textAlign: TextAlign.left,
                                                                                            ),
                                                                                            Text(
                                                                                              'Port: ${project.ports}',
                                                                                              style: TextStyle(
                                                                                                fontWeight: FontWeight.bold,
                                                                                                fontSize: 20,
                                                                                              ),
                                                                                              textAlign: TextAlign.center,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                        // Otros elementos de la tarjeta
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Positioned(
                                                                      bottom:
                                                                          10,
                                                                      right: 10,
                                                                      child:
                                                                          IconButton(
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .delete,
                                                                            color:
                                                                                Colors.black),
                                                                        onPressed:
                                                                            () async {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContext context) {
                                                                              return AlertDialog(
                                                                                title: const Text('Delete Graphic?'),
                                                                                content: const Text('Are you sure you want to delete this Graphic?'),
                                                                                actions: <Widget>[
                                                                                  Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                    children: [
                                                                                      TextButton(
                                                                                        style: ButtonStyle(
                                                                                          backgroundColor: MaterialStateProperty.all<Color>(
                                                                                            Colors.red,
                                                                                          ),
                                                                                        ),
                                                                                        onPressed: () async {
                                                                                          final response = await http.delete(Uri.parse('$urlpianta/user/graphics/${widget.idTemplate}/${project.id}/'));
                                                                                          if (response.statusCode == 204) {
                                                                                          } else {
                                                                                            print("could not delete graph");
                                                                                          }
                                                                                          await fetchGraphics();
                                                                                          Navigator.push(
                                                                                            context,
                                                                                            MaterialPageRoute(
                                                                                              builder: (context) => WebDashboard(idTemplate: widget.idTemplate, nameTemplate: widget.nameTemplate),
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                        child: const Text(
                                                                                          'Delete',
                                                                                          style: TextStyle(
                                                                                            color: Colors.white,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      Spacer(),
                                                                                      TextButton(
                                                                                        style: ButtonStyle(
                                                                                          backgroundColor: MaterialStateProperty.all<Color>(
                                                                                            const Color.fromRGBO(0, 191, 174, 1),
                                                                                          ),
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          Navigator.of(context).pop();
                                                                                        },
                                                                                        child: const Text(
                                                                                          'Cancel',
                                                                                          style: TextStyle(
                                                                                            fontWeight: FontWeight.bold,
                                                                                            fontSize: 12,
                                                                                            color: Colors.white,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Container(
                                                          height: 1200,
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          TempCreateGraficsEdit(
                                                                    title: project
                                                                        .titlegraphics,
                                                                    name: project
                                                                        .namegraphics,
                                                                    alias: project
                                                                        .aliasgraphics,
                                                                    port: project
                                                                        .ports,
                                                                    nameTemplate:
                                                                        widget
                                                                            .nameTemplate,
                                                                    idTemplate:
                                                                        widget
                                                                            .idTemplate,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Card(
                                                              child: SizedBox(
                                                                width: 250,
                                                                height: 250,
                                                                child: Stack(
                                                                  children: [
                                                                    Center(
                                                                      child:
                                                                          SizedBox(
                                                                        height:
                                                                            180, //tamaño de la grafica lineal en las card duplicadas
                                                                        width:
                                                                            180, //tamaño de la grafica lineal en las card duplicadas
                                                                        child:
                                                                            Linea_Graphicss(),
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
                                                                    Positioned(
                                                                      top: 10,
                                                                      right: 10,
                                                                      child:
                                                                          IconButton(
                                                                        icon: const Icon(
                                                                            Icons.edit),
                                                                        onPressed:
                                                                            () async {
                                                                          titleController.text =
                                                                              project.titlegraphics ?? '';
                                                                          nameController.text =
                                                                              project.namegraphics ?? '';
                                                                          aliasController.text =
                                                                              project.aliasgraphics ?? '';
                                                                          // Acción para editar la tarjeta
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (context) {
                                                                              return AlertDialog(
                                                                                elevation: 4.0,
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(0),
                                                                                ),
                                                                                contentPadding: const EdgeInsets.all(30.0),
                                                                                content: SizedBox(
                                                                                  width: 350,
                                                                                  height: 400,
                                                                                  child: SingleChildScrollView(
                                                                                    child: Form(
                                                                                      key: _formKey,
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          const SizedBox(height: 16.0),
                                                                                          const Text(
                                                                                            'Edit Graphics',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 18.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          Text(
                                                                                            'Chart title: ',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          TextFormField(
                                                                                            //initialValue: _username ?? '',
                                                                                            controller: titleController,
                                                                                            validator: (valor) {
                                                                                              if (valor!.isEmpty || !RegExp(r'^[a-z A-Z]+$').hasMatch(valor)) {
                                                                                                //allow upper and lower case alphabets and space
                                                                                                return "Please enter your name";
                                                                                              } else if (valor?.trim()?.isEmpty ?? true) {
                                                                                                return 'your password must have digits';
                                                                                              } else {
                                                                                                return null;
                                                                                              }
                                                                                            },
                                                                                            keyboardType: TextInputType.text,
                                                                                            //initialValue: _username, // Agregamos el valor inicial aquí
                                                                                            decoration: const InputDecoration(
                                                                                              prefixIcon: Icon(Icons.incomplete_circle_sharp),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  width: 1,
                                                                                                  color: Colors.grey,
                                                                                                ), //<-- SEE HERE
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          const Text(
                                                                                            'Chart Name :',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0, // Se ha cambiado el tamaño a 14.0
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          TextFormField(
                                                                                            //initialValue: _email ?? '',
                                                                                            controller: nameController,
                                                                                            validator: (valor) {
                                                                                              if (valor!.isEmpty || !RegExp(r'^[a-z A-Z]+$').hasMatch(valor)) {
                                                                                                //allow upper and lower case alphabets and space
                                                                                                return "Please enter your name";
                                                                                              } else if (valor?.trim()?.isEmpty ?? true) {
                                                                                                return 'your password must have digits';
                                                                                              } else {
                                                                                                return null;
                                                                                              }
                                                                                            },
                                                                                            keyboardType: TextInputType.text,
                                                                                            decoration: const InputDecoration(
                                                                                              prefixIcon: Icon(Icons.supervised_user_circle_outlined),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  width: 1,
                                                                                                  color: Colors.grey,
                                                                                                ), //<-- SEE HERE
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          Text(
                                                                                            'Chart alias: ',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 16.0),
                                                                                          TextFormField(
                                                                                            //initialValue: _username ?? '',
                                                                                            controller: aliasController,
                                                                                            validator: (valor) {
                                                                                              if (valor!.isEmpty || !RegExp(r'^[a-z A-Z]+$').hasMatch(valor)) {
                                                                                                //allow upper and lower case alphabets and space
                                                                                                return "Please enter your name";
                                                                                              } else if (valor?.trim()?.isEmpty ?? true) {
                                                                                                return 'your password must have digits';
                                                                                              } else {
                                                                                                return null;
                                                                                              }
                                                                                            },
                                                                                            keyboardType: TextInputType.text,
                                                                                            //initialValue: _username, // Agregamos el valor inicial aquí
                                                                                            decoration: const InputDecoration(
                                                                                              prefixIcon: Icon(Icons.alternate_email_outlined),
                                                                                              enabledBorder: OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                  width: 1,
                                                                                                  color: Colors.grey,
                                                                                                ), //<-- SEE HERE
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 20),
                                                                                          Text(
                                                                                            'Elegir PIN',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              fontSize: 14.0,
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(height: 20),
                                                                                          DropdownButtonFormField<double>(
                                                                                            value: _selectedValue,
                                                                                            onChanged: (value) {
                                                                                              setState(() {
                                                                                                _selectedValue = value!;
                                                                                              });
                                                                                            },
                                                                                            items: _vValues.map<DropdownMenuItem<double>>((value) {
                                                                                              return DropdownMenuItem<double>(
                                                                                                value: value,
                                                                                                child: Text('v$value'),
                                                                                              );
                                                                                            }).toList(),
                                                                                          ),
                                                                                          const SizedBox(height: 20),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.all(30),
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                              children: [
                                                                                                ElevatedButton(
                                                                                                  onPressed: () {
                                                                                                    Navigator.of(context).pop();
                                                                                                  },
                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                    minimumSize: const Size(90, 30),
                                                                                                    backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
                                                                                                  ),
                                                                                                  child: const Text(
                                                                                                    'Cancel',
                                                                                                    style: TextStyle(fontSize: 12, color: Color.fromRGBO(16, 16, 16, 1)),
                                                                                                  ),
                                                                                                ),
                                                                                                const SizedBox(
                                                                                                  width: 25, // Espacio de 16 píxeles entre los botones
                                                                                                ),
                                                                                                ElevatedButton(
                                                                                                  onPressed: () async {
                                                                                                    if (_formKey.currentState!.validate()) {
                                                                                                      var box = await Hive.openBox(tokenBox);
                                                                                                      final token = box.get("token") as String?;
                                                                                                      final response = await http.put(
                                                                                                        Uri.parse('$urlpianta/user/graphics/${widget.idTemplate}/${project.id}/'),
                                                                                                        headers: {
                                                                                                          'Authorization': 'Token $token',
                                                                                                          'Content-Type': 'application/json',
                                                                                                          // Especifica el tipo de contenido del cuerpo de la solicitud
                                                                                                        },
                                                                                                        body: jsonEncode({
                                                                                                          'titlegraphics': titleController.text,
                                                                                                          'namegraphics': nameController.text,
                                                                                                          'aliasgraphics': aliasController.text,
                                                                                                          'ports': _selectedValue.toString(),
                                                                                                        }),
                                                                                                      );
                                                                                                      if (response.statusCode == 200) {
                                                                                                        print(response.body);
                                                                                                      } else {
                                                                                                        print("Could not update graph: ${response.body}");
                                                                                                      }
                                                                                                      Navigator.push(
                                                                                                          context,
                                                                                                          MaterialPageRoute(
                                                                                                            builder: (context) => WebDashboard(idTemplate: widget.idTemplate, nameTemplate: widget.nameTemplate),
                                                                                                          ));
                                                                                                    }
                                                                                                  },
                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                    minimumSize: const Size(90, 30),
                                                                                                    backgroundColor: const Color.fromRGBO(0, 191, 174, 1),
                                                                                                  ),
                                                                                                  child: const Text(
                                                                                                    'Done',
                                                                                                    style: TextStyle(
                                                                                                      fontSize: 12,
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                    //Boton gráfica lineal más grande
                                                                    Positioned(
                                                                      top: 125,
                                                                      right: 10,
                                                                      child:
                                                                          IconButton(
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .fullscreen,
                                                                            color:
                                                                                Colors.black),
                                                                        onPressed:
                                                                            () async {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContext context) {
                                                                              final double graphSize = 400.0;
                                                                              return Dialog(
                                                                                child: Container(
                                                                                  width: 1000,
                                                                                  height: 1000,
                                                                                  child: Card(
                                                                                    child: Column(
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
                                                                                                  icon: const Icon(Icons.exit_to_app))),
                                                                                        ),
                                                                                        // Agrega aquí los elementos que desees mostrar en la tarjeta
                                                                                        // por ejemplo:
                                                                                        Padding(
                                                                                          padding: EdgeInsets.all(16.0),
                                                                                          child: Text(
                                                                                            'Gráfica lineal: $title',
                                                                                            style: TextStyle(
                                                                                              fontSize: 30,
                                                                                              fontWeight: FontWeight.bold,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                        Padding(
                                                                                          padding: EdgeInsets.all(59.0),
                                                                                          child: Center(
                                                                                            child: SizedBox(
                                                                                              height: 250, //tamaño de la grafica lineal en las card duplicadas
                                                                                              width: 250, //tamaño de la grafica lineal en las card duplicadas
                                                                                              child: Linea_Graphics(),
                                                                                            ),
                                                                                          ),
                                                                                        ),

                                                                                        Wrap(
                                                                                          spacing: 16.0, // Espacio horizontal entre los elementos del Wrap
                                                                                          runSpacing: 8.0, // Espacio vertical entre las líneas de texto
                                                                                          children: [
                                                                                            Text(
                                                                                              title,
                                                                                              style: const TextStyle(
                                                                                                fontWeight: FontWeight.bold,
                                                                                                fontSize: 20,
                                                                                              ),
                                                                                              textAlign: TextAlign.left,
                                                                                            ),
                                                                                            Text(
                                                                                              'Port: ${project.ports}',
                                                                                              style: TextStyle(
                                                                                                fontWeight: FontWeight.bold,
                                                                                                fontSize: 20,
                                                                                              ),
                                                                                              textAlign: TextAlign.center,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                        // Otros elementos de la tarjeta
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Positioned(
                                                                      bottom:
                                                                          10,
                                                                      right: 10,
                                                                      child:
                                                                          IconButton(
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .delete,
                                                                            color:
                                                                                Colors.black),
                                                                        onPressed:
                                                                            () async {
                                                                          showDialog(
                                                                            context:
                                                                                context,
                                                                            builder:
                                                                                (BuildContext context) {
                                                                              return AlertDialog(
                                                                                title: const Text('Delete Graphic?'),
                                                                                content: const Text('Are you sure you want to delete this Graphic?'),
                                                                                actions: <Widget>[
                                                                                  Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                    children: [
                                                                                      TextButton(
                                                                                        style: ButtonStyle(
                                                                                          backgroundColor: MaterialStateProperty.all<Color>(
                                                                                            Colors.red,
                                                                                          ),
                                                                                        ),
                                                                                        onPressed: () async {
                                                                                          final response = await http.delete(Uri.parse('$urlpianta`/user/graphics/${widget.idTemplate}/${project.id}/'));
                                                                                          if (response.statusCode == 204) {
                                                                                          } else {
                                                                                            print("could not delete graph");
                                                                                          }
                                                                                          await fetchGraphics();
                                                                                          Navigator.push(
                                                                                            context,
                                                                                            MaterialPageRoute(
                                                                                              builder: (context) => WebDashboard(idTemplate: widget.idTemplate, nameTemplate: widget.nameTemplate),
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                        child: const Text(
                                                                                          'Delete',
                                                                                          style: TextStyle(
                                                                                            color: Colors.white,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      Spacer(),
                                                                                      TextButton(
                                                                                        style: ButtonStyle(
                                                                                          backgroundColor: MaterialStateProperty.all<Color>(
                                                                                            const Color.fromRGBO(0, 191, 174, 1),
                                                                                          ),
                                                                                        ),
                                                                                        onPressed: () {
                                                                                          Navigator.of(context).pop();
                                                                                        },
                                                                                        child: const Text(
                                                                                          'Cancel',
                                                                                          style: TextStyle(
                                                                                            fontWeight: FontWeight.bold,
                                                                                            fontSize: 12,
                                                                                            color: Colors.white,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      ),
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
                                                  return Text(
                                                      "${snapshot.error}");
                                                }
                                                // By default, show a loading spinner
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
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
                          ),
                        ),
                      ),
                      ...duplicatedCards,
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

class Circular_graphics extends CustomPainter {
  final double currentProgress;

  Circular_graphics(this.currentProgress);

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
    double radius = 60.0;
    canvas.drawCircle(center, radius, circle);

    Paint animationArc = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (currentProgress > 30) {
      animationArc.color = Colors.red;
    } else if (currentProgress > 15) {
      animationArc.color = Colors.orange;
    } else if (currentProgress > 10) {
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

//utilizar clase con una grafica circular más grande
class Circular_Big extends CustomPainter {
  final double currentProgress;

  Circular_Big(this.currentProgress);

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
    double radius = 180.0;
    canvas.drawCircle(center, radius, circle);

    Paint animationArc = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (currentProgress > 30) {
      animationArc.color = Colors.red;
    } else if (currentProgress > 15) {
      animationArc.color = Colors.orange;
    } else if (currentProgress > 10) {
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


class Linea_Graphics extends StatelessWidget {
  const Linea_Graphics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = [
      Expenses(2, 120),
      Expenses(3, 220),
      Expenses(4, 219),
      Expenses(5, 154),
      Expenses(6, 310),
      Expenses(7, 290),
      Expenses(8, 390),
    ];
    final series = [
      charts.Series(
        id: 'Expenses',
        data: data,
        domainFn: (Expenses expenses, _) => expenses.day,
        measureFn: (Expenses expenses, _) => expenses.amount,
      ),
    ];

    final chart = charts.LineChart(
      series,
      animate: true,
    );

    return AbsorbPointer(
      absorbing: true, // Deshabilita la interacción con los widgets hijos
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: chart,
      ),
    );
  }
}

class Expenses {
  final int day;
  final int amount;

  Expenses(this.day, this.amount);
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

