import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pianta/Home/proyecto.dart';
import 'package:pianta/api_login.dart';
import 'package:pianta/constants.dart';
import 'package:pianta/pantalla/pantalla.dart';
import 'package:pianta/user_models.dart';
import 'register/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Box>(
        future: Hive.openBox(tokenBox),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var box = snapshot.data;
            var token = box!.get("token");
            bool showIntroScreen = box!.get("showIntroScreen") ?? true;
            box.put("showIntroScreen", false); // Guardar el valor actualizado

            if (token != null) {
              return FutureBuilder<User?>(
                future: getUser(token),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.data != null) {
                      User user = snapshot.data!;
                      user.token = token;
                      return const Proyectos();
                    } else {
                      return const Login();
                    }
                  } else {
                    return showIntroScreen ? IntroScreenDefault() : Container();
                  }
                },
              );
            } else {
              return showIntroScreen ? IntroScreenDefault() : const Login();
            }
          } else if (snapshot.hasError) {
            return IntroScreenDefault();
          } else {
            return Container();
          }
        },
      ),
    );
  }
}