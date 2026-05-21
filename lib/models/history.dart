import 'sync_status.dart';

class History {
  String id;
  String title;
  String description;
  DateTime date;
  String type;
  SyncStatus syncStatus;

  History({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.syncStatus = SyncStatus.pendingSync,
  });

  History copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? type,
    SyncStatus? syncStatus,
  }) {
    return History(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'syncStatus': syncStatus.index,
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
    );
  }
}
