// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:intro_slider/intro_slider.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../register/login.dart';

// //se entrega la pantalla
// class IntroScreenDefault extends StatefulWidget {
//   @override
//   _IntroScreenDefaultState createState() => _IntroScreenDefaultState();
// }

// class _IntroScreenDefaultState extends State<IntroScreenDefault> {
//   List<ContentConfig> listContentConfig = [];
//   double opacityValue = 0.5;
//   void onDonePress() {
//     log("End of slides");
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("¿Do you want to download the PDF?"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => Login()),
//               ); // Cierra el cuadro de diálogo // Cierra el cuadro de diálogo
//               abrirLinkGoogleDrive();
//             },
//             child: Text("YES"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => Login()),
//               ); // Cierra el cuadro de diálogo
//             },
//             child: Text("NO"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> abrirLinkGoogleDrive() async {
//     const url =
//         'https://drive.google.com/file/d/1Al-aaxG0gaZ8tr3BJP-JuF_vFjmOuUmN/view?usp=sharing'; // Reemplaza con la URL de tu archivo PDF en Google Drive
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       log('No se pudo abrir el enlace');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     List<ContentConfig> listContentConfig = [];

//     listContentConfig.add(
//       const ContentConfig(
//           title: "WELCOME",
//           description:
//               "An IOT platform that presents a comprehensive solution designed specifically for monitoring temperature and humidity in the plants’ environment . Using a network of smart sensors, this platform allows you to obtain accurate and real-time data on air temperature and soil humidity, giving you valuable information to optimize the care of your plants.",
//           pathImage: "images/Logotipo_pianta.png",
//           backgroundImage: "images/fondo.jpg"),
//     );

//     listContentConfig.add(
//       const ContentConfig(
//         title: "SLIDER 2",
//         description:
//             "PIANTA offers you a complete and detailed vision of the environment in different places. It's like having a magical window to the world around you!",
//         pathImage: "images/Logotipo_pianta.png",
//       backgroundImage: "images/fondo2.jpg"
//       ),
//     );
//         listContentConfig.add(
//       const ContentConfig(
//         title: "Developers",
//         description:
//             "Pianta is developed by:\nSebastian Girardot\nkatherine lugo\nalexander vera \nDaniel Sanchez \nKelly Ascanio  \nThank you for having us",
//         pathImage: "images/Logotipo_pianta.png",
//       backgroundImage: "images/fondo3.jpg"
//       ),
//     );
//     return Stack(
//       children: [
//         Image.asset(
//           'images/pianta.gif',
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//         ),
//         Center(
//           child: Card(
//             child: Container(
//               width: 900,
//               height: 600,
//               child: IntroSlider(
//                 key: UniqueKey(),
//                 listContentConfig: listContentConfig,
//                 onDonePress: onDonePress,
//               ),
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../register/login.dart';

//se entrega la pantalla
class IntroScreenDefault extends StatefulWidget {
  @override
  _IntroScreenDefaultState createState() => _IntroScreenDefaultState();
}

class _IntroScreenDefaultState extends State<IntroScreenDefault> {
  List<ContentConfig> listContentConfig = [];
  double opacityValue = 0.5;
  void onDonePress() {
    log("End of slides");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¿Do you want to download the PDF?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              ); // Cierra el cuadro de diálogo // Cierra el cuadro de diálogo
              abrirLinkGoogleDrive();
            },
            child: Text("YES"),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              ); // Cierra el cuadro de diálogo
            },
            child: Text("NO"),
          ),
        ],
      ),
    );
  }

  Future<void> abrirLinkGoogleDrive() async {
    const url =
        'https://drive.google.com/file/d/1Al-aaxG0gaZ8tr3BJP-JuF_vFjmOuUmN/view?usp=sharing'; // Reemplaza con la URL de tu archivo PDF en Google Drive
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      log('No se pudo abrir el enlace');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ContentConfig> listContentConfig = [];

    listContentConfig.add(
      const ContentConfig(
        title: "WELCOME",
        description:
        "An IOT platform that presents a comprehensive solution designed specifically for monitoring temperature and humidity in the plants’ environment . Using a network of smart sensors, this platform allows you to obtain accurate and real-time data on air temperature and soil humidity, giving you valuable information to optimize the care of your plants.",
        pathImage: "images/Logotipo_pianta.png",
      ),
    );

    listContentConfig.add(
      const ContentConfig(
        title: "Join us!",
        description:
        "Discover Pianta, the solution that collects and processes real-time environmental data. With its help, you can drive efficient monitoring and make informed decisions across various sectors. Join us and be part of the change towards a more conscious future.",
        pathImage: "images/Logotipo_pianta.png",
      ),
    );
    listContentConfig.add(
      const ContentConfig(
        title: "Developers",
        description:
        "Pianta is developed by:\nSebastian Girardot\nDaniel Sanchez\nKatherine Lugo\nAlexander Vera \nKelly Ascanio  \nThank you for having us",
        pathImage: "images/Logotipo_pianta.png",
      ),
    );
    return Stack(
      children: [
        ColorFiltered(
          colorFilter:
          ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
          child: Image.asset(
            'images/pianta.gif',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: Container(
            child: IntroSlider(
              key: UniqueKey(),
              listContentConfig: listContentConfig,
              onDonePress: onDonePress,
            ),
          ),
        ),
      ],
    );
  }
}