import 'package:flutter/material.dart';
import '../../controllers/mantenimiento_controller.dart';
import '../../models/asset.dart';
import '../../validators/form_validators.dart';

class MantenimientoDialogs {
  static Future<Map<String, String>?> showCreateDialog(BuildContext context, List<Asset> elegibles) async {
    final techCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedAssetId;

    InputDecoration dlgInput(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: const Color(0xFFF4F6F9),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.build, color: Colors.indigo),
            SizedBox(width: 10),
            Text('Nuevo Mantenimiento', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                elegibles.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No hay activos disponibles para mantenimiento',
                            style: TextStyle(color: Colors.orange)),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: dlgInput('Activo', Icons.inventory_2),
                        hint: const Text('Selecciona un activo'),
                        items: elegibles
                            .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.code})')))
                            .toList(),
                        onChanged: (v) => setDlg(() => selectedAssetId = v),
                        validator: (_) => selectedAssetId == null ? 'Selecciona un activo' : null,
                      ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: techCtrl,
                  decoration: dlgInput('Técnico responsable', Icons.person),
                  validator: FormValidators.requiredField,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx, {
                  'assetId': selectedAssetId!,
                  'technician': techCtrl.text.trim(),
                });
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  static Future<bool> confirmFinalize(BuildContext context, MaintView view) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('¿Finalizar mantenimiento?'),
            content: Text('El activo "${view.asset?.name ?? view.maintenance.assetId}" volverá a estar disponible.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
