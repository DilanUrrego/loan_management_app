import 'package:flutter/material.dart';
import '../widgets/prestamo_card.dart';

class PrestamosPage extends StatelessWidget {
  const PrestamosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      appBar: AppBar(
        title: const Text("Préstamos"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // BUSCADOR
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar préstamo...",
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

                  PrestamoCard(
                    usuario: "Juan Pérez",
                    activo: "Laptop Dell",
                    fecha: "20 Mayo 2026",
                    estado: "Activo",
                    colorEstado: Colors.green,
                  ),

                  SizedBox(height: 15),

                  PrestamoCard(
                    usuario: "María Gómez",
                    activo: "Video Beam Epson",
                    fecha: "18 Mayo 2026",
                    estado: "Pendiente",
                    colorEstado: Colors.orange,
                  ),

                  SizedBox(height: 15),

                  PrestamoCard(
                    usuario: "Carlos Ruiz",
                    activo: "Tablet Samsung",
                    fecha: "15 Mayo 2026",
                    estado: "Vencido",
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