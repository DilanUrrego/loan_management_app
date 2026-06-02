import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  Future<bool> _insert(String table, String id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      try {
        await _firestore.insert(table, id, data);
        return true;
      } on TimeoutException {
        return false; // Offline
      }
    } else {
      final localData = {...data, 'syncStatus': SyncStatus.pendingSync.index};
      await _localDb.insert(table, localData);
      try {
        await _syncToFirestore(table, id, localData).timeout(const Duration(seconds: 3));
        return true;
      } on TimeoutException {
        return false;
      } catch (e) {
        return false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAll(String table) async {
    if (kIsWeb) {
      return await _firestore.getAll(table);
    } else {
      return await _localDb.getAll(table);
    }
  }

  Future<bool> _update(
      String table, String idColumn, String id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      try {
        await _firestore.update(table, id, data);
        return true;
      } on TimeoutException {
        return false;
      }
    } else {
      final localData = {...data, 'syncStatus': SyncStatus.pendingSync.index};
      await _localDb.update(table, idColumn, id, localData);
      try {
        await _syncToFirestore(table, id, localData).timeout(const Duration(seconds: 3));
        return true;
      } on TimeoutException {
        return false;
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> _delete(String table, String idColumn, String id) async {
    if (kIsWeb) {
      await _firestore.delete(table, id);
    } else {
      await _localDb.delete(table, idColumn, id);
      try {
        await _firestore.delete(table, id);
      } catch (e) {
        print('Error deleting $table from Firestore: $e');
      }
    }
  }

  Future<void> _syncToFirestore(
      String table, String id, Map<String, dynamic> data) async {
    await _firestore.insert(table, id, data);
    final synced = {...data, 'syncStatus': SyncStatus.synced.index};
    final idCol = table == 'users' ? 'uid' : 'id';
    await _localDb.update(table, idCol, id, synced);
  }

  // --- USER CRUD ---
  Future<void> addUser(User user) async {
    await _insert('users', user.uid, user.toMap());
  }
 
  Future<List<User>> getUsers() async {
    final data = await _getAll('users');
    return data.map((m) => User.fromMap(m)).toList();
  }
 
  Future<void> updateUser(User user) async {
    await _update('users', 'uid', user.uid, user.toMap());
  }
 
  Future<void> deleteUser(String uid) async {
    await _delete('users', 'uid', uid);
  }

  // --- ASSETS CRUD ---
  Future<bool> addAsset(Asset asset) async {
    return await _insert('assets', asset.id, asset.toMap());
  }
 
  Future<List<Asset>> getAssets() async {
    final data = await _getAll('assets');
    return data.map((m) => Asset.fromMap(m)).toList();
  }
 
  Future<bool> updateAsset(Asset asset) async {
    return await _update('assets', 'id', asset.id, asset.toMap());
  }
 
  Future<void> deleteAsset(String id) async {
    await _delete('assets', 'id', id);
  }

  // --- LOANS CRUD ---
  Future<bool> addLoan(Loan loan) async {
    return await _insert('loans', loan.id, loan.toMap());
  }
 
  Future<List<Loan>> getLoans() async {
    final data = await _getAll('loans');
    return data.map((m) => Loan.fromMap(m)).toList();
  }
 
  Future<void> updateLoan(Loan loan) async {
    await _update('loans', 'id', loan.id, loan.toMap());
  }
 
  Future<void> deleteLoan(String id) async {
    await _delete('loans', 'id', id);
  }

  // --- RETURNS CRUD ---
  Future<void> addReturn(AssetReturn r) async {
    await _insert('returns', r.id, r.toMap());
  }
 
  Future<List<AssetReturn>> getReturns() async {
    final data = await _getAll('returns');
    return data.map((m) => AssetReturn.fromMap(m)).toList();
  }
 
  Future<void> updateReturn(AssetReturn r) async {
    await _update('returns', 'id', r.id, r.toMap());
  }
 
  Future<void> deleteReturn(String id) async {
    await _delete('returns', 'id', id);
  }

  // --- MAINTENANCE CRUD ---
  Future<void> addMaintenance(Maintenance m) async {
    await _insert('maintenances', m.id, m.toMap());
  }
 
  Future<List<Maintenance>> getMaintenances() async {
    final data = await _getAll('maintenances');
    return data.map((m) => Maintenance.fromMap(m)).toList();
  }
 
  Future<void> updateMaintenance(Maintenance m) async {
    await _update('maintenances', 'id', m.id, m.toMap());
  }
 
  Future<void> deleteMaintenance(String id) async {
    await _delete('maintenances', 'id', id);
  }

  // --- HISTORY CRUD ---
  Future<bool> addHistory(History h) async {
    return await _insert('history', h.id, h.toMap());
  }
 
  Future<List<History>> getHistories() async {
    final data = await _getAll('history');
    return data.map((m) => History.fromMap(m)).toList();
  }
 
  Future<void> updateHistory(History h) async {
    await _update('history', 'id', h.id, h.toMap());
  }
 
  Future<void> deleteHistory(String id) async {
    await _delete('history', 'id', id);
  }
}
