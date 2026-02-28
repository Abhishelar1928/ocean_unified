import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'tile_cache_service.dart';

/// A flutter_map [TileProvider] that serves tiles from the local
/// [TileCacheService] when available, and falls back to the network
/// (OSM) when not cached, automatically storing newly fetched tiles for
/// future offline use.
///
/// ### Usage
///
/// ```dart
/// TileLayer(
///   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
///   tileProvider: OfflineTileProvider(cache: tileCacheService),
/// )
/// ```
class OfflineTileProvider extends TileProvider {
  final TileCacheService cache;

  OfflineTileProvider({required this.cache});

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    final z = coordinates.z;
    final x = coordinates.x;
    final y = coordinates.y;

    // ── Offline path: serve instantly from Hive ──
    final cached = cache.getTileSync(z, x, y);
    if (cached != null) {
      return MemoryImage(cached);
    }

    // ── Online path: fetch, render, and cache for next time ──
    final url = getTileUrl(coordinates, options);
    return _NetworkCachingImageProvider(
      url: url,
      z: z,
      x: x,
      y: y,
      cache: cache,
      extraHeaders: headers,
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Internal ImageProvider: fetches tile from network and
//  writes bytes to [TileCacheService] asynchronously.
// ════════════════════════════════════════════════════════════

class _NetworkCachingImageProvider
    extends ImageProvider<_NetworkCachingImageProvider> {
  final String url;
  final int z, x, y;
  final TileCacheService cache;
  final Map<String, String> extraHeaders;

  const _NetworkCachingImageProvider({
    required this.url,
    required this.z,
    required this.x,
    required this.y,
    required this.cache,
    this.extraHeaders = const {},
  });

  // ── ImageProvider lifecycle ─────────────────────────────

  @override
  Future<_NetworkCachingImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _NetworkCachingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _fetchDecode(decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  // ── Fetch → cache → decode ──────────────────────────────

  Future<ui.Codec> _fetchDecode(ImageDecoderCallback decode) async {
    Uint8List? bytes;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FishermanEduSea/1.0',
          ...extraHeaders,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
        // Fire-and-forget cache write — does not block painting.
        unawaited(cache.putTile(z, x, y, bytes));
      }
    } catch (_) {
      // Network error or timeout — fall through to transparent fallback.
    }

    final tileBytes = bytes ?? _kTransparentTile;
    final buffer = await ui.ImmutableBuffer.fromUint8List(tileBytes);
    return decode(buffer);
  }

  // ── Equality ────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      other is _NetworkCachingImageProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

// ── 1×1 transparent RGBA PNG fallback (68 bytes) ────────────
//
// Returned when a tile cannot be fetched (no network, server error).
// Prevents the TileLayer from crashing or showing broken-image icons.
// -------------------------------------------------------------------
final _kTransparentTile = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1×1 px
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // RGBA, CRC
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT length + type
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00, // deflate stream
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, // CRC
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND
  0x42, 0x60, 0x82, //
]);
