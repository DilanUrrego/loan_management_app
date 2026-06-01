import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/maintenance.dart';
import '../models/asset.dart';
import '../models/history.dart';
import '../widgets/mantenimiento_card.dart';

class MantenimientoPage extends StatefulWidget {
  const MantenimientoPage({super.key});

  @override
  State<MantenimientoPage> createState() => _MantenimientoPageState();
}

class _MantenimientoPageState extends State<MantenimientoPage> {
  final _crud = CrudService();
  final _session = SessionService();
  final _searchCtrl = TextEditingController();

  List<_MaintView> _all = [];
  List<_MaintView> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final maintenances = await _crud.getMaintenances();
    final assets = await _crud.getAssets();
    final assetMap = {for (final a in assets) a.id: a};

    final views = maintenances.map((m) {
      return _MaintView(maintenance: m, asset: assetMap[m.assetId]);
    }).toList()
      ..sort((a, b) => b.maintenance.date.compareTo(a.maintenance.date));

    setState(() {
      _all = views;
      _filtered = views;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((v) {
        return (v.asset?.name.toLowerCase().contains(q) ?? false) ||
            v.maintenance.technician.toLowerCase().contains(q) ||
            v.maintenance.status.toLowerCase().contains(q);
      }).toList();
    });
  }

  // ── Crear mantenimiento ───────────────────────────────────────────────────
  Future<void> _showCreateDialog() async {
    final techCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedAssetId;
    final formKey2 = GlobalKey<FormState>();

    // Traer activos en mantenimiento o disponibles
    final assets = await _crud.getAssets();
    final elegibles = assets
        .where((a) => a.status == 'Mantenimiento' || a.status == 'Disponible')
        .toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.build, color: Colors.indigo),
            SizedBox(width: 10),
            Text('Nuevo Mantenimiento',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Activo
                elegibles.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                            'No hay activos disponibles para mantenimiento',
                            style: TextStyle(color: Colors.orange)),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: _dlgInput('Activo', Icons.inventory_2),
                        hint: const Text('Selecciona un activo'),
                        items: elegibles
                            .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text('${a.name} (${a.code})')))
                            .toList(),
                        onChanged: (v) =>
                            setDlg(() => selectedAssetId = v),
                        validator: (_) => selectedAssetId == null
                            ? 'Selecciona un activo'
                            : null,
                      ),
                const SizedBox(height: 14),
                // Técnico
                TextFormField(
                  controller: techCtrl,
                  decoration: _dlgInput('Técnico responsable', Icons.person),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _createMaintenance(
                  assetId: selectedAssetId!,
                  assets: assets,
                  technician: techCtrl.text.trim(),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMaintenance({
    required String assetId,
    required List<Asset> assets,
    required String technician,
  }) async {
    try {
      final asset = assets.firstWhere((a) => a.id == assetId);
      final now = DateTime.now();

      final m = Maintenance(
        id: const Uuid().v4(),
        assetId: assetId,
        technician: technician,
        date: now,
        status: 'En proceso',
      );
      await _crud.addMaintenance(m);

      // Marcar activo como en mantenimiento
      await _crud.updateAsset(asset.copyWith(status: 'Mantenimiento'));

      await _crud.addHistory(History(
        id: const Uuid().v4(),
        title: 'Mantenimiento iniciado',
        description: '${asset.name} enviado a mantenimiento con $technician',
        date: now,
        type: 'maintenance',
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mantenimiento creado'),
              backgroundColor: Colors.green),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Finalizar mantenimiento ───────────────────────────────────────────────
  Future<void> _finalize(_MaintView view) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('¿Finalizar mantenimiento?'),
            content: Text(
                'El activo "${view.asset?.name ?? view.maintenance.assetId}" volverá a estar disponible.'),
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

    if (!confirm) return;

    final updated = view.maintenance.copyWith(status: 'Finalizado');
    await _crud.updateMaintenance(updated);

    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: 'Disponible'));
    }

    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Mantenimiento finalizado',
      description:
          '${view.asset?.name ?? view.maintenance.assetId} completó mantenimiento con ${view.maintenance.technician}',
      date: DateTime.now(),
      type: 'maintenance',
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mantenimiento finalizado. Activo disponible.'),
            backgroundColor: Colors.green),
      );
      await _load();
    }
  }

  Color _colorForStatus(String s) {
    switch (s) {
      case 'En proceso':
        return Colors.orange;
      case 'Finalizado':
        return Colors.green;
      case 'Pendiente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  InputDecoration _dlgInput(String hint, IconData icon) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = _session.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Mantenimiento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Actualizar'),
        ],
      ),

      // FAB solo para admin
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              onPressed: _showCreateDialog,
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

          // Lista
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.indigo))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No hay mantenimientos registrados',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final v = _filtered[i];
                          final color = _colorForStatus(v.maintenance.status);
                          return Column(
                            children: [
                              MantenimientoCard(
                                activo: v.asset?.name ??
                                    v.maintenance.assetId,
                                tecnico: v.maintenance.technician,
                                fecha: _formatDate(v.maintenance.date),
                                estado: v.maintenance.status,
                                colorEstado: color,
                              ),
                              // Botón finalizar solo si admin y en proceso
                              if (isAdmin &&
                                  v.maintenance.status == 'En proceso')
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _finalize(v),
                                      icon: const Icon(Icons.check_circle,
                                          size: 16),
                                      label: const Text('Finalizar mantenimiento'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MaintView {
  final Maintenance maintenance;
  final Asset? asset;
  const _MaintView({required this.maintenance, this.asset});
}