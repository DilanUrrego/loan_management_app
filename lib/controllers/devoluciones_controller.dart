import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/asset_return.dart';
import '../models/maintenance.dart';
import '../models/history.dart';

class ReturnView {
  final Loan loan;
  final Asset? asset;
  const ReturnView({required this.loan, this.asset});
}

class DoneView {
  final AssetReturn ret;
  final Loan? loan;
  final Asset? asset;
  const DoneView({required this.ret, this.loan, this.asset});
}

class DevolucionesController extends ChangeNotifier {
  final _crud = CrudService();

  List<ReturnView> _pending = [];
  List<ReturnView> _pendingFiltered = [];

  List<DoneView> _done = [];
  List<DoneView> _doneFiltered = [];

  bool _loading = true;

  List<ReturnView> get pendingFiltered => _pendingFiltered;
  List<DoneView> get doneFiltered => _doneFiltered;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final loans = await _crud.getLoans();
    final assets = await _crud.getAssets();
    final returns = await _crud.getReturns();

    final assetMap = {for (final a in assets) a.id: a};
    final returnedLoanIds = returns.map((r) => r.loanId).toSet();

    final pendingLoans = loans.where((l) =>
        (l.status == LoanStatus.active ||
            l.status == LoanStatus.approved ||
            l.status == LoanStatus.overdue) &&
        !returnedLoanIds.contains(l.id)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final loanMap = {for (final l in loans) l.id: l};
    final doneViews = returns.map((r) {
      final loan = loanMap[r.loanId];
      final asset = loan != null ? assetMap[loan.assetId] : null;
      return DoneView(ret: r, loan: loan, asset: asset);
    }).toList()
      ..sort((a, b) => b.ret.returnDate.compareTo(a.ret.returnDate));

    _pending = pendingLoans
        .map((l) => ReturnView(loan: l, asset: assetMap[l.assetId]))
        .toList();
    _pendingFiltered = _pending;
    _done = doneViews;
    _doneFiltered = doneViews;
    _loading = false;
    notifyListeners();
  }

  void search(String query) {
    final q = query.toLowerCase();
    _pendingFiltered = _pending.where((v) {
      return v.loan.requestedBy.toLowerCase().contains(q) ||
          (v.asset?.name.toLowerCase().contains(q) ?? false);
    }).toList();
    _doneFiltered = _done.where((v) {
      return (v.loan?.requestedBy.toLowerCase().contains(q) ?? false) ||
          (v.asset?.name.toLowerCase().contains(q) ?? false) ||
          v.ret.status.toLowerCase().contains(q);
    }).toList();
    notifyListeners();
  }

  Future<void> processReturn({
    required ReturnView view,
    required String condition,
    required String notes,
  }) async {
    const uuid = Uuid();
    final now = DateTime.now();
    final assetName = view.asset?.name ?? view.loan.assetId;

    final needsMaintenance = condition == 'Daño menor' || condition == 'Daño mayor';
    final needsBaja = condition == 'Pérdida';

    final ret = AssetReturn(
      id: uuid.v4(),
      loanId: view.loan.id,
      returnDate: now,
      status: condition,
    );
    await _crud.addReturn(ret);
    await _crud.updateLoan(view.loan.copyWith(status: LoanStatus.returned));

    if (view.asset != null) {
      String newAssetStatus;
      if (needsBaja) {
        newAssetStatus = 'Baja';
      } else if (needsMaintenance) {
        newAssetStatus = 'Mantenimiento';
      } else {
        newAssetStatus = 'Disponible';
      }
      await _crud.updateAsset(view.asset!.copyWith(status: newAssetStatus));
    }

    if (needsMaintenance && view.asset != null) {
      final maintenance = Maintenance(
        id: uuid.v4(),
        assetId: view.asset!.id,
        technician: 'Por asignar',
        date: now,
        status: 'Pendiente',
      );
      await _crud.addMaintenance(maintenance);

      await _crud.addHistory(History(
        id: uuid.v4(),
        title: 'Mantenimiento generado por devolución',
        description: '$assetName requiere mantenimiento tras devolución con novedad: $condition',
        date: now,
        type: 'maintenance',
      ));
    }

    if (needsBaja) {
      await _crud.addHistory(History(
        id: uuid.v4(),
        title: 'Activo dado de baja',
        description: '$assetName fue dado de baja por: $condition',
        date: now,
        type: 'return',
      ));
    }

    final desc = notes.isEmpty
        ? '${view.loan.requestedBy} devolvió $assetName — $condition'
        : '${view.loan.requestedBy} devolvió $assetName — $condition. Obs: $notes';
    
    await _crud.addHistory(History(
      id: uuid.v4(),
      title: 'Activo devuelto',
      description: desc,
      date: now,
      type: 'return',
    ));

    await load();
  }
}
