import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/asset.dart';
import '../widgets/asset_card.dart';

class ActivosPage extends StatefulWidget {
  const ActivosPage({super.key});

  @override
  State<ActivosPage> createState() => _ActivosPageState();
}

class _ActivosPageState extends State<ActivosPage> {
  final _crud = CrudService();
  final _session = SessionService();

  List<Asset> _assets = [];
  List<Asset> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _searchController.addListener(_onSearch);
  }

  Future<void> _loadAssets() async {
    setState(() => _loading = true);
    final assets = await _crud.getAssets();
    setState(() {
      _assets = assets;
      _filtered = assets;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _assets
        .where((a) =>
          a.name.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q) ||
          a.status.toLowerCase().contains(q))
        .toList();
    });
  }

  // ── Colores por estado ────────────────────────────────────────────────────
  Color _colorForStatus(String status) {
    switch (status) {
      case 'Disponible':
        return Colors.green;
      case 'Prestado':
        return Colors.orange;
      case 'Mantenimiento':
        return Colors.blue;
      case 'Vencido':
        return Colors.red;
      case 'Baja':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }
 
  IconData _iconForStatus(String status) {
    switch (status) {
      case 'Disponible':
        return Icons.check_circle;
      case 'Prestado':
        return Icons.assignment_returned;
      case 'Mantenimiento':
        return Icons.build;
      case 'Vencido':
        return Icons.warning;
      case 'Baja':
        return Icons.cancel;
      default:
        return Icons.devices;
    }
  }
 
  // ── Diálogo para crear activo ─────────────────────────────────────────────
  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String selectedStatus = 'Disponible';
    final formKey = GlobalKey<FormState>();
 
    const statuses = ['Disponible', 'Mantenimiento', 'Baja'];
 
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_box, color: Colors.indigo),
              SizedBox(width: 10),
              Text('Nuevo Activo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _dialogInput('Nombre del activo', Icons.label),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  // Código
                  TextFormField(
                    controller: codeCtrl,
                    decoration:
                        _dialogInput('Código (ej. ACT-010)', Icons.qr_code),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  // Estado
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration:
                        _dialogInput('Estado inicial', Icons.toggle_on),
                    items: statuses
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedStatus = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _createAsset(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  status: selectedStatus,
                );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
 
  Future<void> _createAsset({
    required String name,
    required String code,
    required String status,
  }) async {
    try {
      final asset = Asset(
        id: const Uuid().v4(),
        name: name,
        code: code,
        status: status,
      );
      await _crud.addAsset(asset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activo "$name" creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAssets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear activo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
 
  InputDecoration _dialogInput(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: const Color(0xFFF4F6F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    //final isAdmin = _session.isAdmin;
    final isAdmin = true;
 
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Activos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssets,
            tooltip: 'Actualizar',
          ),
        ],
      ),
 
      body: Column(
        children: [
          // ── Buscador ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar activo...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
 
          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.indigo))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No se encontraron activos',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            16, 16, 16, isAdmin ? 90 : 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final a = _filtered[i];
                          return AssetCard(
                            nombre: a.name,
                            codigo: a.code,
                            estado: a.status,
                            colorEstado: _colorForStatus(a.status),
                            icono: _iconForStatus(a.status),
                          );
                        },
                      ),
          ),
        ],
      ),
 
      // ── Botón crear activo (solo admin, abajo a la izquierda) ─────────────
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Agregar activo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}