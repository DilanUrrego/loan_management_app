import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Limpia campos que no deben ir a Firestore
  Map<String, dynamic> _clean(Map<String, dynamic> data) {
    final d = Map<String, dynamic>.from(data);
    d.remove('syncStatus');
    return d;
  }

  // --- GENERIC CRUD OPERATIONS ---

  Future<void> insert(String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).set(_clean(data), SetOptions(merge: true));
  }

  // Usa set+merge en lugar de update para evitar error si el doc no existe
  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).set(_clean(data), SetOptions(merge: true));
  }

  Future<void> delete(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  // Get data from Firestore
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final snapshot = await _db.collection(collection).get();
    // Inyecta el id del documento en el mapa para que fromMap funcione
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;   // para assets, loans, etc.
      data['uid'] = doc.id;  // para users (no hace daño en otros)
      return data;
    }).toList();
  }
}
