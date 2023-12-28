import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await dotenv.load(fileName: 'assets/.env'); // Load dotenv asynchronously
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'chat_screen.dart';
// import 'dart:ui' as ui;
// import 'dart:html' as html;

// // Call this method before building your widget tree in main.dart
// void registerHtmlElementView() {
//   // This should match the viewType used in HtmlElementView
//   const String viewType = 'drop-container';

//   // Register the view factory
//   ui.platformViewRegistry.registerViewFactory(
//     viewType,
//     (int viewId) {
//       // Create your HTML element here
//       html.DivElement element = html.DivElement();
//       // Configure your element and return it
//       return element;
//     },
//   );
// }


// void main() {
//   registerHtmlElementView();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Chat App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: ChatScreen(),
//     );
//   }
// }

