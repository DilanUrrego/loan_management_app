import 'package:flutter/material.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/history.dart';
import '../models/user.dart' as app_model;
import '../widgets/historial_card.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final _crud = CrudService();
  final _session = SessionService();
  final _searchCtrl = TextEditingController();

  List<History> _all = [];
  List<History> _filtered = [];
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
    var histories = await _crud.getHistories();
    
    final role = _session.currentUser?.role;
    final currentUser = _session.currentUser;

    if (role == app_model.UserRole.requester && currentUser != null) {
      // Requesters solo ven el historial que los menciona (ej. préstamos)
      histories = histories.where((h) => h.description.contains(currentUser.name)).toList();
    }

    histories.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _all = histories;
      _filtered = histories;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((h) {
        return h.title.toLowerCase().contains(q) ||
            h.description.toLowerCase().contains(q) ||
            h.type.toLowerCase().contains(q);
      }).toList();
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'loan':
        return Icons.assignment;
      case 'return':
        return Icons.assignment_return;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.info;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'loan':
        return Colors.blue;
      case 'return':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Actualizar'),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar movimiento...',
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
                        child: Text('No hay movimientos registrados',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final h = _filtered[i];
                          return HistorialCard(
                            titulo: h.title,
                            descripcion: h.description,
                            fecha: _formatDate(h.date),
                            icono: _iconForType(h.type),
                            color: _colorForType(h.type),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}