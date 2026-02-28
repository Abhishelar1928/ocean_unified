import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/learning_article.dart';
import '../models/government_scheme.dart';

/// Provides offline-first access to [LearningArticle]s and
/// [GovernmentScheme]s.
///
/// ### Storage strategy
///
/// | Layer | Data | Persistence |
/// |-------|------|-------------|
/// | Compile-time constants | [builtinArticles] (10 curated articles) | Always available — no network, no Hive |
/// | Hive box (`learning_saved_articles`) | User-saved / custom articles | Survives app restart |
/// | Compile-time constants | [governmentSchemes] (12 schemes) | Always available — no network, no Hive |
///
/// ### Lifecycle
///
/// ```dart
/// final svc = LearningService();
/// await svc.init();          // open Hive box
/// final articles = svc.articles;
/// final results  = svc.searchArticles('wave height');
/// await svc.close();         // call in dispose()
/// ```
class LearningService {
  // ── Hive box name ──────────────────────────────────────
  static const _boxName = 'learning_saved_articles';

  Box<String>? _box;

  // ── Lifecycle ──────────────────────────────────────────

  /// Opens the Hive box that persists custom/saved articles.
  ///
  /// Must be called **after** [Hive.initFlutter] (already done in `main()`).
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Closes the Hive box.  Call from your widget's [dispose].
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  // ── Articles ───────────────────────────────────────────

  /// All built-in articles (always available offline).
  List<LearningArticle> get builtinArticleList =>
      List.unmodifiable(builtinArticles);

  /// Custom articles previously saved via [saveArticle].
  List<LearningArticle> get savedArticles {
    final box = _box;
    if (box == null || !box.isOpen) return const [];
    return box.values
        .map((json) {
          try {
            return LearningArticle.fromJson(
                jsonDecode(json) as Map<String, dynamic>);
          } catch (_) {
            return null; // skip corrupted entries
          }
        })
        .whereType<LearningArticle>()
        .toList();
  }

  /// Combined list: built-in articles first, then any user-saved articles.
  ///
  /// Fully available offline — this is the primary data accessor.
  List<LearningArticle> get articles => [
        ...builtinArticles,
        ...savedArticles,
      ];

  // ── Government schemes ─────────────────────────────────

  /// All government welfare schemes.
  ///
  /// Data is compiled in [governmentSchemes] — no network or Hive needed.
  List<GovernmentScheme> get schemes => List.unmodifiable(governmentSchemes);

  /// Schemes filtered by [category].  Pass `null` to get all.
  List<GovernmentScheme> schemesByCategory(SchemeCategory? category) {
    if (category == null) return schemes;
    return governmentSchemes.where((s) => s.category == category).toList();
  }

  // ── Search ─────────────────────────────────────────────

  /// Returns articles whose [LearningArticle.title], [LearningArticle.summary],
  /// [LearningArticle.body], or [LearningArticle.tags] contain [query]
  /// (case-insensitive).
  ///
  /// Returns all articles when [query] is blank.
  ///
  /// ```dart
  /// final waveArticles = svc.searchArticles('wave height');
  /// ```
  List<LearningArticle> searchArticles(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return articles;

    return articles.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q) ||
          a.body.toLowerCase().contains(q) ||
          a.tags.any((t) => t.toLowerCase().contains(q)) ||
          a.category.label.toLowerCase().contains(q);
    }).toList();
  }

  /// Returns schemes whose name, description, ministry, eligibility,
  /// benefits, or category label contain [query] (case-insensitive).
  ///
  /// Returns all schemes when [query] is blank.
  List<GovernmentScheme> searchSchemes(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return schemes;

    return governmentSchemes.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q) ||
          s.ministry.toLowerCase().contains(q) ||
          s.eligibility.toLowerCase().contains(q) ||
          s.category.label.toLowerCase().contains(q) ||
          s.benefits.any((b) => b.toLowerCase().contains(q));
    }).toList();
  }

  // ── Persistence helpers ────────────────────────────────

  /// Persists [article] to the Hive box under its [LearningArticle.id].
  ///
  /// If an article with the same id already exists it is overwritten.
  /// [init] must be called first.
  Future<void> saveArticle(LearningArticle article) async {
    _assertInitialised();
    await _box!.put(article.id, jsonEncode(article.toJson()));
  }

  /// Removes the article with [id] from the Hive box.
  ///
  /// No-op if the id is not found.  [init] must be called first.
  Future<void> deleteArticle(String id) async {
    _assertInitialised();
    await _box!.delete(id);
  }

  /// Returns `true` if an article with [id] has been saved to Hive.
  bool isSaved(String id) {
    if (_box == null || !_box!.isOpen) return false;
    return _box!.containsKey(id);
  }

  // ── Internal helpers ───────────────────────────────────

  void _assertInitialised() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'LearningService.init() must be called before accessing Hive storage.',
      );
    }
  }
}
