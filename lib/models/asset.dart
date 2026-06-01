import 'sync_status.dart';

class Asset {
  String id;
  String name;
  String code;
  String status;
  SyncStatus syncStatus;

  Asset({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.syncStatus = SyncStatus.pendingSync,
  });

  Asset copyWith({
    String? id,
    String? name,
    String? code,
    String? status,
    SyncStatus? syncStatus,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status,
      'syncStatus': syncStatus.index,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      status: map['status'],
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
    );
  }
}
