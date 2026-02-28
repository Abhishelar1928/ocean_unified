import '../models/environmental_data.dart';
import '../models/fishing_zone.dart';
import '../services/offline_data_service.dart';
import 'environmental_model_service.dart';
import 'fishing_prediction_service.dart';

// ──────────────────────────────────────────────────────────
//  MarineIntelligenceResult
// ──────────────────────────────────────────────────────────

/// Encapsulates the unified output of [MarineIntelligenceService.assess].
class MarineIntelligenceResult {
  /// All candidate zones ranked by [finalScore] (best first).
  final List<ScoredZone> rankedZones;

  /// The single best fishing zone (highest [finalScore]),
  /// or `null` when no zones are available / all are banned.
  final ScoredZone? bestZone;

  /// Risk classification for the current location.
  final RiskAssessment risk;

  /// Environmental suitability score (0–100) used in the formula.
  final double environmentalScore;

  /// Enriched environmental data (includes suitability score).
  final EnvironmentalData environmentalData;

  /// Short advisory string derived from the composite analysis.
  final String advisory;

  const MarineIntelligenceResult({
    required this.rankedZones,
    required this.bestZone,
    required this.risk,
    required this.environmentalScore,
    required this.environmentalData,
    required this.advisory,
  });

  Map<String, dynamic> toJson() => {
        'best_zone': bestZone?.toJson(),
        'risk': risk.toJson(),
        'environmental_score': environmentalScore,
        'advisory': advisory,
        'ranked_zones': rankedZones.map((z) => z.toJson()).toList(),
      };
}

/// A [FishingZone] decorated with the unified **final_score**.
class ScoredZone {
  final FishingZone zone;

  /// Composite score computed via:
  ///   `final_score = 0.5 × fish_score + 0.3 × env_score − 0.2 × risk_score`
  ///
  /// Clamped to [0, 100].
  final double finalScore;

  /// Human-readable label derived from [finalScore].
  String get label {
    if (finalScore >= 70) return 'Highly Recommended';
    if (finalScore >= 45) return 'Recommended';
    if (finalScore >= 20) return 'Marginal';
    return 'Not Recommended';
  }

  const ScoredZone({required this.zone, required this.finalScore});

  Map<String, dynamic> toJson() => {
        ...zone.toJson(),
        'final_score': finalScore,
        'label': label,
      };
}

// ──────────────────────────────────────────────────────────
//  MarineIntelligenceService
// ──────────────────────────────────────────────────────────

/// Unified intelligence layer that **combines**:
///   • [FishingPredictionService]  → fish_activity_score (0–100)
///   • [EnvironmentalModelService] → environmental_suitability_score (0–100)
///   • [RiskAssessment]            → risk_score (0–100+, lower = safer)
///
/// into a single **final_score** per zone:
///
/// ```
/// final_score = (0.5 × fish_score) + (0.3 × env_score) − (0.2 × risk_score)
/// ```
///
/// The service is fully **offline-capable**: it delegates to the existing
/// services which already cache results locally via [OfflineDataService].
class MarineIntelligenceService {
  final EnvironmentalModelService _envService;
  final FishingPredictionService _fishService;
  final OfflineDataService _offlineData;

  /// Last computed result (synchronous read for widgets).
  MarineIntelligenceResult? _cachedResult;
  MarineIntelligenceResult? get cachedResult => _cachedResult;

  MarineIntelligenceService({
    required EnvironmentalModelService envService,
    required FishingPredictionService fishService,
    required OfflineDataService offlineData,
  })  : _envService = envService,
        _fishService = fishService,
        _offlineData = offlineData;

  // ──────────────────────────────────────
  //  Full pipeline (live → score → cache)
  // ──────────────────────────────────────

  /// Fetch live conditions → evaluate suitability → predict zones →
  /// compute unified final_score → cache everything → return result.
  ///
  /// Falls back to cached data on network failure.
  Future<MarineIntelligenceResult> assess({
    required double lat,
    required double lon,
  }) async {
    try {
      // 1. Fetch + evaluate + predict via EnvironmentalModelService
      final pipeline = await _envService.fetchEvaluateAndPredict(
        lat: lat,
        lon: lon,
      );

      return _buildResult(
        envData: pipeline.env,
        zones: pipeline.zones,
      );
    } catch (_) {
      // Offline fallback
      final cachedEnv = await _offlineData.getCachedEnvironmentalData();
      final cachedZones = await _offlineData.getCachedPredictions();

      if (cachedEnv != null) {
        return _buildResult(
          envData: cachedEnv,
          zones: cachedZones,
        );
      }
      rethrow;
    }
  }

