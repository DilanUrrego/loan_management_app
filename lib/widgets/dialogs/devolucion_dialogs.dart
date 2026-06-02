import 'package:flutter/material.dart';
import '../../controllers/devoluciones_controller.dart';

class DevolucionDialogs {
  static Future<Map<String, dynamic>?> showReturnDialog(BuildContext context, ReturnView view) async {
    String selectedCondition = 'Buenas condiciones';
    final notesCtrl = TextEditingController();

    const conditions = ['Buenas condiciones', 'Daño menor', 'Daño mayor', 'Pérdida'];
    const needsMaintenanceSet = {'Daño menor', 'Daño mayor'};
    const needsBajaSet = {'Pérdida'};

    Color conditionColor(String c) {
      switch (c) {
        case 'Buenas condiciones': return Colors.green;
        case 'Daño menor': return Colors.orange;
        case 'Daño mayor': return Colors.deepOrange;
        case 'Pérdida': return Colors.red;
        default: return Colors.grey;
      }
    }

    IconData conditionIcon(String c) {
      switch (c) {
        case 'Buenas condiciones': return Icons.check_circle;
        case 'Daño menor': return Icons.warning_amber;
        case 'Daño mayor': return Icons.report_problem;
        case 'Pérdida': return Icons.cancel;
        default: return Icons.help;
      }
    }

    InputDecoration dlgInput(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: const Color(0xFFF4F6F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final hasNovedad = selectedCondition != 'Buenas condiciones';
          final col = conditionColor(selectedCondition);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.assignment_return, color: Colors.indigo),
              SizedBox(width: 10),
              Text('Registrar Devolución', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activo: ${view.asset?.name ?? view.loan.assetId}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Solicitante: ${view.loan.requestedBy}'),
                      Text(
                          'Vence: ${view.loan.dueDate.day}/${view.loan.dueDate.month}/${view.loan.dueDate.year}',
                          style: TextStyle(
                            color: view.loan.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.grey.shade700,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCondition,
                  decoration: dlgInput('Condición del activo', Icons.fact_check),
                  items: conditions
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(children: [
                              Icon(conditionIcon(c), color: conditionColor(c), size: 18),
                              const SizedBox(width: 8),
                              Text(c),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setDlg(() => selectedCondition = v!),
                ),
                if (hasNovedad) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: col.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber, color: col, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          needsBajaSet.contains(selectedCondition)
                              ? 'El activo será dado de baja.'
                              : 'Se generará un mantenimiento automáticamente.',
                          style: TextStyle(color: col, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: dlgInput('Observaciones (opcional)', Icons.notes),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx, {
                    'condition': selectedCondition,
                    'notes': notesCtrl.text.trim(),
                    'needsMaintenance': needsMaintenanceSet.contains(selectedCondition),
                    'needsBaja': needsBajaSet.contains(selectedCondition),
                  });
                },
                child: const Text('Confirmar devolución'),
              ),
            ],
          );
        },
      ),
    );

    return result;
  }
}
