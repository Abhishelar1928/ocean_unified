import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around the device GPS (via `geolocator` package).
///
/// Provides one-shot and streaming position access with permission
/// handling, and feeds [GeofenceService] and [SeaModeScreen].
class GpsService {
  StreamSubscription<Position>? _positionSub;

  /// Last known position (cached).
  Position? lastKnownPosition;

  // ──────────────────────────────────────
  //  Permissions
  // ──────────────────────────────────────

  /// Ensures location services are enabled and permissions granted.
  /// Throws a [GpsServiceException] on failure.
  Future<void> ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw GpsServiceException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw GpsServiceException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw GpsServiceException(
        'Location permission permanently denied. '
        'Please enable it in device settings.',
      );
    }
  }

  // ──────────────────────────────────────
  //  One-shot position
  // ──────────────────────────────────────

  /// Returns the current device position. Requests permissions if needed.
  Future<Position> getCurrentPosition() async {
    await ensurePermissions();
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    lastKnownPosition = pos;
    return pos;
  }

  // ──────────────────────────────────────
  //  Continuous tracking
  // ──────────────────────────────────────

  /// Starts streaming position updates at the given [intervalMs].
  ///
  /// Each update is forwarded to [onPosition].
  /// Call [stopTracking] to cancel.
  Future<void> startTracking({
    required void Function(Position position) onPosition,
    int distanceFilterMetres = 50,
  }) async {
    await ensurePermissions();
    await stopTracking();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMetres,
      ),
    ).listen((pos) {
      lastKnownPosition = pos;
      onPosition(pos);
    });
  }

  /// Cancels the position stream.
  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  /// Whether the stream is currently active.
  bool get isTracking => _positionSub != null;

  /// Clean up resources.
  void dispose() {
    stopTracking();
  }
}

// ──────────────────────────────────────────────────────────
//  Exception
// ──────────────────────────────────────────────────────────

class GpsServiceException implements Exception {
  final String message;
  const GpsServiceException(this.message);

  @override
  String toString() => 'GpsServiceException: $message';
}
