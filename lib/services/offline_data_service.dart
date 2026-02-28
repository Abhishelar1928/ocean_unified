import 'dart:convert';
import 'package:hive/hive.dart';

import 'tile_cache_service.dart';
import 'offline_tile_provider.dart';
import '../models/fishing_zone.dart';
import '../models/port.dart';
import '../models/restricted_zone.dart';
import '../models/environmental_data.dart';

/// Provides offline caching & retrieval for all critical data layers
/// using [Hive] — a lightweight, NoSQL, key-value store optimised for
/// Flutter.  Hive is chosen over SharedPreferences because it handles
/// large JSON payloads (polygon arrays, zone catalogues) efficiently
/// and supports lazy-loading boxes.
///
/// Cached entities:
///   • [Port] catalogue
///   • [RestrictedZone] list (with polygon boundaries)
///   • Last [EnvironmentalData] snapshot (with suitability score)
///   • Ranked [FishingZone] predictions (from AI model)
///   • Pending SOS messages (queued for retry when connectivity returns)
///   • **Sea Pack** metadata (download timestamp, version, staleness)
///   • Map tiles for the user's coastline region ([TileCacheService])
///
/// ### Download Sea Pack
///
/// When the user taps **"Download Sea Pack"**, [downloadSeaPack] saves
/// *all* of the above in one go, enabling complete Sea Mode functionality
/// in airplane mode.
class OfflineDataService {
  // ──────────────────────────────────────
  //  Hive box names
  // ──────────────────────────────────────
  static const _boxPorts = 'offline_ports';
  static const _boxRestricted = 'offline_restricted_zones';
  static const _boxEnv = 'offline_env_snapshot';
  static const _boxPredictions = 'offline_predictions';
  static const _boxSos = 'offline_pending_sos';
  static const _boxMeta = 'offline_meta';

  /// Raster tile cache (zoom 8–13 for selected coastal region).
  final TileCacheService _tileCache = TileCacheService();

  late Box<String> _portsBox;
  late Box<String> _restrictedBox;
  late Box<String> _envBox;
  late Box<String> _predictionsBox;
  late Box<String> _sosBox;
  late Box<dynamic> _metaBox;

  bool _initialised = false;

  /// Whether [init] has been called successfully.
  bool get isInitialised => _initialised;

  // ──────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────

  /// Initialise Hive and open all boxes.
  ///
  /// Must be called once at app startup **after** [Hive.init] or
  /// [Hive.initFlutter] has been invoked (typically in `main()`).
  Future<void> init() async {
    await Future.wait([
      Hive.openBox<String>(_boxPorts).then((b) => _portsBox = b),
      Hive.openBox<String>(_boxRestricted).then((b) => _restrictedBox = b),
      Hive.openBox<String>(_boxEnv).then((b) => _envBox = b),
      Hive.openBox<String>(_boxPredictions).then((b) => _predictionsBox = b),
      Hive.openBox<String>(_boxSos).then((b) => _sosBox = b),
      Hive.openBox<dynamic>(_boxMeta).then((b) => _metaBox = b),
      _tileCache.init(),
    ]);
    _initialised = true;
  }

  /// Close all Hive boxes and tile cache gracefully.
  Future<void> dispose() async {
    await Future.wait([
      _portsBox.close(),
      _restrictedBox.close(),
      _envBox.close(),
      _predictionsBox.close(),
      _sosBox.close(),
      _metaBox.close(),
      _tileCache.dispose(),
    ]);
    _initialised = false;
  }

  // ══════════════════════════════════════════════════════════
  //  D O W N L O A D   S E A   P A C K
  // ══════════════════════════════════════════════════════════

