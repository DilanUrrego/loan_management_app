import 'package:flutter/material.dart';
import '../widgets/devolucion_card.dart';

class DevolucionesPage extends StatelessWidget {
  const DevolucionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        title: const Text("Devoluciones"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () {},
        child: const Icon(Icons.keyboard_return),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // BUSCADOR
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar devolución...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LISTA
            Expanded(
              child: ListView(
                children: const [

                  DevolucionCard(
                    usuario: "Juan Pérez",
                    activo: "Laptop Dell",
                    fecha: "22 Mayo 2026",
                    estado: "Devuelto",
                    colorEstado: Colors.green,
                  ),

                  SizedBox(height: 15),

                  DevolucionCard(
                    usuario: "María Gómez",
                    activo: "Tablet Samsung",
                    fecha: "21 Mayo 2026",
                    estado: "Pendiente",
                    colorEstado: Colors.orange,
                  ),

                  SizedBox(height: 15),

                  DevolucionCard(
                    usuario: "Carlos Ruiz",
                    activo: "Video Beam Epson",
                    fecha: "20 Mayo 2026",
                    estado: "Retrasado",
                    colorEstado: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
