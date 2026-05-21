import 'package:flutter/material.dart';
import 'activos_page.dart';
import 'prestamos_page.dart';
import 'devoluciones_page.dart';
import 'mantenimiento_page.dart';
import 'historial_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      // APPBAR
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
        title: const Text(
          "Control de Activos",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.indigo,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Administrador",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "admin@institucion.com",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // ACTIVOS
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text("Activos"),

              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivosPage(),
                  ),
                );

              },
            ),

            // PRESTAMOS
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Préstamos"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrestamosPage(),
                  ),
                );
              },
            ),

            // MANTENIMIENTO
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text("Mantenimiento"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MantenimientoPage(),
                  ),
                );
              },
            ),

            // HISTORIAL
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Historial"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistorialPage(),
                  ),
                );
              },
            ),

            const Divider(),

            // CERRAR SESION
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () {},
            ),
          ],
        ),
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  buildCard(
                    title: "Disponibles",
                    value: "15",
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),

                  buildCard(
                    title: "Prestados",
                    value: "8",
                    icon: Icons.assignment_returned,
                    color: Colors.orange,
                  ),

                  buildCard(
                    title: "Vencidos",
                    value: "3",
                    icon: Icons.warning,
                    color: Colors.red,
                  ),

                  buildCard(
                    title: "Mantenimiento",
                    value: "4",
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
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text(
                  "Solicitar préstamo",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard({
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: color,
            ),

            const SizedBox(height: 15),

            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}