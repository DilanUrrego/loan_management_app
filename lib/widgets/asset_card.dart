import 'package:flutter/material.dart';

class AssetCard extends StatelessWidget {

  final String nombre;
  final String codigo;
  final String estado;
  final Color colorEstado;
  final IconData icono;

  const AssetCard({
    super.key,
    required this.nombre,
    required this.codigo,
    required this.estado,
    required this.colorEstado,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [

          Icon(
            icono,
            size: 40,
            color: colorEstado,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(codigo),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    estado,
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}