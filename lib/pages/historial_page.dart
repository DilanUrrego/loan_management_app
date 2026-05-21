import 'package:flutter/material.dart';
import '../widgets/historial_card.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        title: const Text("Historial"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // BUSCADOR
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar movimiento...",
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

                  HistorialCard(
                    titulo: "Préstamo realizado",
                    descripcion: "Juan Pérez solicitó Laptop Dell",
                    fecha: "20 Mayo 2026",
                    icono: Icons.assignment,
                    color: Colors.blue,
                  ),

                  SizedBox(height: 15),

                  HistorialCard(
                    titulo: "Activo devuelto",
                    descripcion: "Tablet Samsung fue devuelta",
                    fecha: "19 Mayo 2026",
                    icono: Icons.assignment_return,
                    color: Colors.green,
                  ),

                  SizedBox(height: 15),

                  HistorialCard(
                    titulo: "Mantenimiento iniciado",
                    descripcion: "Video Beam Epson en revisión",
                    fecha: "18 Mayo 2026",
                    icono: Icons.build,
                    color: Colors.orange,
                  ),

                  SizedBox(height: 15),

                  HistorialCard(
                    titulo: "Activo vencido",
                    descripcion: "Laptop HP tiene retraso",
                    fecha: "15 Mayo 2026",
                    icono: Icons.warning,
                    color: Colors.red,
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