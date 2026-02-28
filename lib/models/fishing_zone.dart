import 'dart:math';

/// Represents a fishing zone with environmental & prediction data.
///
/// Used by [FishingPredictionService] to recommend optimal fishing locations,
/// and rendered on the map in [SeaModeScreen].
class FishingZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;

  /// Predicted fish density (count / km²) from the AI model.
  final double fishDensity;

  /// Sea-surface temperature in °C.
  final double sst;

  /// Chlorophyll-a concentration (mg/m³) — proxy for productivity.
  final double chlorophyll;

  /// Salinity in PSU.
  final double salinity;

  /// Historical Catch-Per-Unit-Effort (kg/trip).
  final double cpue;

  /// Composite fish-activity score (0–100) computed from SST, chlorophyll,
  /// salinity, and CPUE.  Higher = better fishing potential.
  final double fishActivityScore;

  /// Current speed in m/s.
  final double currentSpeed;

  /// List of primary species expected in this zone.
  final List<String> expectedSpecies;

  /// Season tag (e.g. "monsoon", "post-monsoon", "pre-monsoon").
  final String season;

  /// AI confidence score 0–1 for the fish-density prediction.
  final double predictionConfidence;

  /// Whether the zone overlaps a government-declared breeding area.
  final bool isBreedingZone;

  /// Whether fishing is currently allowed (false during breeding bans).
  final bool isFishingAllowed;

  /// Timestamp of the last data refresh (ISO-8601).
  final DateTime lastUpdated;

  const FishingZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.fishDensity,
    required this.sst,
    required this.chlorophyll,
    required this.salinity,
    required this.cpue,
    required this.fishActivityScore,
    required this.currentSpeed,
    required this.expectedSpecies,
    required this.season,
    required this.predictionConfidence,
    this.isBreedingZone = false,
    this.isFishingAllowed = true,
    required this.lastUpdated,
  });

  /// Deserialise from a JSON map (e.g. API response / local cache).
  factory FishingZone.fromJson(Map<String, dynamic> json) {
    final sst = (json['sst'] as num).toDouble();
    final chlorophyll = (json['chlorophyll'] as num).toDouble();
    final salinity = (json['salinity'] as num?)?.toDouble() ?? 35.0;
    final cpue = (json['cpue'] as num?)?.toDouble() ?? 0.0;
    final score = json['fish_activity_score'] != null
        ? (json['fish_activity_score'] as num).toDouble()
        : computeFishActivityScore(
            sst: sst, chlorophyll: chlorophyll, salinity: salinity, cpue: cpue);

    return FishingZone(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
      fishDensity: (json['fish_density'] as num).toDouble(),
      sst: sst,
      chlorophyll: chlorophyll,
      salinity: salinity,
      cpue: cpue,
      fishActivityScore: score,
      currentSpeed: (json['current_speed'] as num).toDouble(),
      expectedSpecies: List<String>.from(json['expected_species'] ?? []),
      season: json['season'] as String,
      predictionConfidence:
          (json['prediction_confidence'] as num).toDouble(),
      isBreedingZone: json['is_breeding_zone'] as bool? ?? false,
      isFishingAllowed: json['is_fishing_allowed'] as bool? ?? true,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  /// Serialise to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'fish_density': fishDensity,
      'sst': sst,
      'chlorophyll': chlorophyll,
      'salinity': salinity,
      'cpue': cpue,
      'fish_activity_score': fishActivityScore,
      'current_speed': currentSpeed,
      'expected_species': expectedSpecies,
      'season': season,
      'prediction_confidence': predictionConfidence,
      'is_breeding_zone': isBreedingZone,
      'is_fishing_allowed': isFishingAllowed,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Human-readable productivity label based on chlorophyll levels.
  String get productivityLabel {
    if (chlorophyll >= 3.0) return 'High';
    if (chlorophyll >= 1.0) return 'Moderate';
    return 'Low';
  }

  /// Human-readable activity label derived from [fishActivityScore].
  String get activityLabel {
    if (fishActivityScore >= 75) return 'Excellent';
    if (fishActivityScore >= 50) return 'Good';
    if (fishActivityScore >= 25) return 'Fair';
    return 'Poor';
  }

  // ────────────────────────────────────────────────────────
  //  Fish Activity Score — pure, offline computation
  // ────────────────────────────────────────────────────────

  /// Computes a composite **fish_activity_score** (0–100) from four
  /// oceanographic inputs.  Runs entirely on-device — no internet needed.
  ///
  /// Formula (weighted sum of normalised sub-scores):
  /// ```
  /// score = 0.30 × sstScore
  ///       + 0.25 × chlorophyllScore
  ///       + 0.20 × salinityScore
  ///       + 0.25 × cpueScore
  /// ```
  ///
  /// | Parameter    | Ideal range          | Normalisation              |
  /// |-------------|----------------------|----------------------------|
  /// | SST         | 26 – 30 °C           | Gaussian around 28 °C      |
  /// | Chlorophyll | 0.5 – 10 mg/m³       | Log-scale, capped at 10    |
  /// | Salinity    | 33 – 36 PSU          | Gaussian around 34.5 PSU   |
  /// | CPUE        | 0 – 100 kg/trip      | Linear, capped at 100      |
  static double computeFishActivityScore({
    required double sst,
    required double chlorophyll,
    required double salinity,
    required double cpue,
  }) {
    // --- SST sub-score (Gaussian, peak at 28 °C, σ = 3) ---------------
    final sstScore = exp(-pow((sst - 28) / 3, 2)) * 100;

    // --- Chlorophyll sub-score (log-scale, 0.5–10 mg/m³) --------------
    final chlClamped = chlorophyll.clamp(0.01, 10.0);
    final chlScore = (log(chlClamped) - log(0.01)) /
        (log(10.0) - log(0.01)) *
        100;

    // --- Salinity sub-score (Gaussian, peak at 34.5 PSU, σ = 2) -------
    final salScore = exp(-pow((salinity - 34.5) / 2, 2)) * 100;

    // --- CPUE sub-score (linear, 0–100 kg/trip) -----------------------
    final cpueScore = cpue.clamp(0, 100).toDouble();

    // --- Weighted composite -------------------------------------------
    final composite = 0.30 * sstScore +
        0.25 * chlScore +
        0.20 * salScore +
        0.25 * cpueScore;

    return double.parse(composite.clamp(0, 100).toStringAsFixed(2));
  }

  @override
  String toString() =>
      'FishingZone($name, density=$fishDensity, activity=$fishActivityScore)';
}
