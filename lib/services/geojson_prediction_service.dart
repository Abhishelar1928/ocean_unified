import '../models/geojson_zone.dart';

/// Loads the bundled North Sea AI fishing-prediction GeoJSON asset and
/// converts it into a list of [GeoJsonZone] objects.
///
/// All work is done asynchronously so it never blocks the UI thread.
/// The asset is loaded from the Flutter bundle (works fully offline —
/// no network request is ever made).
///
/// Usage:
/// ```dart
/// final service = GeoJsonPredictionService();
/// final zones = await service.loadNorthSeaPrediction();
/// ```
class GeoJsonPredictionService {
  /// Path inside the Flutter assets bundle.
  static const _assetPath = 'assets/data/north_sea_fishing_prediction.geojson';

  // ── Public API ──────────────────────────────────────────────────

  /// Loads the North Sea prediction dataset.
  ///
  /// Steps performed internally:
  ///   1. Load `north_sea_fishing_prediction.geojson` from the asset bundle.
  ///   2. Decode the JSON string.
  ///   3. Extract the top-level `"features"` list.
  ///   4. Convert each feature map into a [GeoJsonZone] via
  ///      [GeoJsonZone.fromFeature].
  ///   5. Return the completed [List<GeoJsonZone>].
  ///
  /// Throws a [FlutterError] if the asset is missing from the bundle.
  Future<List<GeoJsonZone>> loadNorthSeaPrediction() async {
    final collection = await GeoJsonCollection.loadAsset(_assetPath);
    return collection.zones;
  }
}
