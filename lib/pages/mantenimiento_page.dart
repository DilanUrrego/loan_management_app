import 'package:flutter/material.dart';
import '../data/session_service.dart';
import '../widgets/mantenimiento_card.dart';
import '../validators/business_rules.dart';
import '../controllers/mantenimiento_controller.dart';
import '../widgets/dialogs/mantenimiento_dialogs.dart';

class MantenimientoPage extends StatefulWidget {
  const MantenimientoPage({super.key});

  @override
  State<MantenimientoPage> createState() => _MantenimientoPageState();
}

class _MantenimientoPageState extends State<MantenimientoPage> {
  final _session = SessionService();
  final _searchCtrl = TextEditingController();
  final _controller = MantenimientoController();

  @override
  void initState() {
    super.initState();
    _controller.load();
    _searchCtrl.addListener(() => _controller.search(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final elegibles = await _controller.getEligibleAssets();
    if (!mounted) return;
    
    final result = await MantenimientoDialogs.showCreateDialog(context, elegibles);
    if (result == null) return;

    await _controller.createMaintenance(
      assetId: result['assetId']!,
      technician: result['technician']!,
    );
    if (mounted) _showSnack('Mantenimiento creado', Colors.green);
  }

  Future<void> _handleFinalize(MaintView view) async {
    final confirm = await MantenimientoDialogs.confirmFinalize(context, view);
    if (!confirm) return;

    await _controller.finalizeMaintenance(view);
    if (mounted) _showSnack('Mantenimiento finalizado. Activo disponible.', Colors.green);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Color _colorForStatus(String s) {
    switch (s) {
      case 'En proceso': return Colors.orange;
      case 'Finalizado': return Colors.green;
      case 'Pendiente': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final role = _session.currentUser?.role;
    final isAdminOrManager = BusinessRules.canCreateAsset(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Mantenimiento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.load(),
            tooltip: 'Actualizar',
          ),
        ],
      ),

      // FAB solo para admin o manager
      floatingActionButton: isAdminOrManager
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              onPressed: _handleCreate,
              child: const Icon(Icons.build),
            )
          : null,

      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar mantenimiento...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // Lista ListenableBuilder
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.loading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }
                if (_controller.filtered.isEmpty) {
                  return const Center(
                    child: Text('No hay mantenimientos registrados', style: TextStyle(color: Colors.grey))
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final v = _controller.filtered[i];
                    final color = _colorForStatus(v.maintenance.status);
                    return Column(
                      children: [
                        MantenimientoCard(
                          activo: v.asset?.name ?? v.maintenance.assetId,
                          tecnico: v.maintenance.technician,
                          fecha: _formatDate(v.maintenance.date),
                          estado: v.maintenance.status,
                          colorEstado: color,
                        ),
                        // Botón finalizar solo si admin/manager y en proceso
                        if (isAdminOrManager && v.maintenance.status == 'En proceso')
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleFinalize(v),
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Finalizar mantenimiento'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}