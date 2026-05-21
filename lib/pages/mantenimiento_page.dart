import 'package:flutter/material.dart';
import '../widgets/mantenimiento_card.dart';

class MantenimientoPage extends StatelessWidget {
  const MantenimientoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        title: const Text("Mantenimiento"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () {},
        child: const Icon(Icons.build),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // BUSCADOR
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar mantenimiento...",
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

                  MantenimientoCard(
                    activo: "Laptop Dell",
                    tecnico: "Carlos Gómez",
                    fecha: "20 Mayo 2026",
                    estado: "En proceso",
                    colorEstado: Colors.orange,
                  ),

                  SizedBox(height: 15),

                  MantenimientoCard(
                    activo: "Impresora HP",
                    tecnico: "Laura Ruiz",
                    fecha: "18 Mayo 2026",
                    estado: "Finalizado",
                    colorEstado: Colors.green,
                  ),

                  SizedBox(height: 15),

                  MantenimientoCard(
                    activo: "Video Beam Epson",
                    tecnico: "Andrés Pérez",
                    fecha: "15 Mayo 2026",
                    estado: "Pendiente",
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