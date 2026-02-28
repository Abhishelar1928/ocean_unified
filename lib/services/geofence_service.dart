import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../models/restricted_zone.dart';
import 'gps_service.dart';

/// Monitors the fisherman's position and triggers alerts when they
/// approach or enter a [RestrictedZone].
///
/// Uses a two-tier check:
///   1. **Bounding-circle** (Haversine) — fast filter.
///   2. **Point-in-polygon** (ray-casting) — precise boundary check.
class GeofenceService {
  final GpsService _gps;

  /// All known restricted zones (loaded at startup / synced offline).
  List<RestrictedZone> _zones = [];

  /// Buffer distance (km) for "approaching" warnings.
  final double warningBufferKm;

  /// Callback fired when the user enters or approaches a zone.
  void Function(GeofenceAlert alert)? onAlert;

  GeofenceService({
    required GpsService gpsService,
    this.warningBufferKm = 5.0,
    this.onAlert,
  }) : _gps = gpsService;

  // ──────────────────────────────────────
  //  Zone management
  // ──────────────────────────────────────

  /// Load / update the list of restricted zones.
  void updateZones(List<RestrictedZone> zones) {
    _zones = zones;
  }

  // ──────────────────────────────────────
  //  Start / stop monitoring
  // ──────────────────────────────────────

  Future<void> startMonitoring() async {
    await _gps.startTracking(onPosition: _onPositionUpdate);
  }

  Future<void> stopMonitoring() async {
    await _gps.stopTracking();
  }

  // ──────────────────────────────────────
  //  Position callback
  // ──────────────────────────────────────

  /// Manually check a position against all active restricted zones.
  /// Use this when the caller already has its own GPS stream and
  /// does not want [startMonitoring] to create a second one.
  void checkPosition(Position pos) => _onPositionUpdate(pos);

  void _onPositionUpdate(Position pos) {
    final lat = pos.latitude;
    final lon = pos.longitude;

    for (final zone in _zones) {
      if (!zone.isActive) continue;

      // Tier 1 – bounding-circle
      if (!zone.isNearby(lat, lon, bufferKm: warningBufferKm)) continue;

      // Tier 2 – point-in-polygon
      final inside = _isInsidePolygon(lat, lon, zone.boundary);

      if (inside) {
        onAlert?.call(GeofenceAlert(
          zone: zone,
          status: GeofenceStatus.inside,
          distanceKm: 0,
        ));
      } else {
        // Approaching
        final dist = _haversine(
            zone.centerLatitude, zone.centerLongitude, lat, lon);
        if (dist <= zone.approximateRadiusKm + warningBufferKm) {
          onAlert?.call(GeofenceAlert(
            zone: zone,
            status: GeofenceStatus.approaching,
            distanceKm: dist - zone.approximateRadiusKm,
          ));
        }
      }
    }
  }

  // ──────────────────────────────────────
  //  Geometry helpers
  // ──────────────────────────────────────

  /// Ray-casting algorithm (odd-even rule).
  bool _isInsidePolygon(double lat, double lon, List<List<double>> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final yi = poly[i][0], xi = poly[i][1];
      final yj = poly[j][0], xj = poly[j][1];

      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double d) => d * (pi / 180);
}

// ──────────────────────────────────────────────────────────
//  Alert model
// ──────────────────────────────────────────────────────────

enum GeofenceStatus { approaching, inside }

class GeofenceAlert {
  final RestrictedZone zone;
  final GeofenceStatus status;

  /// Approximate distance in km (0 when inside).
  final double distanceKm;

  const GeofenceAlert({
    required this.zone,
    required this.status,
    required this.distanceKm,
  });

  @override
  String toString() =>
      'GeofenceAlert(${zone.name}, $status, ${distanceKm.toStringAsFixed(1)} km)';
}
