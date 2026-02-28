import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../l10n/app_strings.dart';

/// Application-wide state shared across all screens.
///
/// Holds:
/// - Current GPS [location]
/// - UI [lang] (English / Marathi toggle)
/// - [selectedRegionId] (one of the 5 coastal region IDs)
/// - [completedModules] — set of learning module IDs completed
/// - [simulatorScore] — last simulator score (out of 5)
class AppState extends ChangeNotifier {
  // ── GPS ──────────────────────────────────────────────────────────
  ll.LatLng? _location;

  ll.LatLng? get location => _location;

  void updateLocation(double latitude, double longitude) {
    _location = ll.LatLng(latitude, longitude);
    notifyListeners();
  }

  void clearLocation() {
    _location = null;
    notifyListeners();
  }

  // ── Language ──────────────────────────────────────────────────────
  AppLang _lang = AppLang.en;

  AppLang get lang => _lang;
  AppStrings get strings => AppStrings.of(_lang);

  void toggleLang() {
    _lang = _lang == AppLang.en ? AppLang.mr : AppLang.en;
    notifyListeners();
  }

  void setLang(AppLang lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
  }

  // ── Selected Region ───────────────────────────────────────────────
  String _selectedRegionId = 'mumbai';

  String get selectedRegionId => _selectedRegionId;

  void setRegion(String regionId) {
    if (_selectedRegionId == regionId) return;
    _selectedRegionId = regionId;
    notifyListeners();
  }

  // ── Progress tracking ─────────────────────────────────────────────
  final Set<String> _completedModules = {};

  Set<String> get completedModules => Set.unmodifiable(_completedModules);
  int get completedCount => _completedModules.length;

  void markModuleComplete(String moduleId) {
    if (_completedModules.add(moduleId)) notifyListeners();
  }

  void unmarkModule(String moduleId) {
    if (_completedModules.remove(moduleId)) notifyListeners();
  }

  bool isModuleComplete(String moduleId) =>
      _completedModules.contains(moduleId);

  // ── Simulator score ───────────────────────────────────────────────
  int _simulatorScore = 0;

  int get simulatorScore => _simulatorScore;

  void updateSimulatorScore(int score) {
    _simulatorScore = score;
    notifyListeners();
  }
}