  /// Bundle and persist **all** data required for full Sea Mode
  /// functionality offline — including raster map tiles.
  ///
  /// Call this when the user taps **"Download Sea Pack"** while they
  /// still have network connectivity.
  ///
  /// Parameters:
  /// - [predictions]  — ranked fishing zones from the AI model.
  /// - [envData]      — latest environmental snapshot (with suitability).
  /// - [ports]        — port database for navigation & SOS.
  /// - [restricted]   — restricted-zone polygons for geofencing.
  /// - [centerLat/Lon] — centre of the region to tile-cache.
  /// - [tileRadiusKm] — radius around centre to download tiles for
  ///                    (default 200 km, zoom levels 8–13).
  /// - [onTileProgress] — progress callback `(done, total)` for the tile
  ///                      download phase.
  ///
  /// Returns a [SeaPackReceipt] with download metadata.
  Future<SeaPackReceipt> downloadSeaPack({
    required List<FishingZone> predictions,
    required EnvironmentalData envData,
    required List<Port> ports,
    required List<RestrictedZone> restricted,
    double centerLat = 15.0,
    double centerLon = 74.0,
    double tileRadiusKm = 200.0,
    void Function(int done, int total)? onTileProgress,
  }) async {
    final now = DateTime.now();

    // Write data layers + download map tiles in parallel.
    final results = await Future.wait([
      cachePredictions(predictions),
      cacheEnvironmentalData(envData),
      cachePorts(ports),
      cacheRestrictedZones(restricted),
      _tileCache.cacheTilesForRegion(
        lat: centerLat,
        lon: centerLon,
        radiusKm: tileRadiusKm,
        minZoom: 8,
        maxZoom: 13,
        onProgress: onTileProgress,
      ),
    ]);

    final newTiles = results[4] as int;

    // Stamp metadata so the app knows the pack is fresh.
    await _metaBox.put('sea_pack_downloaded_at', now.toIso8601String());
    await _metaBox.put('sea_pack_version', _seaPackVersion);
    await _metaBox.put('sea_pack_zone_count', predictions.length);
    await _metaBox.put('sea_pack_port_count', ports.length);
    await _metaBox.put('sea_pack_restricted_count', restricted.length);
    await _metaBox.put(
        'sea_pack_tile_count', _tileCache.tileCount); // cumulative

    return SeaPackReceipt(
      downloadedAt: now,
      version: _seaPackVersion,
      zoneCount: predictions.length,
      portCount: ports.length,
      restrictedZoneCount: restricted.length,
      newTilesDownloaded: newTiles,
      totalTilesCached: _tileCache.tileCount,
    );
  }

  /// Current schema version for the sea pack.
  static const _seaPackVersion = 1;

  /// Whether a Sea Pack has been downloaded previously.
  bool get hasSeaPack => _metaBox.containsKey('sea_pack_downloaded_at');

