// Widget tests — componentes visuales y estados de UI.
// Ejecutar con: flutter test test/widget/ui_states_test.dart
//
// NOTA: Estos tests evitan inicializar Firebase / SQLite inyectando widgets
// de forma aislada. El patrón es: renderizar el widget bajo prueba,
// interactuar con él y verificar lo que aparece en pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_exam/models/user.dart';
import 'package:final_exam/models/asset.dart';
import 'package:final_exam/models/sync_status.dart';

// Simula la pantalla de acceso bloqueado que se muestra cuando
// el usuario tiene AccountStatus.blocked.
class BlockedUserScreen extends StatelessWidget {
  const BlockedUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Acceso bloqueado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tu cuenta ha sido suspendida. Contacta al administrador.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Simula la pantalla de espera para usuarios pendingApproval.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Cuenta pendiente de aprobación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Un administrador debe aprobar tu cuenta antes de continuar.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard que muestra u oculta opciones según el rol del usuario.
class DashboardScreen extends StatelessWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        user.role == UserRole.admin || user.role == UserRole.inventoryManager;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        children: [
          const Text('Bienvenido'),
          // Opción exclusiva para admin / coordinador
          if (isAdmin)
            ListTile(
              key: const Key('admin_option'),
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gestión de usuarios'),
            ),
        ],
      ),
    );
  }
}

// Lista de activos con estado vacío.
class AssetListScreen extends StatelessWidget {
  final List<Asset> assets;
  const AssetListScreen({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activos')),
      body: assets.isEmpty
          ? const Center(
              child: Text(
                'No hay activos registrados',
                key: Key('empty_state_label'),
              ),
            )
          : ListView.builder(
              itemCount: assets.length,
              itemBuilder: (_, i) => ListTile(title: Text(assets[i].name)),
            ),
    );
  }
}

// Widget que muestra un badge "Pendiente de sync" cuando syncStatus es pendingSync.
class SyncBadge extends StatelessWidget {
  final SyncStatus syncStatus;
  const SyncBadge({super.key, required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    if (syncStatus == SyncStatus.pendingSync) {
      return Container(
        key: const Key('pending_sync_badge'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'Pendiente de sync',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// TESTS

void main() {
  // Helper para envolver widgets en MaterialApp
  Widget wrap(Widget child) => MaterialApp(home: child);


  // WIDGET TEST 1 — Si no hay activos, se muestra estado vacío

  testWidgets(
      'WIDGET TEST 1: lista vacía de activos muestra mensaje de estado vacío',
      (tester) async {
    await tester.pumpWidget(
      wrap(const AssetListScreen(assets: [])),
    );

    expect(find.byKey(const Key('empty_state_label')), findsOneWidget);
    expect(find.text('No hay activos registrados'), findsOneWidget);
  });

  // WIDGET TEST 2 — Si el usuario está blocked, se muestra pantalla de acceso bloqueado

  testWidgets(
      'WIDGET TEST 2: usuario bloqueado ve pantalla de acceso bloqueado',
      (tester) async {

    final user = User(
      uid: 'u-blocked',
      name: 'Pedro Bloqueado',
      email: 'pedro@uni.edu',
      role: UserRole.requester,
      status: AccountStatus.blocked,
      syncStatus: SyncStatus.synced,
    );


    final screen = user.status == AccountStatus.blocked
        ? const BlockedUserScreen()
        : const Scaffold(body: Text('Dashboard'));

    await tester.pumpWidget(wrap(screen));

    expect(find.text('Acceso bloqueado'), findsOneWidget);
    expect(
      find.text('Tu cuenta ha sido suspendida. Contacta al administrador.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });


  // WIDGET TEST 3 — Si el usuario está pendingApproval, se muestra pantalla de espera

  testWidgets(
      'WIDGET TEST 3: usuario pendingApproval ve pantalla de espera',
      (tester) async {
    final user = User(
      uid: 'u-pending',
      name: 'María Nueva',
      email: 'maria@uni.edu',
      role: UserRole.requester,
      status: AccountStatus.pendingApproval,
      syncStatus: SyncStatus.synced,
    );

    final screen = user.status == AccountStatus.pendingApproval
        ? const PendingApprovalScreen()
        : const Scaffold(body: Text('Dashboard'));

    await tester.pumpWidget(wrap(screen));

    expect(find.text('Cuenta pendiente de aprobación'), findsOneWidget);
    expect(
      find.text(
          'Un administrador debe aprobar tu cuenta antes de continuar.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
  });


  // WIDGET TEST 4 — Si el usuario es administrador, aparece opción de gestión

  testWidgets(
      'WIDGET TEST 4: usuario admin ve opción de gestión de usuarios en el dashboard',
      (tester) async {
    final adminUser = User(
      uid: 'u-admin',
      name: 'Laura Admin',
      email: 'laura@uni.edu',
      role: UserRole.admin,
      status: AccountStatus.active,
      syncStatus: SyncStatus.synced,
    );

    await tester.pumpWidget(wrap(DashboardScreen(user: adminUser)));

    expect(find.byKey(const Key('admin_option')), findsOneWidget);
    expect(find.text('Gestión de usuarios'), findsOneWidget);
  });


  // WIDGET TEST 5 — Si el usuario NO es administrador, NO aparece opción de gestión

  testWidgets(
      'WIDGET TEST 5: usuario requester NO ve opción de gestión de usuarios',
      (tester) async {
    final requesterUser = User(
      uid: 'u-req',
      name: 'Carlos Estudiante',
      email: 'carlos@uni.edu',
      role: UserRole.requester,
      status: AccountStatus.active,
      syncStatus: SyncStatus.synced,
    );

    await tester.pumpWidget(wrap(DashboardScreen(user: requesterUser)));

    expect(find.byKey(const Key('admin_option')), findsNothing);
    expect(find.text('Gestión de usuarios'), findsNothing);
  });
}