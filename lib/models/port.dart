import 'dart:math';

/// Represents a fishing port / harbour that the fisherman can navigate to.
///
/// Used by [PortService] for nearest-port lookups and by [SeaModeScreen]
/// to render port markers on the map.
class Port {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// State the port belongs to (e.g. "Maharashtra").
  final String state;

  /// Type of port: fishing, commercial, or naval.
  final PortType type;

  /// Whether the port currently has refuelling facilities.
  final bool hasFuel;

  /// Whether the port has ice / cold-storage for catch.
  final bool hasColdStorage;

  /// Whether a medical facility or first-aid station is available.
  final bool hasMedical;

  /// Contact number for the port authority (used by SOS service).
  final String? contactNumber;

  /// Operating hours description, e.g. "06:00–18:00".
  final String? operatingHours;

  const Port({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.state,
    this.type = PortType.fishing,
    this.hasFuel = false,
    this.hasColdStorage = false,
    this.hasMedical = false,
    this.contactNumber,
    this.operatingHours,
  });

  factory Port.fromJson(Map<String, dynamic> json) {
    return Port(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      state: json['state'] as String,
      type: PortType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'fishing'),
        orElse: () => PortType.fishing,
      ),
      hasFuel: json['has_fuel'] as bool? ?? false,
      hasColdStorage: json['has_cold_storage'] as bool? ?? false,
      hasMedical: json['has_medical'] as bool? ?? false,
      contactNumber: json['contact_number'] as String?,
      operatingHours: json['operating_hours'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'state': state,
        'type': type.name,
        'has_fuel': hasFuel,
        'has_cold_storage': hasColdStorage,
        'has_medical': hasMedical,
        'contact_number': contactNumber,
        'operating_hours': operatingHours,
      };

  /// Straight-line distance in km to the given coordinate (Haversine).
  double distanceKmTo(double lat, double lon) {
    return _haversine(latitude, longitude, lat, lon);
  }

  @override
  String toString() => 'Port($name, $state)';
}

enum PortType { fishing, commercial, naval }

// ──────────────────────────────────────────────────────────
//  Haversine helper
// ──────────────────────────────────────────────────────────

double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (pi / 180);
