// Unit tests — reglas de negocio, autorización, estados y sincronización.
// Ejecutar con: flutter test test/unit/business_rules_test.dart
//
// Los modelos se usan  con datos de prueba

import 'package:flutter_test/flutter_test.dart';
import 'package:final_exam/models/user.dart';
import 'package:final_exam/models/loan.dart';
import 'package:final_exam/models/sync_status.dart';

/// Devuelve true si el usuario puede crear una solicitud de préstamo.
bool canRequestLoan(User user) {
  if (user.status != AccountStatus.active) return false;
  // Cualquier rol activo puede hacer solicitudes
  return true;
}

bool canApproveLoan(User user) {
  if (user.status != AccountStatus.active) return false;
  return user.role == UserRole.inventoryManager || user.role == UserRole.admin;
}

bool canAccessMainModule(User user) {
  return user.status == AccountStatus.active;
}

bool rejectionIsValid(Loan loan) {
  if (loan.status != LoanStatus.rejected) return true;
  return loan.approvedBy != null && loan.approvedBy!.trim().isNotEmpty;
}

// TEST 1 — Usuario active + rol requester puede crear solicitud

void main() {
  group('Reglas de autorización — quién puede solicitar préstamos', () {
    test(
        'TEST 1: usuario activo con rol requester SÍ puede crear solicitud',
        () {
      final user = User(
        uid: 'u1',
        name: 'Ana Estudiante',
        email: 'ana@uni.edu',
        role: UserRole.requester,
        status: AccountStatus.active,
        syncStatus: SyncStatus.synced,
      );

      expect(canRequestLoan(user), isTrue,
          reason: 'Un usuario activo siempre puede solicitar préstamos');
    });

    // TEST 2 — Usuario pendingApproval NO puede crear solicitud

    test(
        'TEST 2: usuario con estado pendingApproval NO puede crear solicitud',
        () {
      final user = User(
        uid: 'u2',
        name: 'Carlos Nuevo',
        email: 'carlos@uni.edu',
        role: UserRole.requester,
        status: AccountStatus.pendingApproval,
        syncStatus: SyncStatus.synced,
      );

      expect(canRequestLoan(user), isFalse,
          reason: 'Su cuenta aún no ha sido aprobada');
    });


    // TEST 3 — Usuario blocked NO puede acceder al módulo principal

    test(
        'TEST 3: usuario bloqueado NO puede acceder al módulo principal',
        () {
      final user = User(
        uid: 'u3',
        name: 'Pedro Bloqueado',
        email: 'pedro@uni.edu',
        role: UserRole.requester,
        status: AccountStatus.blocked,
        syncStatus: SyncStatus.synced,
      );

      expect(canAccessMainModule(user), isFalse,
          reason: 'Un usuario bloqueado no debe poder entrar al sistema');
    });
  });

  
  group('Reglas de autorización — aprobación de préstamos', () {
    
    // TEST 4 — Coordinador (inventoryManager) SÍ puede aprobar préstamo

    test(
        'TEST 4: usuario con rol inventoryManager SÍ puede aprobar préstamos',
        () {
      final coordinador = User(
        uid: 'u4',
        name: 'Laura Coordinadora',
        email: 'laura@uni.edu',
        role: UserRole.inventoryManager,
        status: AccountStatus.active,
        syncStatus: SyncStatus.synced,
      );

      expect(canApproveLoan(coordinador), isTrue,
          reason: 'El coordinador de inventario puede aprobar/rechazar');
    });

    // TEST 5 — Estudiante (requester) NO puede aprobar préstamo

    test(
        'TEST 5: usuario con rol requester NO puede aprobar préstamos',
        () {
      final estudiante = User(
        uid: 'u5',
        name: 'Juan Estudiante',
        email: 'juan@uni.edu',
        role: UserRole.requester,
        status: AccountStatus.active,
        syncStatus: SyncStatus.synced,
      );

      expect(canApproveLoan(estudiante), isFalse,
          reason: 'Solo coordinadores y admins pueden aprobar');
    });
  });


  group('Reglas de negocio — cambios de estado en préstamos', () {

    // TEST 6 — Solicitud rechazada requiere responsable (motivo implícito)

    test(
        'TEST 6: préstamo rechazado SIN approvedBy se considera inválido',
        () {
      final loanSinMotivo = Loan(
        id: 'loan-1',
        assetId: 'asset-1',
        requestedBy: 'Juan',
        approvedBy: null, // ← falta quién rechazó / motivo
        loanDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: LoanStatus.rejected,
        syncStatus: SyncStatus.pendingSync,
      );

      expect(rejectionIsValid(loanSinMotivo), isFalse,
          reason: 'Un rechazo debe registrar quién lo rechazó');
    });

    test(
        'TEST 6b: préstamo rechazado CON approvedBy es válido',
        () {
      final loanConMotivo = Loan(
        id: 'loan-2',
        assetId: 'asset-1',
        requestedBy: 'Juan',
        approvedBy: 'Laura Coordinadora',
        loanDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: LoanStatus.rejected,
        syncStatus: SyncStatus.pendingSync,
      );

      expect(rejectionIsValid(loanConMotivo), isTrue);
    });
  });
}