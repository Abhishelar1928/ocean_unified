import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/port.dart';

/// Manages port data — loading, caching, and nearest-port queries.
///
/// Ports are fetched from the backend on first launch and cached locally
/// via [OfflineDataService] for offline access.
class PortService {
  final String _baseUrl;

  /// In-memory cache of all ports.
  List<Port> _ports = [];

  PortService({required String baseUrl}) : _baseUrl = baseUrl;

  /// All loaded ports (may be empty before [loadPorts] completes).
  List<Port> get ports => List.unmodifiable(_ports);

  // ──────────────────────────────────────
  //  Data loading
  // ──────────────────────────────────────

  /// Fetch the port catalogue from the backend API.
  Future<void> loadPorts() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/ports');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        _ports =
            list.map((j) => Port.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Will rely on offline cache
    }
  }

  /// Load from a pre-cached JSON list (used by [OfflineDataService]).
  void loadFromCache(List<Map<String, dynamic>> jsonList) {
    _ports = jsonList.map(Port.fromJson).toList();
  }

  // ──────────────────────────────────────
  //  Queries
  // ──────────────────────────────────────

  /// Returns the nearest port to the given coordinates, or `null` if
  /// no ports are loaded.
  Port? findNearestPort(double lat, double lon) {
    if (_ports.isEmpty) return null;

    Port? nearest;
    double minDist = double.infinity;

    for (final port in _ports) {
      final d = port.distanceKmTo(lat, lon);
      if (d < minDist) {
        minDist = d;
        nearest = port;
      }
    }
    return nearest;
  }

  /// Returns all ports within [radiusKm] of the given point, sorted by
  /// distance (ascending).
  List<Port> findPortsNearby(double lat, double lon, double radiusKm) {
    final results = <_PortDist>[];

    for (final port in _ports) {
      final d = port.distanceKmTo(lat, lon);
      if (d <= radiusKm) {
        results.add(_PortDist(port, d));
      }
    }

    results.sort((a, b) => a.distance.compareTo(b.distance));
    return results.map((r) => r.port).toList();
  }

  /// Returns all ports in the given [state].
  List<Port> portsByState(String state) {
    return _ports.where((p) => p.state == state).toList();
  }

  /// Returns ports that have medical facilities (useful for SOS).
  List<Port> portsWithMedical() {
    return _ports.where((p) => p.hasMedical).toList();
  }
}

// Small helper for sorting
class _PortDist {
  final Port port;
  final double distance;
  const _PortDist(this.port, this.distance);
}
