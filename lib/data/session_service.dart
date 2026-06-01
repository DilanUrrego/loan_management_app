import '../models/user.dart';

/// Singleton que guarda el usuario autenticado en memoria durante la sesión.
/// Se debe poblar al hacer login antes de navegar al HomePage.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == UserRole.admin;

  void setUser(User user) => _currentUser = user;

  void clear() => _currentUser = null;
}