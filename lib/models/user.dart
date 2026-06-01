import 'sync_status.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final AccountStatus status;
  final SyncStatus syncStatus;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.syncStatus = SyncStatus.pendingSync,
  });

  User copyWith({
    String? iud,
    String? name,
    String? email,
    UserRole? role,
    AccountStatus? status,
    SyncStatus? syncStatus,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.index,
      'status': status.index,
      'syncStatus': syncStatus.index,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values[map['role'] ?? 0],
      status: AccountStatus.values[map['status'] ?? 0],
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
    );
  }
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