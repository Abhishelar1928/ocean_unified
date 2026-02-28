import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'gps_service.dart';
import 'offline_data_service.dart';
import 'port_service.dart';

/// Emergency SOS service for fishermen at sea.
///
/// Capabilities:
///   1. Broadcast current GPS position via SMS to pre-configured contacts.
///   2. Initiate a phone call to the nearest coast-guard / port authority.
///   3. Send an HTTP distress signal to the backend (when online).
///   4. **Queue** the distress signal locally when offline and auto-send
///      via [flushPendingSos] when connectivity resumes.
///   5. Every SOS is **always** logged locally in Hive so no data is lost.
///
/// Designed to work with minimal connectivity — SMS is the primary channel.
class SosService {
  final GpsService _gps;
  final PortService _portService;
  final OfflineDataService _offlineData;
  final String backendUrl;

  /// Pre-configured emergency contacts (phone numbers).
  final List<EmergencyContact> emergencyContacts;

  /// Indian Coast Guard distress number.
  static const coastGuardNumber = '1554';

  SosService({
    required GpsService gpsService,
    required PortService portService,
    required OfflineDataService offlineData,
    required this.backendUrl,
    required this.emergencyContacts,
  })  : _gps = gpsService,
        _portService = portService,
        _offlineData = offlineData;

  // ──────────────────────────────────────
  //  Trigger SOS
  // ──────────────────────────────────────

  /// Main SOS trigger. Attempts all channels concurrently.
  ///
  /// The distress payload is **always** persisted locally first via
  /// [OfflineDataService.enqueueSos] so it survives app restarts and
  /// offline conditions.
  ///
  /// Returns a summary of which channels succeeded.
  Future<SosResult> triggerSos({String? additionalMessage}) async {
    Position? position;
    try {
      position = _gps.lastKnownPosition ?? await _gps.getCurrentPosition();
    } catch (_) {
      // Position unavailable — proceed with null
    }

    // Build the canonical payload for local storage + HTTP.
    final payload = _buildPayload(position, additionalMessage);

    // 0. **Always** log locally (Hive — works offline).
    await _offlineData.enqueueSos(payload);

    final futures = <Future<bool>>[];

    // 1. SMS to all emergency contacts
    futures.add(_sendSmsToAll(position, additionalMessage));

    // 2. Phone call to coast guard
    futures.add(_callCoastGuard());

    // 3. HTTP distress signal (best-effort — dequeues on success)
    futures.add(_sendHttpDistress(payload));

    final results = await Future.wait(futures);

    return SosResult(
      smsSent: results[0],
      callInitiated: results[1],
      httpSent: results[2],
      position: position,
      timestamp: DateTime.now(),
    );
  }

  // ──────────────────────────────────────
  //  Payload builder
  // ──────────────────────────────────────

  Map<String, dynamic> _buildPayload(Position? pos, String? message) {
    final nearest = pos != null
        ? _portService.findNearestPort(pos.latitude, pos.longitude)
        : null;

    return {
      'latitude': pos?.latitude,
      'longitude': pos?.longitude,
      'accuracy_m': pos?.accuracy,
      'nearest_port': nearest?.name,
      'nearest_port_distance_km': nearest != null && pos != null
          ? nearest.distanceKmTo(pos.latitude, pos.longitude)
          : null,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ──────────────────────────────────────
  //  SMS
  // ──────────────────────────────────────

  Future<bool> _sendSmsToAll(Position? pos, String? extra) async {
    final body = _buildSosMessage(pos, extra);

    try {
      for (final contact in emergencyContacts) {
        final uri = Uri(
          scheme: 'sms',
          path: contact.phone,
          queryParameters: {'body': body},
        );
        await launchUrl(uri);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _buildSosMessage(Position? pos, String? extra) {
    final buf = StringBuffer('🚨 SOS — FISHERMAN IN DISTRESS\n');
    if (pos != null) {
      buf.writeln(
          'Location: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
      buf.writeln(
          'Google Maps: https://maps.google.com/?q=${pos.latitude},${pos.longitude}');

      // Include nearest port if cached
      final nearest = _portService.findNearestPort(pos.latitude, pos.longitude);
      if (nearest != null) {
        buf.writeln(
            'Nearest port: ${nearest.name} (${nearest.distanceKmTo(pos.latitude, pos.longitude).toStringAsFixed(1)} km)');
      }
    } else {
      buf.writeln('Location: UNAVAILABLE');
    }
    buf.writeln('Time: ${DateTime.now().toIso8601String()}');
    if (extra != null && extra.isNotEmpty) {
      buf.writeln('Details: $extra');
    }
    return buf.toString();
  }

  // ──────────────────────────────────────
  //  Phone call
  // ──────────────────────────────────────

  Future<bool> _callCoastGuard() async {
    try {
      final uri = Uri(scheme: 'tel', path: coastGuardNumber);
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────
  //  HTTP distress signal
  // ──────────────────────────────────────

  /// Attempt to POST the distress payload to the backend.
  ///
  /// If the request fails (timeout / no internet), the payload is
  /// already queued locally — [flushPendingSos] will retry later.
  Future<bool> _sendHttpDistress(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$backendUrl/api/sos');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      // Network unavailable — payload already in local queue.
      return false;
    }
  }

  // ──────────────────────────────────────
  //  Flush queued SOS (call on reconnect)
  // ──────────────────────────────────────

  /// Dequeues every pending SOS payload from Hive and POSTs each
  /// to the backend.  Payloads that still fail are re-enqueued.
  ///
  /// Call this when the device regains network connectivity.
  Future<int> flushPendingSos() async {
    final pending = _offlineData.dequeuePendingSos();
    if (pending.isEmpty) return 0;

    int sent = 0;
    for (final payload in pending) {
      final ok = await _sendHttpDistress(payload);
      if (ok) {
        sent++;
      } else {
        // Re-enqueue for the next flush attempt.
        await _offlineData.enqueueSos(payload);
      }
    }
    return sent;
  }
}

// ──────────────────────────────────────────────────────────
//  Supporting models
// ──────────────────────────────────────────────────────────

class EmergencyContact {
  final String name;
  final String phone;
  final String? relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relation,
  });
}

class SosResult {
  final bool smsSent;
  final bool callInitiated;
  final bool httpSent;
  final Position? position;
  final DateTime timestamp;

  const SosResult({
    required this.smsSent,
    required this.callInitiated,
    required this.httpSent,
    this.position,
    required this.timestamp,
  });

  bool get anySucceeded => smsSent || callInitiated || httpSent;
}