  /// When the most recent Sea Pack was saved. `null` if never.
  DateTime? get seaPackDownloadedAt {
    final raw = _metaBox.get('sea_pack_downloaded_at') as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Whether the cached Sea Pack is considered stale (> 24 hours old).
  bool get isSeaPackStale {
    final ts = seaPackDownloadedAt;
    if (ts == null) return true;
    return DateTime.now().difference(ts).inHours >= 24;
  }

  /// Short human-readable summary of the Sea Pack contents.
  String get seaPackSummary {
    if (!hasSeaPack) return 'No Sea Pack downloaded yet.';
    final zones = _metaBox.get('sea_pack_zone_count', defaultValue: 0);
    final ports = _metaBox.get('sea_pack_port_count', defaultValue: 0);
    final restricted =
        _metaBox.get('sea_pack_restricted_count', defaultValue: 0);
    final tiles = _tileCache.tileCount;
    final ts = seaPackDownloadedAt;
    final age =
        ts != null ? DateTime.now().difference(ts) : const Duration(hours: 0);
    final ageLabel =
        age.inHours < 1 ? '${age.inMinutes}m ago' : '${age.inHours}h ago';
    return '$zones zones · $ports ports · $restricted restricted · '
        '$tiles tiles (${_tileCache.cacheSizeLabel}) · $ageLabel';
  }

  /// A [TileProvider] for flutter_map that serves from the local tile
  /// cache when available, and falls back to the network otherwise.
  ///
  /// Pass this to `TileLayer.tileProvider` in the map widget.
  OfflineTileProvider get tileProvider =>
      OfflineTileProvider(cache: _tileCache);

  // ══════════════════════════════════════════════════════════
  //  P O R T S
  // ══════════════════════════════════════════════════════════

  Future<void> cachePorts(List<Port> ports) async {
    final json = jsonEncode(ports.map((p) => p.toJson()).toList());
    await _portsBox.put('data', json);
    await _metaBox.put(
        '${_boxPorts}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  List<Port> getCachedPorts() {
    final raw = _portsBox.get('data');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((j) => Port.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ══════════════════════════════════════════════════════════
  //  R E S T R I C T E D   Z O N E S
  // ══════════════════════════════════════════════════════════

  Future<void> cacheRestrictedZones(List<RestrictedZone> zones) async {
    final json = jsonEncode(zones.map((z) => z.toJson()).toList());
    await _restrictedBox.put('data', json);
    await _metaBox.put(
        '${_boxRestricted}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  List<RestrictedZone> getCachedRestrictedZones() {
    final raw = _restrictedBox.get('data');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((j) => RestrictedZone.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════
  //  E N V I R O N M E N T A L   S N A P S H O T
  // ══════════════════════════════════════════════════════════

  Future<void> cacheEnvironmentalData(EnvironmentalData data) async {
    await _envBox.put('data', jsonEncode(data.toJson()));
    await _metaBox.put('${_boxEnv}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  Future<EnvironmentalData?> getCachedEnvironmentalData() async {
    final raw = _envBox.get('data');
    if (raw == null) return null;
    return EnvironmentalData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ══════════════════════════════════════════════════════════
  //  F I S H I N G   P R E D I C T I O N S
  // ══════════════════════════════════════════════════════════

  Future<void> cachePredictions(List<FishingZone> zones) async {
    final json = jsonEncode(zones.map((z) => z.toJson()).toList());
    await _predictionsBox.put('data', json);
    await _metaBox.put(
        '${_boxPredictions}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<FishingZone>> getCachedPredictions() async {
    final raw = _predictionsBox.get('data');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((j) => FishingZone.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════
  //  P E N D I N G   S O S   Q U E U E
  // ══════════════════════════════════════════════════════════

  Future<void> enqueueSos(Map<String, dynamic> payload) async {
    // Key by timestamp to preserve order and allow iteration.
    final key = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    await _sosBox.put(key, jsonEncode(payload));
  }

  List<Map<String, dynamic>> dequeuePendingSos() {
    final entries = _sosBox.values.toList();
    _sosBox.clear(); // fire-and-forget; Hive.clear() is sync-ish
    return entries.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  /// Number of SOS messages waiting to be sent.
  int get pendingSosCount => _sosBox.length;

  // ══════════════════════════════════════════════════════════
  //  U T I L I T I E S
  // ══════════════════════════════════════════════════════════

  /// Wipe **all** offline caches including the tile cache (e.g. on logout).
  Future<void> clearAll() async {
    await Future.wait([
      _portsBox.clear(),
      _restrictedBox.clear(),
      _envBox.clear(),
      _predictionsBox.clear(),
      _sosBox.clear(),
      _metaBox.clear(),
      _tileCache.clearTiles(),
    ]);
  }

  /// Timestamp of the last cache write for a given box.
  DateTime? lastCacheTime(String boxName) {
    final ts = _metaBox.get('${boxName}_ts') as int?;
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  /// Total approximate size of all cached data (in bytes) including tiles.
  int get estimatedCacheSizeBytes {
    int total = _tileCache.estimatedSizeBytes;
    for (final box in [
      _portsBox,
      _restrictedBox,
      _envBox,
      _predictionsBox,
      _sosBox,
    ]) {
      for (final v in box.values) {
        total += v.length * 2; // ~2 bytes per UTF-16 char
      }
    }
    return total;
  }

  /// Human-readable cache size label (e.g. "1.2 MB").
  String get cacheSizeLabel {
    final bytes = estimatedCacheSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ──────────────────────────────────────────────────────────
//  Sea Pack receipt (returned by downloadSeaPack)
// ──────────────────────────────────────────────────────────

/// Metadata about a completed Sea Pack download.
class SeaPackReceipt {
  /// When the pack was saved to disk.
  final DateTime downloadedAt;

  /// Schema version.
  final int version;

  /// Number of fishing zones stored.
  final int zoneCount;

  /// Number of ports stored.
  final int portCount;

  /// Number of restricted-zone polygons stored.
  final int restrictedZoneCount;

  /// Number of map tiles newly downloaded in this Sea Pack run.
  final int newTilesDownloaded;

  /// Total tiles stored in the local cache (cumulative).
  final int totalTilesCached;

  const SeaPackReceipt({
    required this.downloadedAt,
    required this.version,
    required this.zoneCount,
    required this.portCount,
    required this.restrictedZoneCount,
    this.newTilesDownloaded = 0,
    this.totalTilesCached = 0,
  });

  @override
  String toString() =>
      'SeaPack v$version — $zoneCount zones, $portCount ports, '
      '$restrictedZoneCount restricted zones, '
      '$newTilesDownloaded new tiles ($totalTilesCached total) '
      '(downloaded ${downloadedAt.toIso8601String()})';
}
