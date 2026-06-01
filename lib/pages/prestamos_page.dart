import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/history.dart';
import '../widgets/prestamo_card.dart';
import 'solicitar_prestamo_page.dart';

class PrestamosPage extends StatefulWidget {
  const PrestamosPage({super.key});

  @override
  State<PrestamosPage> createState() => _PrestamosPageState();
}

class _PrestamosPageState extends State<PrestamosPage> {
  final _crud = CrudService();
  final _session = SessionService();
  final _searchCtrl = TextEditingController();

  List<_LoanView> _all = [];
  List<_LoanView> _filtered = [];
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
    final loans = await _crud.getLoans();
    final assets = await _crud.getAssets();
    final assetMap = {for (final a in assets) a.id: a};

    final views = loans.map((l) {
      final asset = assetMap[l.assetId];
      return _LoanView(loan: l, asset: asset);
    }).toList()
      ..sort((a, b) => b.loan.loanDate.compareTo(a.loan.loanDate));

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
        return v.loan.requestedBy.toLowerCase().contains(q) ||
            (v.asset?.name.toLowerCase().contains(q) ?? false) ||
            _statusLabel(v.loan.status).toLowerCase().contains(q);
      }).toList();
    });
  }

  // ── Aprobar préstamo (solo admin) ─────────────────────────────────────────
  Future<void> _approve(_LoanView view) async {
    final updated = view.loan.copyWith(
      status: LoanStatus.active,
      approvedBy: _session.currentUser?.name,
    );
    await _crud.updateLoan(updated);
    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo aprobado',
      description:
          '${_session.currentUser?.name} aprobó préstamo de ${view.asset?.name ?? view.loan.assetId} a ${view.loan.requestedBy}',
      date: DateTime.now(),
      type: 'loan',
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Préstamo aprobado'), backgroundColor: Colors.green),
      );
    }
    await _load();
  }

  // ── Rechazar préstamo (solo admin) ────────────────────────────────────────
  Future<void> _reject(_LoanView view) async {
    final confirm = await _confirmDialog(
      '¿Rechazar préstamo?',
      'El activo volverá a estar disponible.',
    );
    if (!confirm) return;

    final updated = view.loan.copyWith(status: LoanStatus.rejected);
    await _crud.updateLoan(updated);

    // Liberar el activo
    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: 'Disponible'));
    }

    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo rechazado',
      description:
          'Préstamo de ${view.asset?.name ?? view.loan.assetId} a ${view.loan.requestedBy} fue rechazado',
      date: DateTime.now(),
      type: 'loan',
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Préstamo rechazado'),
            backgroundColor: Colors.red),
      );
    }
    await _load();
  }

  // ── Marcar como vencido ───────────────────────────────────────────────────
  Future<void> _markOverdue(_LoanView view) async {
    final updated = view.loan.copyWith(status: LoanStatus.overdue);
    await _crud.updateLoan(updated);
    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: 'Vencido'));
    }
    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo vencido',
      description:
          'Préstamo de ${view.asset?.name ?? view.loan.assetId} a ${view.loan.requestedBy} marcado como vencido',
      date: DateTime.now(),
      type: 'loan',
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Marcado como vencido'),
            backgroundColor: Colors.orange),
      );
    }
    await _load();
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Helpers UI ────────────────────────────────────────────────────────────
  String _statusLabel(LoanStatus s) {
    switch (s) {
      case LoanStatus.pending:
        return 'Pendiente';
      case LoanStatus.approved:
      case LoanStatus.active:
        return 'Activo';
      case LoanStatus.overdue:
        return 'Vencido';
      case LoanStatus.returned:
        return 'Devuelto';
      case LoanStatus.rejected:
        return 'Rechazado';
    }
  }

  Color _statusColor(LoanStatus s) {
    switch (s) {
      case LoanStatus.pending:
        return Colors.orange;
      case LoanStatus.approved:
      case LoanStatus.active:
        return Colors.green;
      case LoanStatus.overdue:
        return Colors.red;
      case LoanStatus.returned:
        return Colors.blue;
      case LoanStatus.rejected:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isAdmin = _session.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Préstamos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Actualizar'),
        ],
      ),

      // FAB: solicitar nuevo préstamo
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () async {
          final result = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const SolicitarPrestamoPage()));
          if (result == true) _load();
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar préstamo...',
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
                        child: Text('No hay préstamos registrados',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final v = _filtered[i];
                          final statusLabel = _statusLabel(v.loan.status);
                          final statusColor = _statusColor(v.loan.status);

                          return Column(
                            children: [
                              PrestamoCard(
                                usuario: v.loan.requestedBy,
                                activo: v.asset?.name ?? v.loan.assetId,
                                fecha: _formatDate(v.loan.dueDate),
                                estado: statusLabel,
                                colorEstado: statusColor,
                              ),
                              // Botones de acción solo para admin
                              if (isAdmin &&
                                  v.loan.status == LoanStatus.pending)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _reject(v),
                                          icon: const Icon(Icons.close,
                                              size: 16),
                                          label: const Text('Rechazar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _approve(v),
                                          icon: const Icon(Icons.check,
                                              size: 16),
                                          label: const Text('Aprobar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              // Botón vencer (admin, préstamo activo y pasado de fecha)
                              if (isAdmin &&
                                  (v.loan.status == LoanStatus.active ||
                                      v.loan.status == LoanStatus.approved) &&
                                  v.loan.dueDate.isBefore(DateTime.now()))
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _markOverdue(v),
                                      icon: const Icon(Icons.warning, size: 16),
                                      label: const Text('Marcar como vencido'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                            color: Colors.red),
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

// ── Modelo de vista ────────────────────────────────────────────────────────
class _LoanView {
  final Loan loan;
  final Asset? asset;
  const _LoanView({required this.loan, this.asset});
}