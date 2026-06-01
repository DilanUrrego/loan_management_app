import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/asset_return.dart';
import '../models/maintenance.dart';
import '../models/history.dart';
import '../widgets/devolucion_card.dart';

class DevolucionesPage extends StatefulWidget {
  const DevolucionesPage({super.key});

  @override
  State<DevolucionesPage> createState() => _DevolucionesPageState();
}

class _DevolucionesPageState extends State<DevolucionesPage> {
  final _crud = CrudService();
  final _session = SessionService();
  final _searchCtrl = TextEditingController();

  // Préstamos activos/vencidos que aún no han sido devueltos
  List<_ReturnView> _pending = [];
  List<_ReturnView> _pendingFiltered = [];

  // Devoluciones ya registradas
  List<_DoneView> _done = [];
  List<_DoneView> _doneFiltered = [];

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
    final returns = await _crud.getReturns();

    final assetMap = {for (final a in assets) a.id: a};
    final returnedLoanIds = returns.map((r) => r.loanId).toSet();

    // Préstamos pendientes de devolución (activos o vencidos, sin devolución)
    final pendingLoans = loans.where((l) =>
        (l.status == LoanStatus.active ||
            l.status == LoanStatus.approved ||
            l.status == LoanStatus.overdue) &&
        !returnedLoanIds.contains(l.id)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Devoluciones ya registradas, unidas con su loan y asset
    final loanMap = {for (final l in loans) l.id: l};
    final doneViews = returns.map((r) {
      final loan = loanMap[r.loanId];
      final asset = loan != null ? assetMap[loan.assetId] : null;
      return _DoneView(ret: r, loan: loan, asset: asset);
    }).toList()
      ..sort((a, b) => b.ret.returnDate.compareTo(a.ret.returnDate));

    setState(() {
      _pending = pendingLoans
          .map((l) => _ReturnView(loan: l, asset: assetMap[l.assetId]))
          .toList();
      _pendingFiltered = _pending;
      _done = doneViews;
      _doneFiltered = doneViews;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _pendingFiltered = _pending.where((v) {
        return v.loan.requestedBy.toLowerCase().contains(q) ||
            (v.asset?.name.toLowerCase().contains(q) ?? false);
      }).toList();
      _doneFiltered = _done.where((v) {
        return (v.loan?.requestedBy.toLowerCase().contains(q) ?? false) ||
            (v.asset?.name.toLowerCase().contains(q) ?? false) ||
            v.ret.status.toLowerCase().contains(q);
      }).toList();
    });
  }

