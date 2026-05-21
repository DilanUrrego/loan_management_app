class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final AccountStatus status;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
}

enum UserRole {
  requester,
  inventoryManager,
  admin
}

enum AccountStatus {
  active,
  blocked,
  pendingApproval
}