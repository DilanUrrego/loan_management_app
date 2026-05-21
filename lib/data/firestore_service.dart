import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- GENERIC CRUD OPERATIONS ---

  Future<void> insert(String collection, String id, Map<String, dynamic> data) async {
    // Remove syncStatus before sending to Firestore
    final firestoreData = Map<String, dynamic>.from(data);
    firestoreData.remove('syncStatus');
    
    await _db.collection(collection).doc(id).set(firestoreData, SetOptions(merge: true));
  }

  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    final firestoreData = Map<String, dynamic>.from(data);
    firestoreData.remove('syncStatus');
    
    await _db.collection(collection).doc(id).update(firestoreData);
  }

  Future<void> delete(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  // Get data from Firestore
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final snapshot = await _db.collection(collection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
