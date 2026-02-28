import 'dart:math';

/// An area where fishing is restricted or prohibited.
///
/// Reasons include seasonal breeding bans, marine-protected areas,
/// international maritime boundaries, and naval exercise zones.
/// Used by [GeofenceService] to alert fishermen.
class RestrictedZone {
  final String id;
  final String name;

  /// Reason for restriction.
  final RestrictionType type;

  /// Human-readable description of the restriction.
  final String description;

  /// Polygon boundary as a list of [lat, lon] pairs.
  final List<List<double>> boundary;

  /// Centre of the zone (for quick distance checks).
  final double centerLatitude;
  final double centerLongitude;

  /// Approximate radius in km for fast bounding-circle filter.
  final double approximateRadiusKm;

  /// Date range the restriction is active. Null means permanent.
  final DateTime? activeFrom;
  final DateTime? activeUntil;

  /// Severity: warning-only vs. hard block.
  final RestrictionSeverity severity;

  /// Authority that declared the zone (e.g. "CMFRI", "Indian Navy").
  final String? authority;

  const RestrictedZone({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.boundary,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.approximateRadiusKm,
    this.activeFrom,
    this.activeUntil,
    this.severity = RestrictionSeverity.warning,
    this.authority,
  });

  /// Whether the restriction is currently in effect.
  bool get isActive {
    final now = DateTime.now();
    if (activeFrom != null && now.isBefore(activeFrom!)) return false;
    if (activeUntil != null && now.isAfter(activeUntil!)) return false;
    return true;
  }

  /// Quick check: is the point within the bounding circle?
  bool isNearby(double lat, double lon, {double bufferKm = 0}) {
    final dist = _haversine(centerLatitude, centerLongitude, lat, lon);
    return dist <= (approximateRadiusKm + bufferKm);
  }

  factory RestrictedZone.fromJson(Map<String, dynamic> json) {
    return RestrictedZone(
      id: json['id'] as String,
      name: json['name'] as String,
      type: RestrictionType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'other'),
        orElse: () => RestrictionType.other,
      ),
      description: json['description'] as String,
      boundary: (json['boundary'] as List)
          .map((p) =>
              List<double>.from((p as List).map((v) => (v as num).toDouble())))
          .toList(),
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      approximateRadiusKm: (json['approximate_radius_km'] as num).toDouble(),
      activeFrom: json['active_from'] != null
          ? DateTime.parse(json['active_from'] as String)
          : null,
      activeUntil: json['active_until'] != null
          ? DateTime.parse(json['active_until'] as String)
          : null,
      severity: RestrictionSeverity.values.firstWhere(
        (e) => e.name == (json['severity'] as String? ?? 'warning'),
        orElse: () => RestrictionSeverity.warning,
      ),
      authority: json['authority'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'boundary': boundary,
        'center_latitude': centerLatitude,
        'center_longitude': centerLongitude,
        'approximate_radius_km': approximateRadiusKm,
        'active_from': activeFrom?.toIso8601String(),
        'active_until': activeUntil?.toIso8601String(),
        'severity': severity.name,
        'authority': authority,
      };

  @override
  String toString() => 'RestrictedZone($name, $type)';
}

enum RestrictionType {
  breedingSeason,
  marineProtectedArea,
  internationalBoundary,
  navalExercise,
  pollutionHazard,
  other,
}

enum RestrictionSeverity {
  /// Informational — fisherman is warned but not blocked.
  warning,

  /// Hard — fisherman must not enter.
  prohibited,
}

// ──────────────────────────────────────────────────────────
//  Haversine (duplicated for model independence)
// ──────────────────────────────────────────────────────────

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _deg2rad(double d) => d * (pi / 180);
