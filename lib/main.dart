import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'data/crud_service.dart';
import 'data/session_service.dart';
import 'models/asset.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);

//Simular sesión de admin
  SessionService().setUser(User(
    uid: 'admin-test',
    name: 'Administrador',
    email: 'admin@institucion.com',
    role: UserRole.admin,
    status: AccountStatus.active,
  ));

  // Crear un asset nuevo en cada ejecución para pruebas
  final id = const Uuid().v4();
  final numero = DateTime.now().millisecondsSinceEpoch % 10000;
  await CrudService().addAsset(Asset(
    id: id,
    name: 'Laptop Dell #$numero',
    code: 'ACT-$numero',
    status: 'Disponible',
  ));

  runApp(const MyApp());
}

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