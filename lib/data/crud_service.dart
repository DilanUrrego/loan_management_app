import 'local_db_helper.dart';
import 'firestore_service.dart';
import '../models/asset.dart';
import '../models/loan.dart';
import '../models/asset_return.dart';
import '../models/maintenance.dart';
import '../models/history.dart';
import '../models/user.dart';
import '../models/sync_status.dart';

class CrudService {
  static final CrudService _instance = CrudService._internal();
  factory CrudService() => _instance;
  CrudService._internal();

  final LocalDbHelper _localDb = LocalDbHelper();
  final FirestoreService _firestore = FirestoreService();

  // Helper method for sync
  Future<void> _syncToFirestore(String table, String id, Map<String, dynamic> data) async {
    try {
      await _firestore.insert(table, id, data);
      // Update local db to synced
      data['syncStatus'] = SyncStatus.synced.index;
      await _localDb.update(table, table == 'users' ? 'uid' : 'id', id, data);
    } catch (e) {
      // It stays as pendingSync if offline
      print("Error syncing $table to Firestore: $e");
    }
  }

  // --- USER CRUD ---
  Future<void> addUser(User user) async {
    final data = user.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.insert('users', data);
    _syncToFirestore('users', user.uid, data);
  }

  Future<List<User>> getUsers() async {
    final data = await _localDb.getAll('users');
    return data.map((map) => User.fromMap(map)).toList();
  }

  Future<void> updateUser(User user) async {
    final data = user.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.update('users', 'uid', user.uid, data);
    _syncToFirestore('users', user.uid, data);
  }

  Future<void> deleteUser(String uid) async {
    await _localDb.delete('users', 'uid', uid);
    try {
      await _firestore.delete('users', uid);
    } catch (e) {
      print("Error deleting user from Firestore: $e");
    }
  }

  // --- ASSETS CRUD ---
  Future<void> addAsset(Asset asset) async {
    final data = asset.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.insert('assets', data);
    _syncToFirestore('assets', asset.id, data);
  }

  Future<List<Asset>> getAssets() async {
    final data = await _localDb.getAll('assets');
    return data.map((map) => Asset.fromMap(map)).toList();
  }

  Future<void> updateAsset(Asset asset) async {
    final data = asset.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.update('assets', 'id', asset.id, data);
    _syncToFirestore('assets', asset.id, data);
  }

  Future<void> deleteAsset(String id) async {
    await _localDb.delete('assets', 'id', id);
    try {
      await _firestore.delete('assets', id);
    } catch (e) {
      print("Error deleting asset from Firestore: $e");
    }
  }

  // --- LOANS CRUD ---
  Future<void> addLoan(Loan loan) async {
    final data = loan.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.insert('loans', data);
    _syncToFirestore('loans', loan.id, data);
  }

  Future<List<Loan>> getLoans() async {
    final data = await _localDb.getAll('loans');
    return data.map((map) => Loan.fromMap(map)).toList();
  }

  Future<void> updateLoan(Loan loan) async {
    final data = loan.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.update('loans', 'id', loan.id, data);
    _syncToFirestore('loans', loan.id, data);
  }

  Future<void> deleteLoan(String id) async {
    await _localDb.delete('loans', 'id', id);
    try {
      await _firestore.delete('loans', id);
    } catch (e) {
      print("Error deleting loan from Firestore: $e");
    }
  }

  // --- RETURNS CRUD ---
  Future<void> addReturn(AssetReturn r) async {
    final data = r.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.insert('returns', data);
    _syncToFirestore('returns', r.id, data);
  }

  Future<List<AssetReturn>> getReturns() async {
    final data = await _localDb.getAll('returns');
    return data.map((map) => AssetReturn.fromMap(map)).toList();
  }

  Future<void> updateReturn(AssetReturn r) async {
    final data = r.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.update('returns', 'id', r.id, data);
    _syncToFirestore('returns', r.id, data);
  }

  Future<void> deleteReturn(String id) async {
    await _localDb.delete('returns', 'id', id);
    try {
      await _firestore.delete('returns', id);
    } catch (e) {
      print("Error deleting return from Firestore: $e");
    }
  }

  // --- MAINTENANCE CRUD ---
  Future<void> addMaintenance(Maintenance m) async {
    final data = m.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.insert('maintenances', data);
    _syncToFirestore('maintenances', m.id, data);
  }

  Future<List<Maintenance>> getMaintenances() async {
    final data = await _localDb.getAll('maintenances');
    return data.map((map) => Maintenance.fromMap(map)).toList();
  }

  Future<void> updateMaintenance(Maintenance m) async {
    final data = m.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.update('maintenances', 'id', m.id, data);
    _syncToFirestore('maintenances', m.id, data);
  }

  Future<void> deleteMaintenance(String id) async {
    await _localDb.delete('maintenances', 'id', id);
    try {
      await _firestore.delete('maintenances', id);
    } catch (e) {
      print("Error deleting maintenance from Firestore: $e");
    }
  }

  // --- HISTORY CRUD ---
  Future<void> addHistory(History h) async {
    final data = h.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.insert('history', data);
    _syncToFirestore('history', h.id, data);
  }

  Future<List<History>> getHistories() async {
    final data = await _localDb.getAll('history');
    return data.map((map) => History.fromMap(map)).toList();
  }

  Future<void> updateHistory(History h) async {
    final data = h.copyWith(syncStatus: SyncStatus.pendingSync).toMap();
    await _localDb.update('history', 'id', h.id, data);
    _syncToFirestore('history', h.id, data);
  }

  Future<void> deleteHistory(String id) async {
    await _localDb.delete('history', 'id', id);
    try {
      await _firestore.delete('history', id);
    } catch (e) {
      print("Error deleting history from Firestore: $e");
    }
  }
}
