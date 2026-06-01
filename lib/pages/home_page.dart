import 'package:flutter/material.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/asset.dart';
import 'activos_page.dart';
import 'prestamos_page.dart';
import 'devoluciones_page.dart';
import 'mantenimiento_page.dart';
import 'historial_page.dart';
import 'solicitar_prestamo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _crud = CrudService();
  final _session = SessionService();

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
    final user = _session.currentUser;

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
        ],
      ),

      // ── DRAWER ──────────────────────────────────────────────────────────────
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.indigo),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.name ?? 'Usuario',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Activos'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ActivosPage()));
                _loadDashboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Préstamos'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrestamosPage()));
                _loadDashboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Devoluciones'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const DevolucionesPage()));
                _loadDashboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Mantenimiento'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const MantenimientoPage()));
                _loadDashboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistorialPage()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                _session.clear();
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
                        _buildCard(
                          title: 'Disponibles',
                          value: '$_disponibles',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        _buildCard(
                          title: 'Prestados',
                          value: '$_prestados',
                          icon: Icons.assignment_returned,
                          color: Colors.orange,
                        ),
                        _buildCard(
                          title: 'Vencidos',
                          value: '$_vencidos',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                        _buildCard(
                          title: 'Mantenimiento',
                          value: '$_mantenimiento',
                          icon: Icons.build_circle,
                          color: Colors.blue,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SolicitarPrestamoPage()),
                  );
                  if (result == true) _loadDashboard();
                },
                icon: const Icon(Icons.add),
                label: const Text('Solicitar préstamo',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
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
              color: Colors.black.withOpacity(0.08),
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