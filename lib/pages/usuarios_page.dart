import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../data/crud_service.dart';
import 'login_page.dart';
import '../models/user.dart' as app_model;

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _crud = CrudService();
  final _searchCtrl = TextEditingController();

  List<app_model.User> _all = [];
  List<app_model.User> _filtered = [];
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
    final users = await _crud.getUsers();
    // Ordenar: pendientes primero, luego activos, luego bloqueados
    users.sort((a, b) {
      if (a.status == b.status) return a.name.compareTo(b.name);
      if (a.status == app_model.AccountStatus.pendingApproval) return -1;
      if (b.status == app_model.AccountStatus.pendingApproval) return 1;
      if (a.status == app_model.AccountStatus.active) return -1;
      return 1;
    });

    setState(() {
      _all = users;
      _filtered = users;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            _roleLabel(u.role).toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _updateStatus(app_model.User user, app_model.AccountStatus newStatus) async {
    final updated = user.copyWith(status: newStatus);
    await _crud.updateUser(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado de ${user.name} actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    }
  }

  Future<void> _confirmAction(String title, String content, VoidCallback onConfirm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) onConfirm();
  }

  String _roleLabel(app_model.UserRole role) {
    switch (role) {
      case app_model.UserRole.admin: return 'Administrador';
      case app_model.UserRole.inventoryManager: return 'Gestor';
      case app_model.UserRole.requester: return 'Solicitante';
    }
  }

  String _statusLabel(app_model.AccountStatus status) {
    switch (status) {
      case app_model.AccountStatus.active: return 'Activo';
      case app_model.AccountStatus.blocked: return 'Bloqueado';
      case app_model.AccountStatus.pendingApproval: return 'Pendiente';
    }
  }

  Color _statusColor(app_model.AccountStatus status) {
    switch (status) {
      case app_model.AccountStatus.active: return Colors.green;
      case app_model.AccountStatus.blocked: return Colors.red;
      case app_model.AccountStatus.pendingApproval: return Colors.orange;
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
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
              hintText: 'Buscar usuario...',
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

        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('No se encontraron usuarios',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        final statusLabel = _statusLabel(u.status);
                        final statusColor = _statusColor(u.status);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.indigo.shade50,
                                      child: Icon(Icons.person, color: Colors.indigo.shade400),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            u.email,
                                            style: const TextStyle(
                                                color: Colors.grey, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                _roleLabel(u.role),
                                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Acciones
                                if (u.role != app_model.UserRole.admin) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (u.status == app_model.AccountStatus.pendingApproval) ...[
                                        OutlinedButton(
                                          onPressed: () => _confirmAction(
                                            'Rechazar usuario',
                                            '¿Estás seguro de rechazar y bloquear a este usuario?',
                                            () => _updateStatus(u, app_model.AccountStatus.blocked),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                          ),
                                          child: const Text('Rechazar'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _updateStatus(u, app_model.AccountStatus.active),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Aprobar'),
                                        ),
                                      ] else if (u.status == app_model.AccountStatus.active) ...[
                                        OutlinedButton.icon(
                                          onPressed: () => _confirmAction(
                                            'Bloquear usuario',
                                            'El usuario no podrá iniciar sesión en el sistema.',
                                            () => _updateStatus(u, app_model.AccountStatus.blocked),
                                          ),
                                          icon: const Icon(Icons.block, size: 16),
                                          label: const Text('Bloquear'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                          ),
                                        ),
                                      ] else if (u.status == app_model.AccountStatus.blocked) ...[
                                        OutlinedButton.icon(
                                          onPressed: () => _confirmAction(
                                            'Desbloquear usuario',
                                            'El usuario recuperará el acceso al sistema.',
                                            () => _updateStatus(u, app_model.AccountStatus.active),
                                          ),
                                          icon: const Icon(Icons.check_circle, size: 16),
                                          label: const Text('Desbloquear'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            side: const BorderSide(color: Colors.green),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
      ),
    );
  }
}
