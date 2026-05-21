import 'sync_status.dart';

class AssetReturn {
  String id;
  String loanId;
  DateTime returnDate;
  String status;
  SyncStatus syncStatus;

  AssetReturn({
    required this.id,
    required this.loanId,
    required this.returnDate,
    required this.status,
    this.syncStatus = SyncStatus.pendingSync,
  });

  AssetReturn copyWith({
    String? id,
    String? loanId,
    DateTime? returnDate,
    String? status,
    SyncStatus? syncStatus,
  }) {
    return AssetReturn(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'returnDate': returnDate.toIso8601String(),
      'status': status,
      'syncStatus': syncStatus.index,
    };
  }

  factory ReturnModel.fromMap(Map<String, dynamic> map) {
    return ReturnModel(
      id: map['id'],
      loanId: map['loanId'],
      returnDate: DateTime.parse(map['returnDate']),
      status: map['status'],
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
    );
  }
}
