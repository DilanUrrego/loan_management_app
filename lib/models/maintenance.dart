import 'sync_status.dart';

class Maintenance {
  String id;
  String assetId;
  String technician;
  DateTime date;
  String status;
  SyncStatus syncStatus;

  Maintenance({
    required this.id,
    required this.assetId,
    required this.technician,
    required this.date,
    required this.status,
    this.syncStatus = SyncStatus.pendingSync,
  });

  Maintenance copyWith({
    String? id,
    String? assetId,
    String? technician,
    DateTime? date,
    String? status,
    SyncStatus? syncStatus,
  }) {
    return Maintenance(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      technician: technician ?? this.technician,
      date: date ?? this.date,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'technician': technician,
      'date': date.toIso8601String(),
      'status': status,
      'syncStatus': syncStatus.index,
    };
  }

  factory MaintenanceModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceModel(
      id: map['id'],
      assetId: map['assetId'],
      technician: map['technician'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
    );
  }
}