  /// Assess using pre-fetched [EnvironmentalData] (useful when data
  /// was already fetched elsewhere).  Pure + offline.
  Future<MarineIntelligenceResult> assessFromData({
    required EnvironmentalData envData,
    required double lat,
    required double lon,
  }) async {
    // Ensure suitability score exists
    final enriched = envData.environmentalSuitabilityScore != null
        ? envData
        : await _envService.evaluateEnvironment(envData);

    final zones = _fishService.predictFromEnvironment(
      env: enriched,
      latitude: lat,
      longitude: lon,
    );

    await _offlineData.cachePredictions(zones);

    return _buildResult(envData: enriched, zones: zones);
  }

  /// Assess a custom list of [ZoneInput]s against the given environment.
  Future<MarineIntelligenceResult> assessZones({
    required EnvironmentalData envData,
    required List<ZoneInput> zoneInputs,
  }) async {
    final enriched = envData.environmentalSuitabilityScore != null
        ? envData
        : await _envService.evaluateEnvironment(envData);

    final zones = _fishService.predictZones(
      zoneInputs,
      environmentalSuitability: enriched.environmentalSuitabilityScore,
    );

    await _offlineData.cachePredictions(zones);

    return _buildResult(envData: enriched, zones: zones);
  }

  // ──────────────────────────────────────
  //  Core formula
  // ──────────────────────────────────────

  /// Computes the unified final_score for a single zone.
  ///
  /// ```
  /// final_score = (0.5 × fish_score) + (0.3 × env_score) − (0.2 × risk_score)
  /// ```
  ///
  /// The risk_score is normalised to 0–100 (capped at 100) before use.
  /// Result is clamped to [0, 100].
  static double computeFinalScore({
    required double fishActivityScore,
    required double environmentalScore,
    required double riskScore,
  }) {
    // Normalise risk to 0–100 range (the raw score can exceed 100).
    final normalisedRisk = riskScore.clamp(0, 100);

    final raw = (0.5 * fishActivityScore) +
        (0.3 * environmentalScore) -
        (0.2 * normalisedRisk);

    return double.parse(raw.clamp(0, 100).toStringAsFixed(2));
  }

  // ──────────────────────────────────────
  //  Internal builder
  // ──────────────────────────────────────

  MarineIntelligenceResult _buildResult({
    required EnvironmentalData envData,
    required List<FishingZone> zones,
  }) {
    final envScore = envData.environmentalSuitabilityScore ?? 0.0;
    final riskScore = envData.risk.score;

    // Score each zone
    final scored = zones.map((z) {
      final fs = computeFinalScore(
        fishActivityScore: z.fishActivityScore,
        environmentalScore: envScore,
        riskScore: riskScore,
      );
      return ScoredZone(zone: z, finalScore: fs);
    }).toList();

    // Sort by final_score descending
    scored.sort((a, b) => b.finalScore.compareTo(a.finalScore));

    // Best zone = highest final_score among allowed zones, or overall best
    final allowedZones = scored.where((s) => s.zone.isFishingAllowed);
    final best = allowedZones.isNotEmpty ? allowedZones.first : null;

    final advisory = _generateAdvisory(
      best: best,
      risk: envData.risk,
      envScore: envScore,
    );

    final result = MarineIntelligenceResult(
      rankedZones: scored,
      bestZone: best,
      risk: envData.risk,
      environmentalScore: envScore,
      environmentalData: envData,
      advisory: advisory,
    );

    _cachedResult = result;
    return result;
  }

  // ──────────────────────────────────────
  //  Advisory generation (offline)
  // ──────────────────────────────────────

  String _generateAdvisory({
    ScoredZone? best,
    required RiskAssessment risk,
    required double envScore,
  }) {
    final buf = StringBuffer();

    // Risk warning
    switch (risk.level) {
      case RiskLevel.high:
        buf.write(
            '⚠ DANGER: ${risk.description} Do NOT venture out. ');
        break;
      case RiskLevel.moderate:
        buf.write(
            '⚡ CAUTION: ${risk.description} ');
        break;
      case RiskLevel.safe:
        buf.write(
            '✓ Sea conditions are safe. ');
        break;
    }

    // Environmental quality
    if (envScore >= 70) {
      buf.write('Environmental conditions are excellent for fishing. ');
    } else if (envScore >= 40) {
      buf.write('Environmental conditions are moderate. ');
    } else {
      buf.write('Environmental conditions are poor — limited catch expected. ');
    }

    // Best zone recommendation
    if (best != null && risk.level != RiskLevel.high) {
      buf.write(
          'Best zone: ${best.zone.name} '
          '(score ${best.finalScore.toStringAsFixed(1)}, '
          '${best.label}).');
    } else if (risk.level == RiskLevel.high) {
      buf.write('Stay onshore until conditions improve.');
    } else {
      buf.write('No recommended zones at this time.');
    }

    return buf.toString();
  }
}
