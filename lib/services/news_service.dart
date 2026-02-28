import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════
//  MarineNewsArticle model
// ══════════════════════════════════════════════════════════

/// A single marine / fisheries news article.
class MarineNewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String source;
  final String? url;
  final DateTime publishedAt;
  final List<String> tags;

  const MarineNewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.source,
    this.url,
    required this.publishedAt,
    this.tags = const [],
  });

  factory MarineNewsArticle.fromJson(Map<String, dynamic> json) {
    return MarineNewsArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      source: json['source'] as String? ?? 'Unknown',
      url: json['url'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'image_url': imageUrl,
        'source': source,
        'url': url,
        'published_at': publishedAt.toIso8601String(),
        'tags': tags,
      };
}

// ══════════════════════════════════════════════════════════
//  NewsService
// ══════════════════════════════════════════════════════════

/// Fetches and caches marine / fisheries news.
///
/// **Online** → hits the backend mock API, caches results locally in Hive.
/// **Offline** → returns previously cached articles.
///
/// All data is stored as JSON strings in a single Hive `Box<String>`.
class NewsService {
  final String backendUrl;

  static const _boxName = 'offline_news';
  static const _dataKey = 'articles';
  static const _timestampKey = 'fetched_at';

  Box<String>? _box;

  NewsService({required this.backendUrl});

  // ──────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────

  /// Open the Hive box. Call once at startup (after `Hive.initFlutter()`).
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Close the Hive box gracefully.
  Future<void> dispose() async {
    await _box?.close();
  }

  // ──────────────────────────────────────
  //  Public API
  // ──────────────────────────────────────

  /// Fetch the latest marine news.
  ///
  /// Tries the network first; on failure returns cached articles.
  /// If nothing is cached either, returns built-in fallback headlines.
  Future<List<MarineNewsArticle>> fetchNews() async {
    try {
      final articles = await _fetchFromApi();
      await _cacheArticles(articles);
      return articles;
    } catch (_) {
      // Network unavailable — try local cache
      final cached = getCachedNews();
      if (cached.isNotEmpty) return cached;

      // Last resort — built-in mock headlines (always offline)
      return _fallbackArticles();
    }
  }

  /// Returns locally cached news (synchronous, works offline).
  List<MarineNewsArticle> getCachedNews() {
    final raw = _box?.get(_dataKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((j) => MarineNewsArticle.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// When the cache was last refreshed, or `null` if never.
  DateTime? get lastFetchedAt {
    final raw = _box?.get(_timestampKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Whether cached news is older than [maxAge] (default 6 hours).
  bool isCacheStale({Duration maxAge = const Duration(hours: 6)}) {
    final ts = lastFetchedAt;
    if (ts == null) return true;
    return DateTime.now().difference(ts) > maxAge;
  }

  // ──────────────────────────────────────
  //  Network fetch
  // ──────────────────────────────────────

  Future<List<MarineNewsArticle>> _fetchFromApi() async {
    final uri = Uri.parse('$backendUrl/api/news');
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      final list = (body is List ? body : body['articles'] as List?) ?? [];
      return list
          .map((j) => MarineNewsArticle.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('News API returned ${response.statusCode}');
  }

  // ──────────────────────────────────────
  //  Local cache (Hive)
  // ──────────────────────────────────────

  Future<void> _cacheArticles(List<MarineNewsArticle> articles) async {
    final json = jsonEncode(articles.map((a) => a.toJson()).toList());
    await _box?.put(_dataKey, json);
    await _box?.put(_timestampKey, DateTime.now().toIso8601String());
  }

  // ──────────────────────────────────────
  //  Built-in fallback (always offline)
  // ──────────────────────────────────────

  static List<MarineNewsArticle> _fallbackArticles() {
    final now = DateTime.now();
    return [
      MarineNewsArticle(
        id: 'fallback_1',
        title: 'INCOIS Issues Potential Fishing Zone Advisory for Feb 2026',
        summary:
            'The Indian National Centre for Ocean Information Sciences has '
            'released updated PFZ maps highlighting productive zones off '
            'the Kerala and Karnataka coasts due to favourable upwelling.',
        source: 'INCOIS',
        publishedAt: now.subtract(const Duration(hours: 4)),
        tags: ['PFZ', 'advisory', 'Kerala', 'Karnataka'],
      ),
      MarineNewsArticle(
        id: 'fallback_2',
        title: 'Cyclone Watch: IMD Monitors Low-Pressure System in Bay of Bengal',
        summary:
            'The India Meteorological Department is tracking a low-pressure '
            'area over the central Bay of Bengal. Fishermen along the '
            'Andhra Pradesh and Odisha coasts are advised not to venture out.',
        source: 'IMD',
        publishedAt: now.subtract(const Duration(hours: 8)),
        tags: ['cyclone', 'safety', 'Bay of Bengal'],
      ),
      MarineNewsArticle(
        id: 'fallback_3',
        title: 'PMMSY Subsidy Portal Opens New Registration Window',
        summary:
            'The Pradhan Mantri Matsya Sampada Yojana portal has opened a '
            'fresh registration window for vessel modernisation subsidies. '
            'Eligible fishermen can apply until March 31, 2026.',
        source: 'Ministry of Fisheries',
        publishedAt: now.subtract(const Duration(days: 1)),
        tags: ['PMMSY', 'subsidy', 'government'],
      ),
      MarineNewsArticle(
        id: 'fallback_4',
        title: 'Record Sardine Catch Reported off Kochi Coast',
        summary:
            'Fishermen operating from Kochi harbour have reported the '
            'highest sardine (Sardinella longiceps) landings in five years, '
            'attributed to favourable SST and chlorophyll conditions.',
        source: 'CMFRI',
        publishedAt: now.subtract(const Duration(days: 2)),
        tags: ['sardine', 'catch', 'Kochi', 'CMFRI'],
      ),
      MarineNewsArticle(
        id: 'fallback_5',
        title: 'NAVIC-Enabled Safety Devices Now Mandatory for Deep-Sea Vessels',
        summary:
            'Starting April 2026, all mechanised fishing vessels venturing '
            'beyond 12 nautical miles must carry an ISRO NAVIC-based '
            'transponder for real-time tracking and distress signalling.',
        source: 'DG Shipping',
        publishedAt: now.subtract(const Duration(days: 3)),
        tags: ['NAVIC', 'safety', 'regulation'],
      ),
      MarineNewsArticle(
        id: 'fallback_6',
        title: 'Annual Monsoon Fishing Ban Dates Announced for 2026',
        summary:
            'The Ministry of Fisheries has confirmed the 47-day monsoon '
            'fishing ban from June 15 to August 1, 2026 for the west coast '
            'and June 15 to July 31 for the east coast.',
        source: 'Ministry of Fisheries',
        publishedAt: now.subtract(const Duration(days: 4)),
        tags: ['ban', 'monsoon', 'regulation'],
      ),
    ];
  }
}
