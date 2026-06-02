import '../models/user.dart';
import '../models/loan.dart';

class BusinessRules {
  /// Retorna un mensaje de error si el usuario alcanzó el límite de préstamos activos
  static String? checkLoanLimit(List<Loan> loans, String userName) {
    final activeLoans = loans.where((l) =>
        l.requestedBy == userName &&
        (l.status == LoanStatus.active ||
         l.status == LoanStatus.pending ||
         l.status == LoanStatus.approved)).toList();

    if (activeLoans.length >= 2) {
      return 'Ya tienes ${activeLoans.length} préstamos activos. El límite es 2.';
    }
    return null;
  }

  /// Verifica si un préstamo está vencido dinámicamente según la fecha actual
  static bool isLoanOverdue(Loan loan) {
    return (loan.status == LoanStatus.active || loan.status == LoanStatus.approved) && 
           loan.dueDate.isBefore(DateTime.now());
  }

  /// Retorna el estado dinámico de un préstamo (añadiendo el caso Vencido dinámico)
  static String getDynamicLoanStatusLabel(Loan loan) {
    if (isLoanOverdue(loan)) {
      return 'Vencido';
    }
    switch (loan.status) {
      case LoanStatus.pending: return 'Pendiente';
      case LoanStatus.approved:
      case LoanStatus.active: return 'Activo';
      case LoanStatus.overdue: return 'Vencido';
      case LoanStatus.returned: return 'Devuelto';
      case LoanStatus.rejected: return 'Rechazado';
    }
  }

  static bool canCreateAsset(UserRole? role) {
    return role == UserRole.admin || role == UserRole.inventoryManager;
  }

  static bool canConfirmReturn(UserRole? role) {
    return role == UserRole.admin || role == UserRole.inventoryManager;
  }
}
