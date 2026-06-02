import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../data/crud_service.dart';
import '../models/user.dart' as app_model;

/// Pantalla de configuración inicial: crea el primer administrador.
/// Solo está disponible si no existe ningún admin en la base de datos.
class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      // Verificar que no exista ya un admin
      final users = await CrudService().getUsers();
      final adminExists = users.any(
        (u) => u.role == app_model.UserRole.admin,
      );
      if (adminExists) {
        throw Exception('Ya existe un administrador registrado.');
      }

      // Crear en Firebase Auth
      final credential = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      // Guardar perfil con rol admin y estado activo
      await CrudService().addUser(app_model.User(
        uid: credential.user!.uid,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: app_model.UserRole.admin,
        status: app_model.AccountStatus.active,
      ));

      // Cerrar sesión de Firebase (el admin debe iniciar sesión normalmente)
      await fb_auth.FirebaseAuth.instance.signOut();

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Administrador creado'),
          content: Text(
            'La cuenta de administrador "${_nameCtrl.text.trim()}" fue creada exitosamente.\n\nYa puedes iniciar sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context); // volver al login
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() => _error = _authError(e.code));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'invalid-email':        return 'Formato de correo no válido.';
      default:                     return 'Error al crear el administrador.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Configuración inicial'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    size: 64, color: Colors.white),
                const SizedBox(height: 12),
                const Text('Crear administrador',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Este proceso solo puede realizarse una vez.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 3)
                                    ? 'Ingresa el nombre del administrador'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Correo
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Ingresa un correo válido'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Contraseña
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6)
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Nota informativa
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.indigo.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.indigo.shade400, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'La cuenta tendrá acceso completo al sistema. '
                                    'Guarda estas credenciales en un lugar seguro.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_error != null) ...[
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                          ],

                          ElevatedButton.icon(
                            onPressed: _loading ? null : _createAdmin,
                            icon: const Icon(Icons.admin_panel_settings),
                            label: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Crear administrador',
                                    style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
