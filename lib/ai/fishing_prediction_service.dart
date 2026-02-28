import '../models/fishing_zone.dart';
import '../models/environmental_data.dart';

/// Input parameters for a single candidate fishing zone.
///
/// Passed to [FishingPredictionService.predictZones] which scores and
/// ranks them entirely on-device — **no internet required**.
class ZoneInput {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;

  /// Sea-surface temperature (°C).
  final double sst;

  /// Chlorophyll-a concentration (mg/m³).
  final double chlorophyll;

  /// Salinity (PSU).
  final double salinity;

  /// Historical Catch-Per-Unit-Effort (kg/trip).
  final double cpue;

  /// Optional pre-known fish density (count / km²).
  final double fishDensity;

  /// Current speed in m/s.
  final double currentSpeed;

  /// Species expected in this zone.
  final List<String> expectedSpecies;

  /// Whether a government breeding ban is active.
  final bool isBreedingZone;

  const ZoneInput({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
    required this.sst,
    required this.chlorophyll,
    required this.salinity,
    required this.cpue,
    this.fishDensity = 0,
    this.currentSpeed = 0,
    this.expectedSpecies = const [],
    this.isBreedingZone = false,
  });
}

/// Pure, offline fishing-zone prediction service.
///
/// Accepts SST, Chlorophyll, Salinity, and CPUE for each candidate zone,
/// computes a **fish_activity_score** via [FishingZone.computeFishActivityScore],
/// and returns the zones ranked from best to worst.
///
/// Reusable in both **Sea Mode** and **Home Mode** — call [predictZones]
/// from either screen with the same inputs.
class FishingPredictionService {
  /// Cached result of the last prediction run.
  List<FishingZone> _cachedZones = [];

  /// Most recent ranked zones (useful for widgets that read synchronously).
  List<FishingZone> get cachedZones => List.unmodifiable(_cachedZones);

  // ──────────────────────────────────────
  //  Core prediction (offline, pure)
  // ──────────────────────────────────────

  /// Score and rank a list of candidate zones.
  ///
  /// Each [ZoneInput] is scored with [FishingZone.computeFishActivityScore]
  /// and wrapped into a [FishingZone].  The returned list is sorted by
  /// `fishActivityScore` descending (best zone first).
  ///
  /// When [environmentalSuitability] is provided (0–100), it acts as a
  /// confidence modifier — zones in a highly suitable environment get a
  /// boosted `predictionConfidence`.
  ///
  /// Zones where `isBreedingZone == true` are kept in the list but flagged
  /// with `isFishingAllowed = false` so the UI can grey them out.
  ///
  /// This method is **synchronous** and does **not** use the network.
  List<FishingZone> predictZones(
    List<ZoneInput> inputs, {
    double? environmentalSuitability,
  }) {
    final now = DateTime.now();
    final season = _currentSeason();

    final zones = inputs.map((z) {
      final score = FishingZone.computeFishActivityScore(
        sst: z.sst,
        chlorophyll: z.chlorophyll,
        salinity: z.salinity,
        cpue: z.cpue,
      );

      // Derive a confidence value blending the activity score with the
      // optional environmental suitability (0–100).  If suitability is
      // provided we average the two; otherwise fall back to activity alone.
      final rawConfidence = score / 100;
      final confidence = environmentalSuitability != null
          ? double.parse(
              ((rawConfidence + environmentalSuitability / 100) / 2)
                  .clamp(0, 1)
                  .toStringAsFixed(2))
          : double.parse(
              rawConfidence.clamp(0, 1).toStringAsFixed(2));

      return FishingZone(
        id: z.id,
        name: z.name,
        latitude: z.latitude,
        longitude: z.longitude,
        radiusKm: z.radiusKm,
        fishDensity: z.fishDensity > 0 ? z.fishDensity : score * 0.6,
        sst: z.sst,
        chlorophyll: z.chlorophyll,
        salinity: z.salinity,
        cpue: z.cpue,
        fishActivityScore: score,
        currentSpeed: z.currentSpeed,
        expectedSpecies: z.expectedSpecies,
        season: season,
        predictionConfidence: confidence,
        isBreedingZone: z.isBreedingZone,
        isFishingAllowed: !z.isBreedingZone,
        lastUpdated: now,
      );
    }).toList();

    // Sort descending by fish activity score.
    zones.sort((a, b) => b.fishActivityScore.compareTo(a.fishActivityScore));

    _cachedZones = zones;
    return zones;
  }

  // ──────────────────────────────────────
  //  Convenience: predict from EnvironmentalData
  // ──────────────────────────────────────

  /// Shorthand that builds a single-zone prediction from live or cached
  /// [EnvironmentalData] at the given position.
  ///
  /// If [env] already contains an [EnvironmentalData.environmentalSuitabilityScore],
  /// it is forwarded to [predictZones] as a confidence modifier.
  ///
  /// Useful on the Home Screen where there is no pre-built zone catalogue.
  List<FishingZone> predictFromEnvironment({
    required EnvironmentalData env,
    required double latitude,
    required double longitude,
    String name = 'Current Location',
  }) {
    return predictZones(
      [
        ZoneInput(
          id: 'env-live',
          name: name,
          latitude: latitude,
          longitude: longitude,
          sst: env.seaSurfaceTemperature,
          chlorophyll: env.chlorophyll ?? 1.0,
          salinity: env.salinity ?? 35.0,
          cpue: 40, // regional average fallback
        ),
      ],
      environmentalSuitability: env.environmentalSuitabilityScore,
    );
  }

  // ──────────────────────────────────────
  //  Advisory (offline fallback)
  // ──────────────────────────────────────

  /// Returns a deterministic, offline advisory based on the risk assessment
  /// and fish-activity score. No network calls.
  Map<String, String> getOfflineAdvisory({
    required EnvironmentalData env,
    double? fishActivityScore,
  }) {
    final activityTag = fishActivityScore != null
        ? (fishActivityScore >= 75
            ? 'Excellent'
            : fishActivityScore >= 50
                ? 'Good'
                : fishActivityScore >= 25
                    ? 'Fair'
                    : 'Poor')
        : 'Unknown';

    return {
      'english':
          'Risk: ${env.risk.level.name}. ${env.risk.description} '
          'Fish activity: $activityTag.',
      'marathi':
          'जोखीम: ${env.risk.level.name}. '
          'मासेमारी क्रियाकलाप: $activityTag.',
      'sustainability_tip':
          'Use sustainable nets and follow local fishing regulations.',
    };
  }

  // ──────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────

  String _currentSeason() {
    final month = DateTime.now().month;
    if (month >= 6 && month <= 9) return 'monsoon';
    if (month >= 10 || month <= 1) return 'post-monsoon';
    return 'pre-monsoon';
  }
}
