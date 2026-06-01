import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/history.dart';

class SolicitarPrestamoPage extends StatefulWidget {
  const SolicitarPrestamoPage({super.key});

  @override
  State<SolicitarPrestamoPage> createState() => _SolicitarPrestamoPageState();
}

class _SolicitarPrestamoPageState extends State<SolicitarPrestamoPage> {
  final _formKey = GlobalKey<FormState>();
  final _crud = CrudService();
  final _session = SessionService();
  final _requestedByController = TextEditingController();

  // Estados de activo que NO se pueden prestar
  static const _blockedStatuses = {'Prestado', 'Vencido', 'Mantenimiento', 'Baja'};

  List<Asset> _availableAssets = [];
  Asset? _selectedAsset;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  bool _loadingAssets = true;

  // Mensaje de bloqueo si el usuario ya tiene 2 préstamos activos
  String? _blockReason;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Cargar activos disponibles (sin estados bloqueados)
    final allAssets = await _crud.getAssets();
    final available =
        allAssets.where((a) => !_blockedStatuses.contains(a.status)).toList();

    // Verificar límite de 2 préstamos activos por usuario
    String? blockReason;
    final currentUser = _session.currentUser;
    if (currentUser != null) {
      final loans = await _crud.getLoans();
      final activeLoans = loans.where((l) =>
          l.requestedBy == currentUser.name &&
          (l.status == LoanStatus.active ||
              l.status == LoanStatus.pending ||
              l.status == LoanStatus.approved)).toList();

      if (activeLoans.length >= 2) {
        blockReason =
            'Ya tienes ${activeLoans.length} préstamos activos. El límite es 2.';
      }
    }

    setState(() {
      _availableAssets = available;
      _blockReason = blockReason;
      _loadingAssets = false;
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.indigo),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAsset == null) {
      _showSnack('Por favor selecciona un activo', Colors.red);
      return;
    }
    if (_blockReason != null) {
      _showSnack(_blockReason!, Colors.red);
      return;
    }

    // Doble verificación: el activo sigue disponible
    if (_blockedStatuses.contains(_selectedAsset!.status)) {
      _showSnack(
          'El activo "${_selectedAsset!.name}" ya no está disponible.', Colors.red);
      await _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final requester =
          _session.currentUser?.name ?? _requestedByController.text.trim();

      // 1. Crear préstamo
      final loan = Loan(
        id: uuid.v4(),
        assetId: _selectedAsset!.id,
        requestedBy: requester,
        loanDate: now,
        dueDate: _dueDate,
        status: LoanStatus.pending,
      );
      await _crud.addLoan(loan);

      // 2. Marcar activo como Prestado
      await _crud.updateAsset(_selectedAsset!.copyWith(status: 'Prestado'));

      // 3. Registrar en historial
      await _crud.addHistory(History(
        id: uuid.v4(),
        title: 'Préstamo solicitado',
        description: '$requester solicitó ${_selectedAsset!.name}',
        date: now,
        type: 'loan',
      ));

      if (mounted) {
        _showSnack('¡Préstamo solicitado exitosamente!', Colors.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _requestedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Solicitar Préstamo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loadingAssets
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ENCABEZADO
                    _headerCard(),
                    const SizedBox(height: 16),

                    // ALERTA si el usuario está bloqueado por límite
                    if (_blockReason != null) ...[
                      _alertCard(
                        icon: Icons.block,
                        color: Colors.red,
                        message: _blockReason!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // SOLICITANTE (solo visible si no hay sesión)
                    if (_session.currentUser == null) ...[
                      _buildLabel('Solicitante'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _requestedByController,
                        decoration: _inputDecoration(
                            hint: 'Nombre completo', icon: Icons.person),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      _infoRow(Icons.person, 'Solicitante',
                          _session.currentUser!.name),
                      const SizedBox(height: 20),
                    ],

                    // ACTIVO
                    _buildLabel('Activo a solicitar'),
                    const SizedBox(height: 8),
                    _availableAssets.isEmpty
                        ? _alertCard(
                            icon: Icons.warning_amber,
                            color: Colors.orange,
                            message: 'No hay activos disponibles en este momento',
                          )
                        : _assetDropdown(),

                    const SizedBox(height: 20),

                    // FECHA DE DEVOLUCIÓN
                    _buildLabel('Fecha de devolución'),
                    const SizedBox(height: 8),
                    _datePicker(),

                    const SizedBox(height: 36),

                    // BOTÓN ENVIAR
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isLoading || _blockReason != null) ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isLoading ? 'Enviando...' : 'Solicitar préstamo',
                          style: const TextStyle(fontSize: 17),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Widgets helper ──────────────────────────────────────────────────────────

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.indigo, borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.assignment_add, color: Colors.white, size: 40),
          SizedBox(height: 10),
          Text('Nueva solicitud',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          Text('Completa los datos para solicitar un activo',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _alertCard(
      {required IconData icon,
      required Color color,
      required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Widget _assetDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: DropdownButtonFormField<Asset>(
        value: _selectedAsset,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.inventory_2, color: Colors.indigo),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        hint: const Text('Selecciona un activo'),
        items: _availableAssets
            .map((a) => DropdownMenuItem(
                value: a, child: Text('${a.name} (${a.code})')))
            .toList(),
        onChanged: (val) => setState(() => _selectedAsset = val),
      ),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.indigo),
            const SizedBox(width: 12),
            Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87));
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}