import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../data/crud_service.dart';
import 'activos_page.dart';
import 'prestamos_page.dart';
import 'mantenimiento_page.dart';
import 'solicitar_prestamo_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _crud = CrudService();

  int _disponibles = 0;
  int _prestados = 0;
  int _vencidos = 0;
  int _mantenimiento = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    final assets = await _crud.getAssets();
    setState(() {
      _disponibles =
          assets.where((a) => a.status == 'Disponible').length;
      _prestados =
          assets.where((a) => a.status == 'Prestado').length;
      _vencidos =
          assets.where((a) => a.status == 'Vencido').length;
      _mantenimiento =
          assets.where((a) => a.status == 'Mantenimiento').length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
        title: const Text(
          'Control de Activos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),

      // ── BODY ────────────────────────────────────────────────────────────────
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.indigo))
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivosPage(initialFilter: 'Disponible'))),
                          child: _buildCard(
                            title: 'Disponibles',
                            value: '$_disponibles',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivosPage(initialFilter: 'Prestado'))),
                          child: _buildCard(
                            title: 'Prestados',
                            value: '$_prestados',
                            icon: Icons.assignment_returned,
                            color: Colors.orange,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrestamosPage(initialFilter: 'Vencido'))),
                          child: _buildCard(
                            title: 'Vencidos',
                            value: '$_vencidos',
                            icon: Icons.warning,
                            color: Colors.red,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MantenimientoPage())),
                          child: _buildCard(
                            title: 'Mantenimiento',
                            value: '$_mantenimiento',
                            icon: Icons.build_circle,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 15),
            Text(value,
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}