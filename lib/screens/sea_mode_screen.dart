import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../state/app_state.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/gps_service.dart';
import '../services/geofence_service.dart';
import '../services/port_service.dart';
import '../services/sos_service.dart';
import '../services/offline_data_service.dart';
import '../models/port.dart';
import '../models/restricted_zone.dart';
import '../models/environmental_data.dart';
import '../models/geojson_zone.dart';
import '../utils/navigation_utils.dart';

// ════════════════════════════════════════════════════════
//  Background GeoJSON parser
//  Must be a top-level function so Flutter’s compute() can send it to
//  a background isolate (or web worker on Flutter Web), preventing any
//  UI jank while parsing the 1 000+ feature dataset.
// ════════════════════════════════════════════════════════
List<GeoJsonZone> _parseGeoJsonIsolate(String raw) =>
    GeoJsonCollection.fromJson(raw).zones;

/// Full-screen map mode for at-sea navigation.
///
/// Shows:
///   • Live GPS position (auto-refreshed every 10 s)
///   • AI-predicted best fishing zone via [MarineIntelligenceService]
///   • Distance & bearing to the best zone
///   • A rotating navigation arrow pointing toward the target
///   • Restricted / breeding zone overlays (geofence alerts)
///   • Nearest port markers
///   • Real-time risk banner
///
/// Placeholder: uses a `CustomPaint` canvas until a map SDK
/// (e.g. Mapbox, Google Maps) is integrated.
class SeaModeScreen extends StatefulWidget {
  /// Optional callback invoked when the user toggles back to Home Mode.
  /// When provided, a mode toggle switch appears in the AppBar.
  final VoidCallback? onModeToggle;

  const SeaModeScreen({super.key, this.onModeToggle});

  @override
  State<SeaModeScreen> createState() => _SeaModeScreenState();
}

