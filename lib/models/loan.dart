import 'sync_status.dart';

class Loan {
  String id;
  String assetId;
  String requestedBy;
  String? approvedBy;
  DateTime loanDate;
  DateTime dueDate;
  LoanStatus status;
  SyncStatus syncStatus;

  Loan({
    required this.id,
    required this.assetId,
    required this.requestedBy,
    this.approvedBy,
    required this.loanDate,
    required this.dueDate,
    required this.status,
    this.syncStatus = SyncStatus.pendingSync,
  });

  Loan copyWith({
    String? id,
    String? assetId,
    String? requestedBy,
    String? approvedBy,
    DateTime? loanDate,
    DateTime? dueDate,
    LoanStatus? status,
    SyncStatus? syncStatus,
  }) {
    return Loan(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      requestedBy: requestedBy ?? this.requestedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'requestedBy': requestedBy,
      'approvedBy': approvedBy,
      'loanDate': loanDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.index,
      'syncStatus': syncStatus.index,
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'],
      assetId: map['assetId'],
      requestedBy: map['requestedBy'],
      approvedBy: map['approvedBy'],
      loanDate: DateTime.parse(map['loanDate']),
      dueDate: DateTime.parse(map['dueDate']),
      status: LoanStatus.values[map['status'] ?? 0],
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
    );
  }
}

enum LoanStatus {
  pending,
  approved,
  active,
  overdue,
  returned,
  rejected
}