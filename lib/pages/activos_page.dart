import 'package:flutter/material.dart';
import '../widgets/asset_card.dart';

class ActivosPage extends StatelessWidget {
  const ActivosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activos"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [

          AssetCard(
            nombre: "Laptop Dell",
            codigo: "ACT-001",
            estado: "Disponible",
            colorEstado: Colors.green,
            icono: Icons.laptop,
          ),

          SizedBox(height: 15),

          AssetCard(
            nombre: "Video Beam",
            codigo: "ACT-002",
            estado: "Prestado",
            colorEstado: Colors.orange,
            icono: Icons.tv,
          ),
        ],
      ),
    );
  }
}