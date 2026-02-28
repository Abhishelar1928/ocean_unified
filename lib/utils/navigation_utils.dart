import 'dart:math';
import 'package:latlong2/latlong.dart' as ll;

// ═══════════════════════════════════════════════════════════
//  NavigationUtils
//  Haversine distance, bearing, cardinal direction helpers.
// ═══════════════════════════════════════════════════════════

/// Calculates the great-circle distance between two geographic points using
/// the Haversine formula.
///
/// Returns the distance in **kilometres**.
///
/// Both [start] and [end] are standard [ll.LatLng] coordinates.
double calculateDistance(ll.LatLng start, ll.LatLng end) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _toRad(end.latitude - start.latitude);
  final double dLon = _toRad(end.longitude - start.longitude);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(start.latitude)) *
          cos(_toRad(end.latitude)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Calculates the initial bearing (forward azimuth) from [start] to [end].
///
/// Returns a value in the range **0–360 degrees** measured clockwise from
/// true north:
///   - 0°   → North
///   - 90°  → East
///   - 180° → South
///   - 270° → West
double calculateBearing(ll.LatLng start, ll.LatLng end) {
  final double lat1 = _toRad(start.latitude);
  final double lat2 = _toRad(end.latitude);
  final double dLon = _toRad(end.longitude - start.longitude);

  final double y = sin(dLon) * cos(lat2);
  final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

  // atan2 returns a value in (-π, π]; convert to 0–360 °.
  return ((_toDeg(atan2(y, x)) + 360) % 360);
}

/// Converts a bearing in degrees to an 8-point cardinal direction string.
///
/// | Range (° from N) | Direction |
/// |-------------------|-----------|
/// | 337.5 – 22.5      | N         |
/// | 22.5  – 67.5      | NE        |
/// | 67.5  – 112.5     | E         |
/// | 112.5 – 157.5     | SE        |
/// | 157.5 – 202.5     | S         |
/// | 202.5 – 247.5     | SW        |
/// | 247.5 – 292.5     | W         |
/// | 292.5 – 337.5     | NW        |
String getCardinalDirection(double bearing) {
  const List<String> directions = [
    'N',
    'NE',
    'E',
    'SE',
    'S',
    'SW',
    'W',
    'NW',
  ];
  // Each sector spans 45° starting at −22.5° (i.e. 337.5°) from north.
  final int index = ((bearing + 22.5) / 45).floor() % 8;
  return directions[index];
}

/// Estimates travel time in hours for a given [distanceKm] at [speedKmh].
///
/// Defaults to **20 km/h** (typical small fishing vessel).
double estimateTravelTimeHours(double distanceKm, {double speedKmh = 20.0}) {
  if (speedKmh <= 0) return double.infinity;
  return distanceKm / speedKmh;
}

/// Returns a human-readable time string for [hours]:
///   - < 1 h  →  "45 min"
///   - ≥ 1 h  →  "2 h 15 min"
String formatTravelTime(double hours) {
  if (hours.isInfinite || hours.isNaN) return '—';
  final int totalMin = (hours * 60).round();
  if (totalMin < 60) return '$totalMin min';
  final int h = totalMin ~/ 60;
  final int m = totalMin % 60;
  return m > 0 ? '$h h $m min' : '$h h';
}

// ── Internal helpers ─────────────────────────────────────────
double _toRad(double deg) => deg * pi / 180.0;
double _toDeg(double rad) => rad * 180.0 / pi;
