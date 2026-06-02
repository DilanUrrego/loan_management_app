import 'package:flutter/material.dart';
import '../data/session_service.dart';
import '../models/user.dart' as app_model;
import 'home_page.dart';
import 'activos_page.dart';
import 'prestamos_page.dart';
import 'mantenimiento_page.dart';
import 'historial_page.dart';
import 'usuarios_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final app_model.UserRole _role;

  @override
  void initState() {
    super.initState();
    _role = SessionService().currentUser?.role ?? app_model.UserRole.requester;
  }

  // --- Definición de pestañas por rol ---

  List<Widget> _getPages() {
    switch (_role) {
      case app_model.UserRole.admin:
        return const [
          HomePage(), // Dashboard
          UsuariosPage(),
          ActivosPage(),
        ];
      case app_model.UserRole.inventoryManager:
        return const [
          ActivosPage(),
          PrestamosPage(),
          MantenimientoPage(),
          HistorialPage(),
        ];
      case app_model.UserRole.requester:
        return const [
          PrestamosPage(), // Mostrará "Mis Préstamos"
          ActivosPage(),   // Mostrará "Disponibles"
          HistorialPage(), // Mostrará "Mi Historial"
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavBarItems() {
    switch (_role) {
      case app_model.UserRole.admin:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Activos'),
        ];
      case app_model.UserRole.inventoryManager:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Activos'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Préstamos'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Mantenimiento'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        ];
      case app_model.UserRole.requester:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_ind), label: 'Mis Préstamos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Solicitar'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Mi Historial'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    final items = _getNavBarItems();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: items,
      ),
    );
  }
}
