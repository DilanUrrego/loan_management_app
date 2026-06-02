class AppConstants {
  static const List<String> assetStatuses = ['Disponible', 'Prestado', 'Mantenimiento', 'Vencido', 'Baja'];
  static const List<String> returnStatuses = ['Disponible', 'Mantenimiento', 'Baja'];
  static const Set<String> blockedLoanStatuses = {'Prestado', 'Vencido', 'Mantenimiento', 'Baja'};
  static const List<String> maintenanceStatuses = ['En proceso', 'Finalizado'];
  
  // En el signup solo se permite crear estos roles
  static const List<String> userRolesSignup = ['requester', 'inventoryManager'];

  // Estados de usuario para el admin
  static const List<String> userAccountStatuses = ['active', 'blocked', 'pendingApproval'];
}
