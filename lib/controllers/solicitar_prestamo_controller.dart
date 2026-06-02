import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/history.dart';
import '../validators/business_rules.dart';
import '../validators/app_constants.dart';

class SolicitarPrestamoController extends ChangeNotifier {
  final _crud = CrudService();
  final _session = SessionService();

  List<Asset> _availableAssets = [];
  bool _loadingAssets = true;
  String? _blockReason;
  bool _isLoading = false;

  List<Asset> get availableAssets => _availableAssets;
  bool get loadingAssets => _loadingAssets;
  String? get blockReason => _blockReason;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _loadingAssets = true;
    notifyListeners();

    // Cargar activos disponibles (sin estados bloqueados)
    final allAssets = await _crud.getAssets();
    final available =
        allAssets.where((a) => !AppConstants.blockedLoanStatuses.contains(a.status)).toList();

    // Verificar límite de 2 préstamos activos por usuario
    String? blockReason;
    final currentUser = _session.currentUser;
    if (currentUser != null) {
      final loans = await _crud.getLoans();
      blockReason = BusinessRules.checkLoanLimit(loans, currentUser.name);
    }

    _availableAssets = available;
    _blockReason = blockReason;
    _loadingAssets = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submit({
    required Asset? selectedAsset,
    required DateTime dueDate,
    required String requestedByManual,
  }) async {
    if (selectedAsset == null) {
      return {'success': false, 'message': 'Por favor selecciona un activo', 'color': Colors.red};
    }
    if (_blockReason != null) {
      return {'success': false, 'message': _blockReason, 'color': Colors.red};
    }

    // Doble verificación: el activo sigue disponible
    if (AppConstants.blockedLoanStatuses.contains(selectedAsset.status)) {
      await loadData();
      return {
        'success': false,
        'message': 'El activo "${selectedAsset.name}" ya no está disponible.',
        'color': Colors.red
      };
    }

    _isLoading = true;
    notifyListeners();

    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final requester = _session.currentUser?.name ?? requestedByManual;

      // 1. Crear préstamo
      final loan = Loan(
        id: uuid.v4(),
        assetId: selectedAsset.id,
        requestedBy: requester,
        loanDate: now,
        dueDate: dueDate,
        status: LoanStatus.pending,
      );
      final synced1 = await _crud.addLoan(loan);

      // 2. Marcar activo como Prestado
      final synced2 = await _crud.updateAsset(selectedAsset.copyWith(status: 'Prestado'));

      // 3. Registrar en historial
      final synced3 = await _crud.addHistory(History(
        id: uuid.v4(),
        title: 'Préstamo solicitado',
        description: '$requester solicitó ${selectedAsset.name}',
        date: now,
        type: 'loan',
      ));

      final synced = synced1 && synced2 && synced3;
      
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'message': synced ? '¡Préstamo solicitado exitosamente!' : 'Solicitud guardada. Falta por sincronizar.',
        'color': synced ? Colors.green : Colors.orange,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error: $e', 'color': Colors.red};
    }
  }

  bool get hasSession => _session.currentUser != null;
  String get currentUserName => _session.currentUser?.name ?? '';
}
