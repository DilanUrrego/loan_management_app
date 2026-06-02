import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'local_db_helper.dart';
import 'crud_service.dart';
import 'session_service.dart';
import '../models/user.dart' as app_model;

/// Gestiona autenticación con soporte offline-first (solo en móvil/escritorio).
/// En web siempre usa Firebase Auth directamente (sin caché local).
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _localDb = LocalDbHelper();
  static const _authTable = 'local_auth';

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb) return; // SQLite no está disponible en web
    final db = await _localDb.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_authTable (
        uid        TEXT PRIMARY KEY,
        email      TEXT NOT NULL,
        passHash   TEXT NOT NULL
      )
    ''');
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<app_model.User> login(String email, String password) async {
    try {
      // Intentar Firebase Auth (online)
      final credential = await fb_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;
      final user = await _getUserProfile(uid);

      // Guardar credencial local solo en plataformas que soportan SQLite
      if (!kIsWeb) {
        await _saveLocalCredential(uid, email, password);
      }

      return user;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Fallback offline solo en móvil/escritorio
      if (!kIsWeb && e.code == 'network-request-failed') {
        return await _offlineLogin(email, password);
      }
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ── Login offline (solo móvil/escritorio) ──────────────────────────────────

  Future<app_model.User> _offlineLogin(String email, String password) async {
    final db = await _localDb.database;
    final rows = await db.query(
      _authTable,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (rows.isEmpty) {
      throw Exception(
          'Sin conexión y no hay sesión guardada para este correo.');
    }

    if (rows.first['passHash'] != _hashPassword(password)) {
      throw Exception('Contraseña incorrecta.');
    }

    final uid = rows.first['uid'] as String;
    final localUsers = await CrudService().getUsers();
    final user = localUsers.firstWhere(
      (u) => u.uid == uid,
      orElse: () => throw Exception('Perfil no encontrado en local.'),
    );

    _validateStatus(user);
    return user;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<app_model.User> _getUserProfile(String uid) async {
    final allUsers = await CrudService().getUsers();
    final user = allUsers.firstWhere(
      (u) => u.uid == uid,
      orElse: () => throw Exception('Perfil de usuario no encontrado.'),
    );
    _validateStatus(user);
    return user;
  }

  void _validateStatus(app_model.User user) {
    if (user.status == app_model.AccountStatus.blocked) {
      throw Exception('Cuenta bloqueada. Contacta al administrador.');
    }
    if (user.status == app_model.AccountStatus.pendingApproval) {
      throw Exception('Cuenta pendiente de aprobación.');
    }
  }

  Future<void> _saveLocalCredential(
      String uid, String email, String password) async {
    final db = await _localDb.database;
    await db.insert(
      _authTable,
      {
        'uid': uid,
        'email': email,
        'passHash': _hashPassword(password),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'Correo no válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      default:
        return 'Error al iniciar sesión.';
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    SessionService().clear();
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
