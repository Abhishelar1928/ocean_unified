import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// Manages offline caching of raster map tiles (OSM / XYZ scheme).
///
/// ### Storage
/// Tiles are stored in a Hive `Box<String>` as base64-encoded PNG/JPEG bytes.
/// The box key is `'z/x/y'` — e.g. `'12/3456/1980'`.
///
/// ### Typical flow
///
/// **While online (Sea Pack download):**
/// ```dart
/// final svc = TileCacheService();
/// await svc.init();
/// await svc.cacheTilesForRegion(
///   lat: 18.9, lon: 72.8,   // Mumbai coast
///   radiusKm: 150,
///   minZoom: 8, maxZoom: 13,
///   onProgress: (done, total) => print('$done/$total'),
/// );
/// ```
///
/// **While offline (custom TileProvider reads tiles):**
/// ```dart
/// final bytes = svc.getTileSync(12, 3456, 1980);
/// if (bytes != null) return MemoryImage(bytes);
/// ```
class TileCacheService {
  static const _boxName = 'tile_cache';

  // OSM tile server (same as the live TileLayer template)
  static const _tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  Box<String>? _box;

  // ── Lifecycle ─────────────────────────────────────────

  /// Open the Hive tile-cache box.
  ///
  /// Must be called **after** `Hive.initFlutter()`.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Close the Hive box. Call this in `dispose()`.
  Future<void> dispose() async {
    await _box?.close();
    _box = null;
  }

  // ── Read / Write ──────────────────────────────────────

  /// Returns the cached tile bytes for `(z, x, y)`, or `null` if not cached.
  ///
  /// This is **synchronous** — Hive keeps the box in memory once opened,
  /// so reads do not block the UI.
  Uint8List? getTileSync(int z, int x, int y) {
    final raw = _box?.get(_key(z, x, y));
    if (raw == null) return null;
    return base64Decode(raw);
  }

  /// Returns `true` if the tile `(z, x, y)` is cached locally.
  bool hasTile(int z, int x, int y) =>
      _box?.containsKey(_key(z, x, y)) ?? false;

  /// Stores [bytes] for tile `(z, x, y)`.
  Future<void> putTile(int z, int x, int y, Uint8List bytes) async {
    await _box?.put(_key(z, x, y), base64Encode(bytes));
  }

  // ── Region download ───────────────────────────────────

  /// Downloads and caches every tile within [radiusKm] of [lat]/[lon] for
  /// all zoom levels in `[minZoom, maxZoom]`.
  ///
  /// [onProgress] is called after each successful tile fetch with
  /// `(tilesCompleted, totalTiles)` so the caller can update a progress bar.
  ///
  /// Skips tiles that are already cached to allow incremental/resumable
  /// downloads.
  ///
  /// Returns the number of newly downloaded tiles.
  Future<int> cacheTilesForRegion({
    required double lat,
    required double lon,
    required double radiusKm,
    int minZoom = 8,
    int maxZoom = 13,
    void Function(int done, int total)? onProgress,
    http.Client? httpClient,
  }) async {
    _assertInitialised();

    final client = httpClient ?? http.Client();
    bool ownsClient = httpClient == null;

    try {
      // Collect all tile coordinates for the requested region.
      final coords = <({int z, int x, int y})>[];
      for (int z = minZoom; z <= maxZoom; z++) {
        coords.addAll(_tilesForRadius(lat, lon, radiusKm, z));
      }

      int done = 0;
      int downloaded = 0;
      final total = coords.length;

      for (final c in coords) {
        // Skip tiles already cached (allows resumable downloads).
        if (!hasTile(c.z, c.x, c.y)) {
          final bytes = await _fetchTile(c.z, c.x, c.y, client);
          if (bytes != null) {
            await putTile(c.z, c.x, c.y, bytes);
            downloaded++;
          }
        }
        done++;
        onProgress?.call(done, total);
      }

      return downloaded;
    } finally {
      if (ownsClient) client.close();
    }
  }

  // ── Cache stats ───────────────────────────────────────

  /// Total number of tiles currently cached.
  int get tileCount => _box?.length ?? 0;

  /// Estimated storage used by the tile cache (bytes).
  ///
  /// Each Hive value is a base64 string; actual PNG/JPEG bytes are
  /// ~75 % of the base64 length.
  int get estimatedSizeBytes {
    final box = _box;
    if (box == null) return 0;
    int total = 0;
    for (final v in box.values) {
      total += (v.length * 3) ~/ 4; // base64 → raw byte estimate
    }
    return total;
  }

  /// Human-readable estimated size label (e.g. `"8.3 MB"`).
  String get cacheSizeLabel {
    final b = estimatedSizeBytes;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Clear ─────────────────────────────────────────────

  /// Delete all cached tiles.
  Future<void> clearTiles() async {
    await _box?.clear();
  }

  // ── Tile coordinate math ──────────────────────────────

  /// OSM tile key: `'z/x/y'`.
  static String _key(int z, int x, int y) => '$z/$x/$y';

  /// Convert degrees to OSM tile column `x` at [zoom].
  static int _lonToTileX(double lon, int zoom) {
    final n = 1 << zoom;
    return ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
  }

  /// Convert degrees to OSM tile row `y` at [zoom].
  static int _latToTileY(double lat, int zoom) {
    final n = 1 << zoom;
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            n)
        .floor()
        .clamp(0, n - 1);
  }

  /// All tile `(z, x, y)` records within [radiusKm] of [lat]/[lon] at [zoom].
  static List<({int z, int x, int y})> _tilesForRadius(
    double lat,
    double lon,
    double radiusKm,
    int zoom,
  ) {
    // Approximate lat/lon deltas for the given radius.
    final latDelta = radiusKm / 111.0;
    final lonDelta = radiusKm / (111.0 * math.cos(lat * math.pi / 180.0));

    final xMin = _lonToTileX(lon - lonDelta, zoom);
    final xMax = _lonToTileX(lon + lonDelta, zoom);
    final yMin = _latToTileY(lat + latDelta, zoom); // note: y flipped
    final yMax = _latToTileY(lat - latDelta, zoom);

    final result = <({int z, int x, int y})>[];
    for (int x = xMin; x <= xMax; x++) {
      for (int y = yMin; y <= yMax; y++) {
        result.add((z: zoom, x: x, y: y));
      }
    }
    return result;
  }

  /// Build the tile HTTP URL from the template.
  static String _buildUrl(int z, int x, int y) => _tileUrlTemplate
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');

  // ── HTTP fetch ────────────────────────────────────────

  /// Fetch a single tile from the network. Returns `null` on failure.
  static Future<Uint8List?> _fetchTile(
    int z,
    int x,
    int y,
    http.Client client,
  ) async {
    final url = _buildUrl(z, x, y);
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'FishermanEduSea/1.0 (offline tile cache; contact@edusea.app)',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {
      // Network error — return null so the caller skips this tile.
    }
    return null;
  }

  // ── Guard ─────────────────────────────────────────────

  void _assertInitialised() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'TileCacheService.init() must be called before caching tiles.',
      );
    }
  }
}
