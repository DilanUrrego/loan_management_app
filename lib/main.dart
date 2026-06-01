import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'firebase_options.dart';


/*
void main() {
  runApp(const MyApp());
}
*/
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Activos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);

  // Prueba rápida de "Crear" (Create)
  try {
    await FirebaseFirestore.instance.collection('pruebas').add({
      'mensaje': '¡Conexión exitosa desde Flutter!',
      'fecha': DateTime.now(),
    });
    print("✅ ¡Datos enviados a Firebase correctamente!");
  } catch (e) {
    print("❌ Error al enviar datos: $e");
  }

  runApp(const MyApp());
}
