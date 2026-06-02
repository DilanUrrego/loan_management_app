import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../data/session_service.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/history.dart';
import '../models/maintenance.dart';
import '../models/user.dart' as app_model;

class LoanView {
  final Loan loan;
  final Asset? asset;
  const LoanView({required this.loan, this.asset});
}

class PrestamosController extends ChangeNotifier {
  final _crud = CrudService();
  final _session = SessionService();

  List<LoanView> _all = [];
  List<LoanView> _filtered = [];
  bool _loading = true;

  List<LoanView> get filtered => _filtered;
  bool get loading => _loading;

  Future<void> load({String? initialFilter}) async {
    _loading = true;
    notifyListeners();

    final loans = await _crud.getLoans();
    final assets = await _crud.getAssets();
    final assetMap = {for (final a in assets) a.id: a};

    final role = _session.currentUser?.role;
    final currentUser = _session.currentUser;

    var views = loans.map((l) {
      final asset = assetMap[l.assetId];
      return LoanView(loan: l, asset: asset);
    }).toList();

    // Requesters solo pueden ver sus propios préstamos
    if (role == app_model.UserRole.requester && currentUser != null) {
      views = views.where((v) => v.loan.requestedBy == currentUser.name).toList();
    }

    if (initialFilter != null) {
      views = views.where((v) => 
        _statusLabelFallback(v.loan) == initialFilter || 
        v.loan.status.name.toLowerCase() == initialFilter.toLowerCase()
      ).toList();
    }

    views.sort((a, b) => b.loan.loanDate.compareTo(a.loan.loanDate));

    _all = views;
    _filtered = views;
    _loading = false;
    notifyListeners();
  }

  void search(String query) {
    final q = query.toLowerCase();
    _filtered = _all.where((v) {
      return v.loan.requestedBy.toLowerCase().contains(q) ||
          (v.asset?.name.toLowerCase().contains(q) ?? false) ||
          _statusLabelFallback(v.loan).toLowerCase().contains(q);
    }).toList();
    notifyListeners();
  }

  Future<void> approve(LoanView view) async {
    final updated = view.loan.copyWith(
      status: LoanStatus.active,
      approvedBy: _session.currentUser?.name,
    );
    await _crud.updateLoan(updated);
    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo aprobado',
      description:
          '${_session.currentUser?.name} aprobó préstamo de ${view.asset?.name ?? view.loan.assetId} a ${view.loan.requestedBy}',
      date: DateTime.now(),
      type: 'loan',
    ));
    await load();
  }

  Future<void> reject(LoanView view) async {
    final updated = view.loan.copyWith(status: LoanStatus.rejected);
    await _crud.updateLoan(updated);

    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: 'Disponible'));
    }

    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo rechazado',
      description:
          'Préstamo de ${view.asset?.name ?? view.loan.assetId} a ${view.loan.requestedBy} fue rechazado',
      date: DateTime.now(),
      type: 'loan',
    ));
    await load();
  }

  Future<void> markOverdue(LoanView view) async {
    final updated = view.loan.copyWith(status: LoanStatus.overdue);
    await _crud.updateLoan(updated);
    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: 'Vencido'));
    }
    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo vencido',
      description:
          'Préstamo de ${view.asset?.name ?? view.loan.assetId} a ${view.loan.requestedBy} marcado como vencido',
      date: DateTime.now(),
      type: 'loan',
    ));
    await load();
  }

  Future<void> returnLoan(LoanView view, String selectedStatus) async {
    final updated = view.loan.copyWith(status: LoanStatus.returned);
    await _crud.updateLoan(updated);

    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: selectedStatus));
    }

    if (selectedStatus == 'Mantenimiento') {
      await _crud.addMaintenance(Maintenance(
        id: const Uuid().v4(),
        assetId: view.asset?.id ?? view.loan.assetId,
        date: DateTime.now(),
        technician: 'Técnico Default',
        status: 'En proceso',
      ));
    }

    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Préstamo devuelto',
      description:
          '${_session.currentUser?.name} confirmó devolución de ${view.asset?.name ?? view.loan.assetId} (Estado: $selectedStatus)',
      date: DateTime.now(),
      type: 'return',
    ));
    await load();
  }

  // Fallback simple usado solo para filtrado interno (se recomienda que UI use BusinessRules)
  String _statusLabelFallback(Loan loan) {
    if ((loan.status == LoanStatus.active || loan.status == LoanStatus.approved) && 
        loan.dueDate.isBefore(DateTime.now())) {
      return 'Vencido';
    }
    switch (loan.status) {
      case LoanStatus.pending: return 'Pendiente';
      case LoanStatus.approved:
      case LoanStatus.active: return 'Activo';
      case LoanStatus.overdue: return 'Vencido';
      case LoanStatus.returned: return 'Devuelto';
      case LoanStatus.rejected: return 'Rechazado';
    }
  }
}
