import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../validators/form_validators.dart';
import '../controllers/solicitar_prestamo_controller.dart';

class SolicitarPrestamoPage extends StatefulWidget {
  const SolicitarPrestamoPage({super.key});

  @override
  State<SolicitarPrestamoPage> createState() => _SolicitarPrestamoPageState();
}

class _SolicitarPrestamoPageState extends State<SolicitarPrestamoPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestedByController = TextEditingController();
  final _controller = SolicitarPrestamoController();

  Asset? _selectedAsset;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _controller.loadData();
  }

  @override
  void dispose() {
    _requestedByController.dispose();
    _controller.dispose();
    super.dispose();
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
    
    final result = await _controller.submit(
      selectedAsset: _selectedAsset,
      dueDate: _dueDate,
      requestedByManual: _requestedByController.text.trim(),
    );

    if (mounted) {
      _showSnack(result['message'], result['color']);
      if (result['success'] == true) {
        Navigator.pop(context, true);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.loadingAssets) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),

                  if (_controller.blockReason != null) ...[
                    _alertCard(
                      icon: Icons.block,
                      color: Colors.red,
                      message: _controller.blockReason!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!_controller.hasSession) ...[
                    _buildLabel('Solicitante'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _requestedByController,
                      decoration: _inputDecoration(hint: 'Nombre completo', icon: Icons.person),
                      validator: FormValidators.requiredField,
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    _infoRow(Icons.person, 'Solicitante', _controller.currentUserName),
                    const SizedBox(height: 20),
                  ],

                  _buildLabel('Activo a solicitar'),
                  const SizedBox(height: 8),
                  _controller.availableAssets.isEmpty
                      ? _alertCard(
                          icon: Icons.warning_amber,
                          color: Colors.orange,
                          message: 'No hay activos disponibles en este momento',
                        )
                      : _assetDropdown(),

                  const SizedBox(height: 20),

                  _buildLabel('Fecha de devolución'),
                  const SizedBox(height: 8),
                  _datePicker(),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: (_controller.isLoading || _controller.blockReason != null) ? null : _submit,
                      icon: _controller.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _controller.isLoading ? 'Enviando...' : 'Solicitar préstamo',
                        style: const TextStyle(fontSize: 17),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.assignment_add, color: Colors.white, size: 40),
          SizedBox(height: 10),
          Text('Nueva solicitud', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text('Completa los datos para solicitar un activo', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _alertCard({required IconData icon, required Color color, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonFormField<Asset>(
        value: _selectedAsset,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.inventory_2, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        hint: const Text('Selecciona un activo'),
        items: _controller.availableAssets
            .map((a) => DropdownMenuItem(value: a, child: Text('${a.name} (${a.code})')))
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.indigo),
            const SizedBox(width: 12),
            Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}', style: const TextStyle(fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87));
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}