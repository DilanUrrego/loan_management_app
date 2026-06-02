import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../widgets/devolucion_card.dart';
import '../controllers/devoluciones_controller.dart';
import '../widgets/dialogs/devolucion_dialogs.dart';

class DevolucionesPage extends StatefulWidget {
  const DevolucionesPage({super.key});

  @override
  State<DevolucionesPage> createState() => _DevolucionesPageState();
}

class _DevolucionesPageState extends State<DevolucionesPage> {
  final _searchCtrl = TextEditingController();
  final _controller = DevolucionesController();

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

  Future<void> _handleReturnDialog(ReturnView view) async {
    final result = await DevolucionDialogs.showReturnDialog(context, view);
    if (result == null) return;

    await _controller.processReturn(
      view: view,
      condition: result['condition'],
      notes: result['notes'],
    );

    if (mounted) {
      final needsMaintenance = result['needsMaintenance'] as bool;
      final needsBaja = result['needsBaja'] as bool;
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
    }
  }

  Color _conditionColor(String c) {
    switch (c) {
      case 'Buenas condiciones': return Colors.green;
      case 'Daño menor': return Colors.orange;
      case 'Daño mayor': return Colors.deepOrange;
      case 'Pérdida': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _loanStatusColor(LoanStatus s) => s == LoanStatus.overdue ? Colors.red : Colors.orange;
  String _loanStatusLabel(LoanStatus s) => s == LoanStatus.overdue ? 'Vencido' : 'Activo';
  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

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
            onPressed: () => _controller.load(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          return Column(
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
                    if (_controller.pendingFiltered.isNotEmpty) ...[
                      _sectionHeader('Pendientes de devolución', Icons.pending_actions, Colors.orange),
                      const SizedBox(height: 10),
                      ..._controller.pendingFiltered.map((v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                DevolucionCard(
                                  usuario: v.loan.requestedBy,
                                  activo: v.asset?.name ?? v.loan.assetId,
                                  fecha: 'Vence: ${_fmt(v.loan.dueDate)}',
                                  estado: _loanStatusLabel(v.loan.status),
                                  colorEstado: _loanStatusColor(v.loan.status),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleReturnDialog(v),
                                    icon: const Icon(Icons.assignment_return, size: 16),
                                    label: const Text('Registrar devolución'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],

                    if (_controller.pendingFiltered.isEmpty && _searchCtrl.text.isEmpty) ...[
                      _emptyCard(Icons.check_circle, Colors.green, 'No hay préstamos pendientes de devolución'),
                      const SizedBox(height: 16),
                    ],

                    // ── SECCIÓN: Historial de devoluciones ──────────────
                    if (_controller.doneFiltered.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionHeader('Historial de devoluciones', Icons.history, Colors.indigo),
                      const SizedBox(height: 10),
                      ..._controller.doneFiltered.map((v) => Padding(
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
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _emptyCard(IconData icon, Color color, String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: TextStyle(color: color))),
      ]),
    );
  }
}