class _SeaModeScreenState extends State<SeaModeScreen>
    with SingleTickerProviderStateMixin {
  static const _backendUrl = 'http://localhost:3000';

  // ── Services ──────────────────────────
  final _gps = GpsService();
  late final PortService _portService;
  late final GeofenceService _geofenceService;
  late final OfflineDataService _offlineData;
  late final SosService _sosService;
  // ── State ─────────────────────────────
  Position? _currentPos;
  EnvironmentalData? _envData;
  List<Port> _nearbyPorts = [];

  /// Nearest port + its distance from the current position.
  Port? _nearestPort;
  double? _nearestPortDistKm;

  /// Restricted zones loaded from offline cache – rendered as red polygons.
  List<RestrictedZone> _restrictedZones = [];

  bool _loading = true;
  DateTime? _lastRefresh;

  // ── Geofence alert state ─────────────────
  /// Currently active geofence alert (null = no alert).
  GeofenceAlert? _activeGeofenceAlert;

  /// Prevents spamming the same zone alert within a cooldown window.
  final Map<String, DateTime> _alertCooldowns = {};
  static const _alertCooldown = Duration(seconds: 30);

  /// Auto-dismiss timer for approaching-type warnings.
  Timer? _alertDismissTimer;

  // ── SOS state ─────────────────────
  bool _sosSending = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Controller for the smooth arrow rotation animation.
  late final AnimationController _arrowAnimCtrl;

  /// flutter_map controller (centres map on GPS position).
  final MapController _mapController = MapController();

  // ── GeoJSON / North Sea prediction (top 40 by score) ────

  /// Pre-computed circle markers for detail mode (top 40).
  List<CircleMarker> _northSeaCircles = const [];

  /// Pre-computed compact dot markers for performance mode (top 40).
  List<Marker> _northSeaDotMarkers = const [];

  /// Pre-computed tap-target markers (detail mode — top 40).
  List<Marker> _northSeaTapMarkers = const [];

  /// True while the GeoJSON asset is being parsed in the background.
  bool _northSeaLoading = false;

  /// When [true] (default): render dot markers (pixel-size, fastest).
  /// When [false]: render radius-in-metre circles (more visual detail).
  bool _performanceMode = true;

  /// When [true] the map re-centres on the GPS position after every update.
  /// When [false] (default) the user can freely pan/zoom without being snapped
  /// back to their location.  Toggled by the lock-icon button on the map.
  bool _followGps = false;

  // ── Manual route selection ────────────────────────────────────
  /// Start point set by tapping anywhere on the map (blue pin).
  /// Replaced immediately when the user taps a new map position.
  ll.LatLng? _selectedStartPoint;

  /// Destination point set by tapping a fishing-zone marker or a
  /// GeoJSON circle (red pin).
  ll.LatLng? _selectedDestinationPoint;

  /// Shared app state — holds current GPS location and notifies
  /// [ListenableBuilder] widgets (e.g. the live map) when it changes.
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();

    _arrowAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _portService = PortService(baseUrl: _backendUrl);
    _geofenceService = GeofenceService(
      gpsService: _gps,
      onAlert: _onGeofenceAlert,
    );
    _offlineData = OfflineDataService();
    _sosService = SosService(
      gpsService: _gps,
      portService: _portService,
      offlineData: _offlineData,
      backendUrl: _backendUrl,
      emergencyContacts: const [
        EmergencyContact(name: 'Coast Guard', phone: '1554'),
      ],
    );

    // Auto-flush queued SOS when connectivity resumes.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet) _sosService.flushPendingSos();
    });

    _initSeaMode();
  }

  // ──────────────────────────────────────
  //  Initialisation
  // ──────────────────────────────────────

  Future<void> _initSeaMode() async {
    try {
      await _offlineData.init();
      await _portService.loadPorts();

      final pos = await _gps.getCurrentPosition();

      // Load restricted zones for geofence checks + map polygons (offline).
      final cachedZones = _offlineData.getCachedRestrictedZones();
      _geofenceService.updateZones(cachedZones);
      setState(() {
        _restrictedZones = cachedZones;
        _currentPos = pos;
        _nearbyPorts =
            _portService.findPortsNearby(pos.latitude, pos.longitude, 100);
        _nearestPort =
            _portService.findNearestPort(pos.latitude, pos.longitude);
        _nearestPortDistKm =
            _nearestPort?.distanceKmTo(pos.latitude, pos.longitude);
        _lastRefresh = DateTime.now();
        _loading = false;
      });
      _appState.updateLocation(pos.latitude, pos.longitude);

      // Auto-load North Sea GeoJSON fishing-probability prediction.
      _loadNorthSeaPrediction();

      // Live position stream (updates _currentPos + geofence checks).
      await _gps.startTracking(onPosition: (p) {
        if (!mounted) return;
        setState(() {
          _currentPos = p;
          _nearbyPorts =
              _portService.findPortsNearby(p.latitude, p.longitude, 100);
          _nearestPort = _portService.findNearestPort(p.latitude, p.longitude);
          _nearestPortDistKm =
              _nearestPort?.distanceKmTo(p.latitude, p.longitude);
          _lastRefresh = DateTime.now();
        });
        // Check geofence on every GPS tick (fully offline).
        _geofenceService.checkPosition(p);
        // Notify the map’s ListenableBuilder so it re-centres on the new fix.
        _appState.updateLocation(p.latitude, p.longitude);
      });
    } catch (e) {
      // Fallback: still render the map with whatever offline data exists.
      setState(() => _loading = false);
    }
  }

  // ──────────────────────────────────────
  //  North Sea GeoJSON loader (auto-runs at init)
  // ──────────────────────────────────────

  // ── 5-tier probability categorisation ──
  // Thresholds calibrated to the dataset range (0.08 – 0.62).
  static const _kExcellent = 0.55; // dark green
  static const _kGood = 0.45; // green
  static const _kModerate = 0.35; // yellow
  static const _kLow = 0.25; // orange
  //                          < 0.25  → red (very low)

  static Color _categoryColor(double prob) {
    if (prob >= _kExcellent) return const Color(0xFF00C853);
    if (prob >= _kGood) return const Color(0xFF66BB6A);
    if (prob >= _kModerate) return const Color(0xFFFFD600);
    if (prob >= _kLow) return const Color(0xFFFF9100);
    return const Color(0xFFFF1744);
  }

  static Color _categoryFill(double prob) {
    if (prob >= _kExcellent) return const Color(0x6000C853);
    if (prob >= _kGood) return const Color(0x6066BB6A);
    if (prob >= _kModerate) return const Color(0x60FFD600);
    if (prob >= _kLow) return const Color(0x60FF9100);
    return const Color(0x60FF1744);
  }

  Future<void> _loadNorthSeaPrediction() async {
    if (_northSeaLoading) return;
    setState(() => _northSeaLoading = true);
    try {
      const assetPath = 'assets/data/north_sea_fishing_prediction.geojson';
      final raw = await rootBundle.loadString(assetPath);

      // Parse in background isolate to avoid UI jank.
      final allZones = await compute(_parseGeoJsonIsolate, raw);

      // Sort by predictionScore descending, take top 40.
      final sorted = [...allZones]
        ..sort((a, b) => b.predictionScore.compareTo(a.predictionScore));
      final top40 = sorted.take(40).toList(growable: false);

      // Pre-compute radius circles (detail mode).
      final circles = top40.map((zone) {
        final pt = zone.polygonPoints.isNotEmpty
            ? zone.polygonPoints.first
            : const ll.LatLng(0, 0);
        return CircleMarker(
          point: pt,
          radius: 3500,
          useRadiusInMeter: true,
          color: _categoryFill(zone.predictionScore),
          borderColor: _categoryColor(zone.predictionScore),
          borderStrokeWidth: 1.5,
        );
      }).toList(growable: false);

      // Pre-compute compact dot markers (performance mode).
      final dots = top40.map((zone) {
        final pt = zone.polygonPoints.isNotEmpty
            ? zone.polygonPoints.first
            : const ll.LatLng(0, 0);
        final dotColor = _categoryColor(zone.predictionScore);
        return Marker(
          point: pt,
          width: 20,
          height: 20,
          child: GestureDetector(
            onTap: () => setState(() => _selectedDestinationPoint = pt),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: Border.all(color: Colors.white70, width: 1),
              ),
            ),
          ),
        );
      }).toList(growable: false);

      // Pre-compute tap-target markers (detail mode).
      final tapMarkers = top40.map((zone) {
        final pt = zone.polygonPoints.isNotEmpty
            ? zone.polygonPoints.first
            : const ll.LatLng(0, 0);
        return Marker(
          point: pt,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => setState(() => _selectedDestinationPoint = pt),
            child: const ColoredBox(color: Colors.transparent),
          ),
        );
      }).toList(growable: false);

      if (mounted) {
        setState(() {
          _northSeaCircles = circles;
          _northSeaDotMarkers = dots;
          _northSeaTapMarkers = tapMarkers;
          _northSeaLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _northSeaLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load prediction data: \$e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────
  //  Geofence alert handler (offline)
  // ──────────────────────────────────────

  void _onGeofenceAlert(GeofenceAlert alert) {
    if (!mounted) return;

    // Cooldown: don’t re-trigger the same zone within 30 s.
    final now = DateTime.now();
    final lastFired = _alertCooldowns[alert.zone.id];
    if (lastFired != null && now.difference(lastFired) < _alertCooldown) return;
    _alertCooldowns[alert.zone.id] = now;

    final isInside = alert.status == GeofenceStatus.inside;

    // 1. Haptic feedback (vibrate) — works offline, no permissions needed.
    if (isInside) {
      HapticFeedback.heavyImpact();
      // Fire three quick bursts for urgency.
      Future.delayed(const Duration(milliseconds: 200),
          () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 400),
          () => HapticFeedback.heavyImpact());
    } else {
      HapticFeedback.mediumImpact();
    }

    // 2. Play system alert sound (platform channel — works offline).
    SystemSound.play(SystemSoundType.alert);

    // 3. Show persistent red/orange overlay.
    _alertDismissTimer?.cancel();
    setState(() => _activeGeofenceAlert = alert);

    // Auto-dismiss “approaching” warnings after 8 s;
    // “inside” alerts stay until the user taps dismiss or leaves the zone.
    if (!isInside) {
      _alertDismissTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _activeGeofenceAlert = null);
      });
    }
  }

  void _dismissGeofenceAlert() {
    _alertDismissTimer?.cancel();
    setState(() => _activeGeofenceAlert = null);
  }

  // ──────────────────────────────────────
  //  SOS
  // ──────────────────────────────────────

  /// Trigger a full SOS sequence:
  ///  1. Capture GPS
  ///  2. Log locally (Hive — survives offline / restart)
  ///  3. Attempt SMS + call + HTTP
  ///  4. Show confirmation dialog with result
  Future<void> _triggerSos() async {
    if (_sosSending) return; // de-bounce
    setState(() => _sosSending = true);

    // Haptic burst to confirm button press
    HapticFeedback.heavyImpact();

    SosResult? result;
    try {
      result = await _sosService.triggerSos();
    } catch (_) {
      // SOS is already queued locally even if everything fails.
    }

    setState(() => _sosSending = false);

    if (!mounted) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosConfirmationDialog(result: result),
    );
  }

  @override
  void dispose() {
    _alertDismissTimer?.cancel();
    _connectivitySub?.cancel();
    _geofenceService.stopMonitoring();
    _arrowAnimCtrl.dispose();
    _appState.dispose();
    _gps.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  UI
  // ══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sea Mode'),
        backgroundColor: Colors.blueGrey[900],
        leading: widget.onModeToggle != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Home',
                onPressed: widget.onModeToggle,
              )
            : null,
        actions: [
          // Mode toggle (visible when launched from AppShell)
          if (widget.onModeToggle != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _SeaModeToggle(
                onSwitchHome: widget.onModeToggle!,
              ),
            ),
          if (_northSeaLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
        ],
      ),
      // SOS floating action button
      floatingActionButton: _loading
          ? null
          : _SosButton(
              sending: _sosSending,
              onPressed: _triggerSos,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── Real Map with OSM tiles ──
                // Rebuilds whenever AppState.location changes (GPS update
                // or periodic reassessment), keeping the centre in sync.
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: _appState,
                    builder: (context, _) => _buildLiveMap(),
                  ),
                ),

                // Risk banner
                if (_envData != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _RiskBanner(risk: _envData!.risk),
                  ),

                // Coordinates + last-refresh
                if (_currentPos != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_currentPos!.latitude.toStringAsFixed(4)}, '
                            '${_currentPos!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                                color: Colors.white, fontFamily: 'monospace'),
                          ),
                          if (_lastRefresh != null)
                            Text(
                              'Updated ${_lastRefresh!.hour.toString().padLeft(2, '0')}:'
                              '${_lastRefresh!.minute.toString().padLeft(2, '0')}:'
                              '${_lastRefresh!.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Nearest port chip (top-right)
                if (_nearestPort != null && _nearestPortDistKm != null)
                  Positioned(
                    top: _envData != null ? 50 : 12,
                    right: 12,
                    child: _NearestPortChip(
                      port: _nearestPort!,
                      distanceKm: _nearestPortDistKm!,
                    ),
                  ),

                // ── Follow GPS toggle (lock icon, top-right corner) ──
                // OFF by default so the user can pan freely.
                // Tap once to lock map to GPS; tap again to unlock.
                Positioned(
                  top: 12,
                  right: 12,
                  child: Tooltip(
                    message: _followGps ? 'Unfollow GPS' : 'Follow GPS',
                    child: Material(
                      color: _followGps ? Colors.cyanAccent : Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() => _followGps = !_followGps);
                          // If just enabled, jump to current position now.
                          if (_followGps && _appState.location != null) {
                            try {
                              _mapController.move(
                                _appState.location!,
                                _mapController.camera.zoom,
                              );
                            } catch (_) {}
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            _followGps
                                ? Icons.gps_fixed_rounded
                                : Icons.gps_not_fixed_rounded,
                            color: _followGps ? Colors.black87 : Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Performance mode toggle ──
                Positioned(
                  bottom: 145,
                  left: 16,
                  child: Tooltip(
                    message: _performanceMode
                        ? 'Switch to detail circles'
                        : 'Switch to fast dots',
                    child: Material(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.circular(10),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(
                            () => _performanceMode = !_performanceMode),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _performanceMode
                                    ? Icons.lens_rounded
                                    : Icons.circle_outlined,
                                color: Colors.cyanAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _performanceMode ? 'Dots (fast)' : 'Circles',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Prediction legend (top 40) ──
                if (_northSeaDotMarkers.isNotEmpty)
                  Positioned(
                    top: 80,
                    right: 16,
                    child: Material(
                      color: const Color(0xDD1B2838),
                      borderRadius: BorderRadius.circular(12),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Top 40 Fishing Spots',
                              style: TextStyle(
                                color: Colors.cyanAccent.shade100,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _legendRow(
                                const Color(0xFF00C853), 'Excellent (≥0.55)'),
                            _legendRow(
                                const Color(0xFF66BB6A), 'Good (0.45–0.55)'),
                            _legendRow(const Color(0xFFFFD600),
                                'Moderate (0.35–0.45)'),
                            _legendRow(
                                const Color(0xFFFF9100), 'Low (0.25–0.35)'),
                            _legendRow(
                                const Color(0xFFFF1744), 'Very Low (<0.25)'),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Manual route navigation panel ──
                // Shown only when the user has selected both a start point
                // (map tap) and a destination (zone / GeoJSON tap).
                if (_selectedStartPoint != null &&
                    _selectedDestinationPoint != null)
                  Positioned(
                    bottom: 150,
                    left: 16,
                    right: 16,
                    child: _UserNavPanel(
                      start: _selectedStartPoint!,
                      destination: _selectedDestinationPoint!,
                      onClear: () => setState(() {
                        _selectedStartPoint = null;
                        _selectedDestinationPoint = null;
                      }),
                    ),
                  ),

                // ── Full-screen geofence alert overlay ──
                if (_activeGeofenceAlert != null)
                  _GeofenceAlertOverlay(
                    alert: _activeGeofenceAlert!,
                    onDismiss: _dismissGeofenceAlert,
                  ),
              ],
            ),
    );
  }

  // ──────────────────────────────────────
  //  Real-time OSM tile map builder
  // ──────────────────────────────────────
  /// Called by [ListenableBuilder] every time [AppState.location] changes.
  /// Returns a loading indicator until the first GPS fix arrives, then a
  /// fully interactive [FlutterMap] centred on the current position.
  Widget _buildLiveMap() {
    final loc = _appState.location;

    // Show loading state until the first GPS fix is available.
    if (loc == null) {
      return const ColoredBox(
        color: Color(0xFF1A3A5C),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white54),
              SizedBox(height: 12),
              Text('Acquiring GPS…',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // Re-centre the map only when the Follow GPS lock is active.
    // When _followGps is false the user can pan freely without being snapped
    // back to their position on every GPS tick.
    if (_followGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.move(loc, _mapController.camera.zoom);
          } catch (_) {}
        }
      });
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: loc,
        initialZoom: 9,
        backgroundColor: const Color(0xFF1A3A5C),
        // Disable Follow GPS when the user manually pans the map.
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _followGps) {
            setState(() => _followGps = false);
          }
        },
        // Tapping the map sets the start point for manual route.
        onTap: (_, latLng) {
          setState(() => _selectedStartPoint = latLng);
        },
      ),
      children: [
        // OSM base tiles — cache-first via OfflineTileProvider.
        // Tiles that have been pre-fetched during Sea Pack download are
        // served instantly from Hive (no network required).  Unknown
        // tiles fall through to the OSM network and are cached on-demand.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fisherman.edusea',
          maxZoom: 18,
          tileProvider: _offlineData.tileProvider,
        ),

        // ── Restricted zone polygons ──
        // Red fill (40 % opacity) + solid border so boundaries are clearly
        // visible on the sea chart.  Zones are loaded from the offline cache
        // at startup so this works with no network connection.
        if (_restrictedZones.isNotEmpty)
          PolygonLayer(
            polygons: _restrictedZones
                .where((z) => z.isActive && z.boundary.length >= 3)
                .map((zone) => Polygon(
                      points: zone.boundary
                          .map((pt) => ll.LatLng(pt[0], pt[1]))
                          .toList(),
                      color: Colors.red.withOpacity(0.40),
                      borderColor: Colors.red.shade700,
                      borderStrokeWidth: 2.0,
                    ))
                .toList(),
          ),

        // ── North Sea GeoJSON prediction layer (top 40) ────
        // Performance mode: dot Markers (pixel-size — fastest).
        // Detail  mode:     radius CircleMarkers (more visual detail).
        if (_performanceMode)
          MarkerLayer(markers: _northSeaDotMarkers)
        else
          CircleLayer(circles: _northSeaCircles),

        // Tap-target overlays (detail mode only — dots handle their own taps).
        if (!_performanceMode) MarkerLayer(markers: _northSeaTapMarkers),

        // Port markers
        MarkerLayer(
          markers: _nearbyPorts.map((port) {
            return Marker(
              point: ll.LatLng(port.latitude, port.longitude),
              width: 36,
              height: 36,
              child: Tooltip(
                message: port.name,
                child: const Icon(Icons.anchor_rounded,
                    color: Colors.amber, size: 22),
              ),
            );
          }).toList(),
        ),

        // Current GPS position marker
        MarkerLayer(
          markers: [
            Marker(
              point: loc,
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.25),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── User-selected start point (blue pin) ──
        // Set by tapping anywhere on the map background.
        if (_selectedStartPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedStartPoint!,
                width: 44,
                height: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(10, 7),
                      painter: _PinTailPainter(Colors.blue.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // ── User-selected destination point (red flag pin) ──
        // Set by tapping a fishing-zone marker or a GeoJSON circle.
        if (_selectedDestinationPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedDestinationPoint!,
                width: 44,
                height: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(10, 7),
                      painter: _PinTailPainter(Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // ── User navigation polyline (start → destination) ──
        // Solid blue line drawn only when both points are set.
        // Updates instantly whenever either pin changes.
        if (_selectedStartPoint != null && _selectedDestinationPoint != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  _selectedStartPoint!,
                  _selectedDestinationPoint!,
                ],
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
      ],
    );
  }

  // Helper for legend rows.
  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Pin-tail painter (downward triangle under marker head)
// ══════════════════════════════════════════════════════════

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ══════════════════════════════════════════════════════════
//  Bearing arrow widget
//  Rotates an arrow icon to point in the navigation direction.
// ══════════════════════════════════════════════════════════

class _BearingArrow extends StatelessWidget {
  final double bearingDeg;
  const _BearingArrow({required this.bearingDeg});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      // Convert bearing degrees → radians for Transform.rotate.
      angle: bearingDeg * (3.141592653589793 / 180.0),
      child: const Icon(
        Icons.navigation_rounded,
        color: Colors.cyanAccent,
        size: 36,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  User navigation info panel
//  Shows distance, bearing, cardinal direction, ETA and a
//  rotating arrow between two user-selected points.
// ══════════════════════════════════════════════════════════

class _UserNavPanel extends StatelessWidget {
  final ll.LatLng start;
  final ll.LatLng destination;
  final VoidCallback onClear;

  const _UserNavPanel({
    required this.start,
    required this.destination,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final double distKm = calculateDistance(start, destination);
    final double bearing = calculateBearing(start, destination);
    final String cardinal = getCardinalDirection(bearing);
    final double travelHours = estimateTravelTimeHours(distKm);
    final String eta = formatTravelTime(travelHours);

    final String distStr = distKm < 1
        ? '${(distKm * 1000).toStringAsFixed(0)} m'
        : '${distKm.toStringAsFixed(2)} km';

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F33).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.2),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: label + clear button
            Row(
              children: [
                const Icon(Icons.route_rounded,
                    color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Manual Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Rotating arrow centred above the data rows
            _BearingArrow(bearingDeg: bearing),
            const SizedBox(height: 8),
            // Data rows: distance / bearing / cardinal / ETA
            _NavRow(
              icon: Icons.straighten_rounded,
              label: 'Distance',
              value: distStr,
            ),
            const SizedBox(height: 4),
            _NavRow(
              icon: Icons.explore_rounded,
              label: 'Bearing',
              value: '${bearing.toStringAsFixed(1)}°  $cardinal',
            ),
            const SizedBox(height: 4),
            _NavRow(
              icon: Icons.timer_rounded,
              label: 'ETA (20 km/h)',
              value: eta,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single labelled data row used inside [_UserNavPanel].
class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SOS button (FloatingActionButton)
// ══════════════════════════════════════════════════════════

class _SosButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onPressed;

  const _SosButton({required this.sending, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton(
        heroTag: 'sos_fab',
        backgroundColor: Colors.red,
        onPressed: sending ? null : onPressed,
        elevation: 8,
        shape: const CircleBorder(),
        child: sending
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sos, color: Colors.white, size: 30),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SOS confirmation dialog
// ══════════════════════════════════════════════════════════

class _SosConfirmationDialog extends StatelessWidget {
  final SosResult? result;
  const _SosConfirmationDialog({this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        result?.anySucceeded == true ? Icons.check_circle : Icons.cloud_off,
        size: 48,
        color: result?.anySucceeded == true ? Colors.green : Colors.orange,
      ),
      title: Text(
        result?.anySucceeded == true ? 'SOS Sent' : 'SOS Saved Locally',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position recorded
          if (result?.position != null)
            _row(
              Icons.my_location,
              '${result!.position!.latitude.toStringAsFixed(5)}, '
              '${result!.position!.longitude.toStringAsFixed(5)}',
              Colors.blue,
            )
          else
            _row(Icons.location_off, 'GPS unavailable', Colors.grey),

          const SizedBox(height: 6),

          // Channel status rows
          _row(
            Icons.sms,
            result?.smsSent == true ? 'SMS sent' : 'SMS failed',
            result?.smsSent == true ? Colors.green : Colors.red,
          ),
          _row(
            Icons.call,
            result?.callInitiated == true
                ? 'Coast Guard call initiated'
                : 'Call not started',
            result?.callInitiated == true ? Colors.green : Colors.red,
          ),
          _row(
            Icons.cloud_upload,
            result?.httpSent == true
                ? 'Server notified'
                : 'Queued — will auto-send when online',
            result?.httpSent == true ? Colors.green : Colors.orange,
          ),

          const SizedBox(height: 10),
          const Text(
            'Your distress signal has been logged locally '
            'and will be retransmitted automatically when '
            'internet is available.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Full-screen geofence alert overlay
// ══════════════════════════════════════════════════════════

class _GeofenceAlertOverlay extends StatelessWidget {
  final GeofenceAlert alert;
  final VoidCallback onDismiss;

  const _GeofenceAlertOverlay({
    required this.alert,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isInside = alert.status == GeofenceStatus.inside;
    final bgColor = isInside ? Colors.red.shade900 : Colors.orange.shade800;
    final severity = alert.zone.severity;

    return Positioned.fill(
      child: Material(
        color: bgColor.withOpacity(isInside ? 0.92 : 0.85),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              _PulsingIcon(
                icon:
                    isInside ? Icons.dangerous_rounded : Icons.warning_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isInside
                    ? '⛔ RESTRICTED ZONE'
                    : '⚠ APPROACHING RESTRICTED ZONE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Zone name
              Text(
                alert.zone.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Restriction type + authority
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _restrictionLabel(alert.zone.type),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  alert.zone.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Distance (for approaching alerts)
              if (!isInside)
                Text(
                  '${alert.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),

              // Severity badge
              if (severity == RestrictionSeverity.prohibited)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ENTRY PROHIBITED BY LAW',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Authority
              if (alert.zone.authority != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Authority: ${alert.zone.authority}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 28),

              // Dismiss button
              ElevatedButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                label: Text(isInside ? 'I UNDERSTAND — DISMISS' : 'DISMISS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: bgColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _restrictionLabel(RestrictionType type) {
    switch (type) {
      case RestrictionType.breedingSeason:
        return '🐟  Breeding Season Ban';
      case RestrictionType.marineProtectedArea:
        return '🌊  Marine Protected Area';
      case RestrictionType.internationalBoundary:
        return '🚫  International Boundary';
      case RestrictionType.navalExercise:
        return '⚓  Naval Exercise Zone';
      case RestrictionType.pollutionHazard:
        return '☢  Pollution Hazard Zone';
      case RestrictionType.other:
        return '🔒  Restricted Area';
    }
  }
}

/// A simple pulsing icon animation (fully offline — no assets needed).
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Supporting widgets
// ══════════════════════════════════════════════════════════

class _RiskBanner extends StatelessWidget {
  final RiskAssessment risk;
  const _RiskBanner({required this.risk});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (risk.level) {
      case RiskLevel.safe:
        bg = Colors.green;
        break;
      case RiskLevel.moderate:
        bg = Colors.orange;
        break;
      case RiskLevel.high:
        bg = Colors.red;
        break;
    }
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Text(
        '${risk.level.name.toUpperCase()}  •  Score ${risk.score}',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Nearest port chip
// ══════════════════════════════════════════════════════════

class _NearestPortChip extends StatelessWidget {
  final Port port;
  final double distanceKm;

  const _NearestPortChip({
    required this.port,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.anchor, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  port.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (port.hasFuel || port.hasMedical || port.hasColdStorage)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (port.hasFuel)
                          const _FacilityIcon(Icons.local_gas_station, 'Fuel'),
                        if (port.hasMedical)
                          const _FacilityIcon(Icons.medical_services, 'Med'),
                        if (port.hasColdStorage)
                          const _FacilityIcon(Icons.ac_unit, 'Cold'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  const _FacilityIcon(this.icon, this.tooltip);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: 13, color: Colors.white54),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Sea Mode toggle (shown in AppBar when launched from AppShell)
// ══════════════════════════════════════════════════════════

class _SeaModeToggle extends StatelessWidget {
  final VoidCallback onSwitchHome;
  const _SeaModeToggle({required this.onSwitchHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(Icons.home_rounded, 'Home', false, onSwitchHome),
          _chip(Icons.sailing_rounded, 'Sea', true, () {}),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.28) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
