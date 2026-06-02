import 'package:flutter/material.dart';
import '../data/session_service.dart';
import '../data/auth_service.dart';
import '../models/loan.dart';
import '../models/user.dart' as app_model;
import '../widgets/prestamo_card.dart';
import 'solicitar_prestamo_page.dart';
import '../validators/business_rules.dart';
import '../controllers/prestamos_controller.dart';
import '../widgets/dialogs/prestamo_dialogs.dart';
import 'login_page.dart';

class PrestamosPage extends StatefulWidget {
  final String? initialFilter;
  const PrestamosPage({super.key, this.initialFilter});

  @override
  State<PrestamosPage> createState() => _PrestamosPageState();
}

class _PrestamosPageState extends State<PrestamosPage> {
  final _session = SessionService();
  final _searchCtrl = TextEditingController();
  final _controller = PrestamosController();

  @override
  void initState() {
    super.initState();
    _controller.load(initialFilter: widget.initialFilter);
    if (widget.initialFilter != null) {
      _searchCtrl.text = widget.initialFilter!;
    }
    _searchCtrl.addListener(() => _controller.search(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(LoanView view) async {
    await _controller.approve(view);
    if (mounted) _showSnack('Préstamo aprobado', Colors.green);
  }

  Future<void> _handleReject(LoanView view) async {
    final confirm = await PrestamoDialogs.confirmReject(context);
    if (!confirm) return;
    await _controller.reject(view);
    if (mounted) _showSnack('Préstamo rechazado', Colors.red);
  }

  Future<void> _handleMarkOverdue(LoanView view) async {
    await _controller.markOverdue(view);
    if (mounted) _showSnack('Marcado como vencido', Colors.orange);
  }

  Future<void> _handleReturn(LoanView view) async {
    final status = await PrestamoDialogs.returnLoanDialog(context, view);
    if (status == null) return;
    
    await _controller.returnLoan(view, status);
    if (mounted) {
      _showSnack(
        status == 'Mantenimiento' 
          ? 'Préstamo devuelto y enviado a mantenimiento' 
          : 'Préstamo devuelto con éxito',
        Colors.blue
      );
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _statusLabel(Loan loan) => BusinessRules.getDynamicLoanStatusLabel(loan);

  Color _statusColor(Loan loan) {
    if (BusinessRules.isLoanOverdue(loan)) return Colors.red;
    switch (loan.status) {
      case LoanStatus.pending: return Colors.orange;
      case LoanStatus.approved:
      case LoanStatus.active: return Colors.green;
      case LoanStatus.overdue: return Colors.red;
      case LoanStatus.returned: return Colors.blue;
      case LoanStatus.rejected: return Colors.grey;
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final role = _session.currentUser?.role;
    final isAdminOrManager = BusinessRules.canConfirmReturn(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Préstamos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.load(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const SolicitarPrestamoPage()),
          );
          if (result == true) _controller.load();
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
                    child: Text('No hay préstamos registrados', style: TextStyle(color: Colors.grey))
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final v = _controller.filtered[i];
                    final statusLabel = _statusLabel(v.loan);
                    final statusColor = _statusColor(v.loan);

                    return Column(
                      children: [
                        PrestamoCard(
                          usuario: v.loan.requestedBy,
                          activo: v.asset?.name ?? v.loan.assetId,
                          fecha: _formatDate(v.loan.dueDate),
                          estado: statusLabel,
                          colorEstado: statusColor,
                        ),
                        // Botones de acción solo para admin o manager
                        if (isAdminOrManager && v.loan.status == LoanStatus.pending)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const SizedBox(width: 4),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleReject(v),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Rechazar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleApprove(v),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Aprobar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        // Botón vencer (admin/manager, préstamo activo y pasado de fecha)
                        if (isAdminOrManager &&
                            (v.loan.status == LoanStatus.active || v.loan.status == LoanStatus.approved) &&
                            v.loan.dueDate.isBefore(DateTime.now()))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _handleMarkOverdue(v),
                                icon: const Icon(Icons.warning, size: 16),
                                label: const Text('Marcar como vencido en sistema'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        // Botón Devolver (Solo para admin/manager)
                        if (isAdminOrManager &&
                            (v.loan.status == LoanStatus.active ||
                             v.loan.status == LoanStatus.approved ||
                             v.loan.status == LoanStatus.overdue))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleReturn(v),
                                icon: const Icon(Icons.assignment_return, size: 16),
                                label: const Text('Devolver préstamo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
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