  // ── Registrar devolución ──────────────────────────────────────────────────
  Future<void> _showReturnDialog(_ReturnView view) async {
    String selectedCondition = 'Buenas condiciones';
    final notesCtrl = TextEditingController();

    const conditions = [
      'Buenas condiciones',
      'Daño menor',
      'Daño mayor',
      'Pérdida',
    ];

    // Condiciones que generan mantenimiento
    const needsMaintenance = {'Daño menor', 'Daño mayor'};
    // Condiciones que dan de baja el activo
    const needsBaja = {'Pérdida'};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final hasNovedad = selectedCondition != 'Buenas condiciones';
          final conditionColor = _conditionColor(selectedCondition);

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.assignment_return, color: Colors.indigo),
              SizedBox(width: 10),
              Text('Registrar Devolución',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Info del préstamo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activo: ${view.asset?.name ?? view.loan.assetId}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Solicitante: ${view.loan.requestedBy}'),
                      Text(
                          'Vence: ${_fmt(view.loan.dueDate)}',
                          style: TextStyle(
                            color: view.loan.dueDate.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.grey.shade700,
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Condición del activo
                DropdownButtonFormField<String>(
                  value: selectedCondition,
                  decoration: _dlgInput(
                      'Condición del activo', Icons.fact_check),
                  items: conditions
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Row(children: [
                              Icon(_conditionIcon(c),
                                  color: _conditionColor(c), size: 18),
                              const SizedBox(width: 8),
                              Text(c),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setDlg(() => selectedCondition = v!),
                ),

                // Banner de advertencia si hay novedad
                if (hasNovedad) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: conditionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: conditionColor.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber, color: conditionColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          needsBaja.contains(selectedCondition)
                              ? 'El activo será dado de baja.'
                              : 'Se generará un mantenimiento automáticamente.',
                          style: TextStyle(
                              color: conditionColor, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 14),

                // Notas opcionales
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: _dlgInput('Observaciones (opcional)', Icons.notes),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _processReturn(
                    view: view,
                    condition: selectedCondition,
                    notes: notesCtrl.text.trim(),
                    needsMaintenance: needsMaintenance.contains(selectedCondition),
                    needsBaja: needsBaja.contains(selectedCondition),
                  );
                },
                child: const Text('Confirmar devolución'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processReturn({
    required _ReturnView view,
    required String condition,
    required String notes,
    required bool needsMaintenance,
    required bool needsBaja,
  }) async {
    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final assetName = view.asset?.name ?? view.loan.assetId;

      // 1. Registrar la devolución
      final ret = AssetReturn(
        id: uuid.v4(),
        loanId: view.loan.id,
        returnDate: now,
        status: condition,
      );
      await _crud.addReturn(ret);

      // 2. Actualizar estado del préstamo a devuelto
      await _crud.updateLoan(view.loan.copyWith(status: LoanStatus.returned));

      // 3. Actualizar el activo según la condición
      if (view.asset != null) {
        String newAssetStatus;
        if (needsBaja) {
          newAssetStatus = 'Baja';
        } else if (needsMaintenance) {
          newAssetStatus = 'Mantenimiento';
        } else {
          newAssetStatus = 'Disponible';
        }
        await _crud.updateAsset(view.asset!.copyWith(status: newAssetStatus));
      }

      // 4. Si hay novedad → crear mantenimiento automático
      if (needsMaintenance && view.asset != null) {
        final maintenance = Maintenance(
          id: uuid.v4(),
          assetId: view.asset!.id,
          technician: 'Por asignar',
          date: now,
          status: 'Pendiente',
        );
        await _crud.addMaintenance(maintenance);

        await _crud.addHistory(History(
          id: uuid.v4(),
          title: 'Mantenimiento generado por devolución',
          description:
              '$assetName requiere mantenimiento tras devolución con novedad: $condition',
          date: now,
          type: 'maintenance',
        ));
      }

      // 5. Si es pérdida → registrar baja en historial
      if (needsBaja) {
        await _crud.addHistory(History(
          id: uuid.v4(),
          title: 'Activo dado de baja',
          description:
              '$assetName fue dado de baja por: $condition',
          date: now,
          type: 'return',
        ));
      }

      // 6. Historial de devolución
      final desc = notes.isEmpty
          ? '${view.loan.requestedBy} devolvió $assetName — $condition'
          : '${view.loan.requestedBy} devolvió $assetName — $condition. Obs: $notes';
      await _crud.addHistory(History(
        id: uuid.v4(),
        title: 'Activo devuelto',
        description: desc,
        date: now,
        type: 'return',
      ));

      if (mounted) {
        final extra = needsMaintenance
            ? '\nSe creó un mantenimiento automáticamente.'
            : needsBaja
                ? '\nEl activo fue dado de baja.'
                : '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Devolución registrada.$extra'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al registrar devolución: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _conditionColor(String c) {
    switch (c) {
      case 'Buenas condiciones':
        return Colors.green;
      case 'Daño menor':
        return Colors.orange;
      case 'Daño mayor':
        return Colors.deepOrange;
      case 'Pérdida':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _conditionIcon(String c) {
    switch (c) {
      case 'Buenas condiciones':
        return Icons.check_circle;
      case 'Daño menor':
        return Icons.warning_amber;
      case 'Daño mayor':
        return Icons.report_problem;
      case 'Pérdida':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _loanStatusColor(LoanStatus s) =>
      s == LoanStatus.overdue ? Colors.red : Colors.orange;

  String _loanStatusLabel(LoanStatus s) =>
      s == LoanStatus.overdue ? 'Vencido' : 'Activo';

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Devoluciones'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Actualizar'),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.indigo))
          : Column(
              children: [
                // Buscador
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar devolución...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [

                      // ── SECCIÓN: Pendientes de devolución ───────────────
                      if (_pendingFiltered.isNotEmpty) ...[
                        _sectionHeader(
                          'Pendientes de devolución',
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        const SizedBox(height: 10),
                        ..._pendingFiltered.map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  DevolucionCard(
                                    usuario: v.loan.requestedBy,
                                    activo: v.asset?.name ?? v.loan.assetId,
                                    fecha:
                                        'Vence: ${_fmt(v.loan.dueDate)}',
                                    estado: _loanStatusLabel(v.loan.status),
                                    colorEstado:
                                        _loanStatusColor(v.loan.status),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showReturnDialog(v),
                                      icon: const Icon(
                                          Icons.assignment_return,
                                          size: 16),
                                      label: const Text('Registrar devolución'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],

                      if (_pendingFiltered.isEmpty &&
                          _searchCtrl.text.isEmpty) ...[
                        _emptyCard(
                            Icons.check_circle,
                            Colors.green,
                            'No hay préstamos pendientes de devolución'),
                        const SizedBox(height: 16),
                      ],

                      // ── SECCIÓN: Historial de devoluciones ──────────────
                      if (_doneFiltered.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _sectionHeader(
                          'Historial de devoluciones',
                          Icons.history,
                          Colors.indigo,
                        ),
                        const SizedBox(height: 10),
                        ..._doneFiltered.map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DevolucionCard(
                                usuario: v.loan?.requestedBy ?? '—',
                                activo: v.asset?.name ?? '—',
                                fecha: _fmt(v.ret.returnDate),
                                estado: v.ret.status,
                                colorEstado: _conditionColor(v.ret.status),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color)),
    ]);
  }

  Widget _emptyCard(IconData icon, Color color, String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: TextStyle(color: color))),
      ]),
    );
  }
}

// ── Modelos de vista ───────────────────────────────────────────────────────
class _ReturnView {
  final Loan loan;
  final Asset? asset;
  const _ReturnView({required this.loan, this.asset});
}

class _DoneView {
  final AssetReturn ret;
  final Loan? loan;
  final Asset? asset;
  const _DoneView({required this.ret, this.loan, this.asset});
}