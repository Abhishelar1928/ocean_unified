import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' as ll;

/// Represents one GeoJSON Feature from north_sea_fishing_prediction.geojson.
///
/// Supports both Point and Polygon geometry types:
///   - Point   → [polygonPoints] contains the single coordinate
///   - Polygon → [polygonPoints] contains the outer ring coordinates
class GeoJsonZone {
  /// Unique identifier derived from the feature's `id` field,
  /// or auto-generated as `"zone_<index>"` when absent.
  final String id;

  /// AI prediction score in the range [0.0 – 1.0].
  /// Read from `properties.prediction_score`;
  /// falls back to `properties.fishing_prob` for backward compatibility.
  final double predictionScore;

  /// Coordinate ring for this zone.
  ///
  /// - Polygon / MultiPolygon features: outer ring vertices.
  /// - Point features: list containing the single [ll.LatLng] point.
  ///
  /// GeoJSON stores coordinates as [longitude, latitude]; this list
  /// stores them as [ll.LatLng(latitude, longitude)].
  final List<ll.LatLng> polygonPoints;

  const GeoJsonZone({
    required this.id,
    required this.predictionScore,
    required this.polygonPoints,
  });

  // ── Derived helpers ──────────────────────────────────────────────

  /// Prediction score as a percentage string, e.g. `"63.5%"`.
  String get scorePct => '${(predictionScore * 100).toStringAsFixed(1)}%';

  /// Classification label based on [predictionScore].
  String get label {
    if (predictionScore >= 0.65) return 'High';
    if (predictionScore >= 0.45) return 'Moderate';
    return 'Low';
  }

  /// Centroid of [polygonPoints] (simple arithmetic mean).
  ll.LatLng get centroid {
    if (polygonPoints.isEmpty) return const ll.LatLng(0, 0);
    final lat = polygonPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
        polygonPoints.length;
    final lng = polygonPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
        polygonPoints.length;
    return ll.LatLng(lat, lng);
  }

  // ── Factory constructor ──────────────────────────────────────────

  /// Parse a single GeoJSON Feature map.
  ///
  /// Accepts an optional [index] used to generate a fallback [id] when
  /// the feature has no top-level `id` field.
  factory GeoJsonZone.fromFeature(
    Map<String, dynamic> feature, {
    int index = 0,
  }) {
    // ── id ──────────────────────────────────────────────────────────
    final String id = feature['id']?.toString() ?? 'zone_$index';

    // ── geometry.coordinates ────────────────────────────────────────
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final geometryType = geometry['type'] as String;
    final rawCoords = geometry['coordinates'];

    List<ll.LatLng> polygonPoints;

    switch (geometryType) {
      case 'Point':
        // coordinates: [lon, lat]
        final coords = rawCoords as List<dynamic>;
        polygonPoints = [
          ll.LatLng(
            (coords[1] as num).toDouble(),
            (coords[0] as num).toDouble(),
          ),
        ];

      case 'Polygon':
        // coordinates: [ [ [lon, lat], ... ] ]  (first ring = outer ring)
        final ring = (rawCoords as List<dynamic>)[0] as List<dynamic>;
        polygonPoints = ring.map((c) {
          final coord = c as List<dynamic>;
          return ll.LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          );
        }).toList();

      case 'MultiPolygon':
        // coordinates: [ [ [ [lon, lat], ... ] ] ]
        // Use the outer ring of the first polygon.
        final firstPoly = (rawCoords as List<dynamic>)[0] as List<dynamic>;
        final ring = firstPoly[0] as List<dynamic>;
        polygonPoints = ring.map((c) {
          final coord = c as List<dynamic>;
          return ll.LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          );
        }).toList();

      default:
        polygonPoints = const [];
    }

    // ── properties.prediction_score ─────────────────────────────────
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final double predictionScore = props.containsKey('prediction_score')
        ? (props['prediction_score'] as num).toDouble()
        : (props['fishing_prob'] as num? ?? 0.0).toDouble();

    return GeoJsonZone(
      id: id,
      predictionScore: predictionScore,
      polygonPoints: polygonPoints,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FeatureCollection loader
// ═══════════════════════════════════════════════════════════════════

class GeoJsonCollection {
  final List<GeoJsonZone> zones;

  const GeoJsonCollection(this.zones);

  int get length => zones.length;

  /// Zones whose [GeoJsonZone.predictionScore] ≥ [threshold] (default 0.6).
  List<GeoJsonZone> highScoreZones({double threshold = 0.6}) =>
      zones.where((z) => z.predictionScore >= threshold).toList();

  // ── Loading ──────────────────────────────────────────────────────

  /// Loads and parses the bundled GeoJSON asset asynchronously.
  static Future<GeoJsonCollection> loadAsset([
    String assetPath = 'assets/data/north_sea_fishing_prediction.geojson',
  ]) async {
    final raw = await rootBundle.loadString(assetPath);
    return fromJson(raw);
  }

  /// Parses a raw GeoJSON string into a [GeoJsonCollection].
  static GeoJsonCollection fromJson(String raw) {
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>;
    final zones = features
        .asMap()
        .entries
        .map((e) => GeoJsonZone.fromFeature(
              e.value as Map<String, dynamic>,
              index: e.key,
            ))
        .toList();
    return GeoJsonCollection(zones);
  }
}
