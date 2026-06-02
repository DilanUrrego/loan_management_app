import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/crud_service.dart';
import '../models/maintenance.dart';
import '../models/asset.dart';
import '../models/history.dart';

class MaintView {
  final Maintenance maintenance;
  final Asset? asset;
  const MaintView({required this.maintenance, this.asset});
}

class MantenimientoController extends ChangeNotifier {
  final _crud = CrudService();

  List<MaintView> _all = [];
  List<MaintView> _filtered = [];
  bool _loading = true;

  List<MaintView> get filtered => _filtered;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final maintenances = await _crud.getMaintenances();
    final assets = await _crud.getAssets();
    final assetMap = {for (final a in assets) a.id: a};

    final views = maintenances.map((m) {
      return MaintView(maintenance: m, asset: assetMap[m.assetId]);
    }).toList()
      ..sort((a, b) => b.maintenance.date.compareTo(a.maintenance.date));

    _all = views;
    _filtered = views;
    _loading = false;
    notifyListeners();
  }

  void search(String query) {
    final q = query.toLowerCase();
    _filtered = _all.where((v) {
      return (v.asset?.name.toLowerCase().contains(q) ?? false) ||
          v.maintenance.technician.toLowerCase().contains(q) ||
          v.maintenance.status.toLowerCase().contains(q);
    }).toList();
    notifyListeners();
  }

  Future<void> createMaintenance({
    required String assetId,
    required String technician,
  }) async {
    final assets = await _crud.getAssets();
    final asset = assets.firstWhere((a) => a.id == assetId);
    final now = DateTime.now();

    final m = Maintenance(
      id: const Uuid().v4(),
      assetId: assetId,
      technician: technician,
      date: now,
      status: 'En proceso',
    );
    await _crud.addMaintenance(m);

    // Marcar activo como en mantenimiento
    await _crud.updateAsset(asset.copyWith(status: 'Mantenimiento'));

    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Mantenimiento iniciado',
      description: '${asset.name} enviado a mantenimiento con $technician',
      date: now,
      type: 'maintenance',
    ));
    await load();
  }

  Future<void> finalizeMaintenance(MaintView view) async {
    final updated = view.maintenance.copyWith(status: 'Finalizado');
    await _crud.updateMaintenance(updated);

    if (view.asset != null) {
      await _crud.updateAsset(view.asset!.copyWith(status: 'Disponible'));
    }

    await _crud.addHistory(History(
      id: const Uuid().v4(),
      title: 'Mantenimiento finalizado',
      description:
          '${view.asset?.name ?? view.maintenance.assetId} completó mantenimiento con ${view.maintenance.technician}',
      date: DateTime.now(),
      type: 'maintenance',
    ));
    await load();
  }

  Future<List<Asset>> getEligibleAssets() async {
    final assets = await _crud.getAssets();
    return assets
        .where((a) => a.status == 'Mantenimiento' || a.status == 'Disponible')
        .toList();
  }
}
