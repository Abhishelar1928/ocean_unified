import 'dart:math';

/// Live/near-real-time environmental conditions for a coastal location.
///
/// Fetched from the Open-Meteo Marine + Weather APIs and used by
/// [EnvironmentalModelService] for risk scoring, suitability scoring,
/// and AI advisories.
class EnvironmentalData {
  /// Sea-surface temperature in °C.
  final double seaSurfaceTemperature;

  /// Significant wave height in metres.
  final double waveHeight;

  /// Wind speed at 10 m above sea level in km/h.
  final double windSpeed;

  /// Salinity in PSU (may be null if unavailable).
  final double? salinity;

  /// Chlorophyll-a concentration in mg/m³.
  final double? chlorophyll;

  /// Horizontal visibility in km.
  final double? visibility;

  /// Tidal range in metres.
  final double? tidalRange;

  /// Whether an upwelling event is detected.
  final bool upwelling;

  /// Whether a cyclone alert is active for this region.
  final bool cycloneAlert;

  /// Risk assessment derived from wave height & wind speed.
  final RiskAssessment risk;

  /// Composite environmental suitability score (0–100).
  ///
  /// Computed from chlorophyll, salinity, SST, wave height, wind speed,
  /// visibility, and upwelling via [computeSuitabilityScore].  Higher
  /// values mean the environment is more favourable for fishing.
  ///
  /// `null` until [EnvironmentalModelService.evaluateEnvironment] is called.
  final double? environmentalSuitabilityScore;

  /// ISO-8601 timestamp of when the data was fetched.
  final DateTime fetchedAt;

  const EnvironmentalData({
    required this.seaSurfaceTemperature,
    required this.waveHeight,
    required this.windSpeed,
    this.salinity,
    this.chlorophyll,
    this.visibility,
    this.tidalRange,
    this.upwelling = false,
    this.cycloneAlert = false,
    required this.risk,
    this.environmentalSuitabilityScore,
    required this.fetchedAt,
  });

  factory EnvironmentalData.fromJson(Map<String, dynamic> json) {
    return EnvironmentalData(
      seaSurfaceTemperature:
          (json['sea_surface_temperature'] as num).toDouble(),
      waveHeight: (json['wave_height'] as num).toDouble(),
      windSpeed: (json['wind_speed'] as num).toDouble(),
      salinity: (json['salinity'] as num?)?.toDouble(),
      chlorophyll: (json['chlorophyll'] as num?)?.toDouble(),
      visibility: (json['visibility'] as num?)?.toDouble(),
      tidalRange: (json['tidal_range'] as num?)?.toDouble(),
      upwelling: json['upwelling'] as bool? ?? false,
      cycloneAlert: json['cyclone_alert'] as bool? ?? false,
      risk: RiskAssessment.fromJson(
          json['risk'] as Map<String, dynamic>? ?? {}),
      environmentalSuitabilityScore:
          (json['environmental_suitability_score'] as num?)?.toDouble(),
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sea_surface_temperature': seaSurfaceTemperature,
      'wave_height': waveHeight,
      'wind_speed': windSpeed,
      'salinity': salinity,
      'chlorophyll': chlorophyll,
      'visibility': visibility,
      'tidal_range': tidalRange,
      'upwelling': upwelling,
      'cyclone_alert': cycloneAlert,
      'risk': risk.toJson(),
      'environmental_suitability_score': environmentalSuitabilityScore,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  /// Returns a copy with [environmentalSuitabilityScore] set.
  EnvironmentalData copyWithSuitability(double score) {
    return EnvironmentalData(
      seaSurfaceTemperature: seaSurfaceTemperature,
      waveHeight: waveHeight,
      windSpeed: windSpeed,
      salinity: salinity,
      chlorophyll: chlorophyll,
      visibility: visibility,
      tidalRange: tidalRange,
      upwelling: upwelling,
      cycloneAlert: cycloneAlert,
      risk: risk,
      environmentalSuitabilityScore: score,
      fetchedAt: fetchedAt,
    );
  }

  /// Human-readable label for [environmentalSuitabilityScore].
  String get suitabilityLabel {
    final s = environmentalSuitabilityScore;
    if (s == null) return 'N/A';
    if (s >= 75) return 'Excellent';
    if (s >= 50) return 'Good';
    if (s >= 25) return 'Fair';
    return 'Poor';
  }

  // ────────────────────────────────────────────────────────
  //  Environmental Suitability Score — pure, offline
  // ────────────────────────────────────────────────────────

  /// Computes a composite **environmental suitability score** (0–100)
  /// from the full dataset.  Runs entirely on-device — no internet.
  ///
  /// Weighted sub-scores:
  /// ```
  /// score = 0.25 × chlorophyllScore   (primary — productivity proxy)
  ///       + 0.20 × salinityScore      (primary — species tolerance)
  ///       + 0.20 × sstScore           (thermal comfort for fish)
  ///       + 0.15 × waveScore          (inverse — calmer = better)
  ///       + 0.10 × windScore          (inverse — calmer = better)
  ///       + 0.05 × visibilityScore    (higher = better)
  ///       + 0.05 × upwellingBonus     (100 if upwelling, else 0)
  /// ```
  static double computeSuitabilityScore({
    required double sst,
    double? chlorophyll,
    double? salinity,
    required double waveHeight,
    required double windSpeed,
    double? visibility,
    bool upwelling = false,
  }) {
    // --- Chlorophyll sub-score (log-scale, 0.01 – 10 mg/m³) ----------
    final chl = (chlorophyll ?? 1.0).clamp(0.01, 10.0);
    final chlScore =
        (log(chl) - log(0.01)) / (log(10.0) - log(0.01)) * 100;

    // --- Salinity sub-score (Gaussian, peak 34.5 PSU, σ = 2) ---------
    final sal = salinity ?? 35.0;
    final salScore = exp(-pow((sal - 34.5) / 2, 2)) * 100;

    // --- SST sub-score (Gaussian, peak 28 °C, σ = 3) -----------------
    final sstScore = exp(-pow((sst - 28) / 3, 2)) * 100;

    // --- Wave-height sub-score (inverse sigmoid — lower is better) ----
    //     0 m → 100,  2 m → ~50,  5 m → ~5
    final waveScore = 100 / (1 + exp((waveHeight - 2) * 2));

    // --- Wind-speed sub-score (inverse sigmoid — lower is better) -----
    //     0 km/h → 100,  25 km/h → ~50,  50 km/h → ~5
    final windScore = 100 / (1 + exp((windSpeed - 25) / 10));

    // --- Visibility sub-score (linear, 0–20 km capped) ----------------
    final vis = (visibility ?? 12.0).clamp(0.0, 20.0);
    final visScore = (vis / 20.0) * 100;

    // --- Upwelling bonus (binary) -------------------------------------
    final upwellingBonus = upwelling ? 100.0 : 0.0;

    // --- Weighted composite -------------------------------------------
    final composite = 0.25 * chlScore +
        0.20 * salScore +
        0.20 * sstScore +
        0.15 * waveScore +
        0.10 * windScore +
        0.05 * visScore +
        0.05 * upwellingBonus;

    return double.parse(composite.clamp(0, 100).toStringAsFixed(2));
  }
}

// ──────────────────────────────────────────────────────────
//  Risk Assessment
// ──────────────────────────────────────────────────────────

enum RiskLevel { safe, moderate, high }

/// Deterministic risk score mirroring the server-side formula:
///   score = 15 × waveHeight + 0.8 × windSpeed
class RiskAssessment {
  final double score;
  final RiskLevel level;
  final String description;

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.description,
  });

  /// Compute risk from raw environmental values.
  factory RiskAssessment.calculate({
    required double waveHeight,
    required double windSpeed,
  }) {
    final score =
        double.parse(((15 * waveHeight) + (0.8 * windSpeed)).toStringAsFixed(2));

    RiskLevel level;
    String description;

    if (score < 30) {
      level = RiskLevel.safe;
      description =
          'Sea conditions are calm. Suitable for fishing operations.';
    } else if (score < 60) {
      level = RiskLevel.moderate;
      description =
          'Sea conditions are moderate. Exercise caution and monitor updates.';
    } else {
      level = RiskLevel.high;
      description =
          'Dangerous sea conditions. Avoid venturing into the sea. Stay onshore.';
    }

    return RiskAssessment(
      score: score,
      level: level,
      description: description,
    );
  }

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    final levelStr = (json['level'] as String?)?.toLowerCase() ?? 'safe';
    return RiskAssessment(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      level: RiskLevel.values.firstWhere(
        (e) => e.name == levelStr,
        orElse: () => RiskLevel.safe,
      ),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level.name,
        'description': description,
      };

  /// Colour hex for UI badges.
  String get colorHex {
    switch (level) {
      case RiskLevel.safe:
        return '#00C781';
      case RiskLevel.moderate:
        return '#FFAA15';
      case RiskLevel.high:
        return '#FF4B4B';
    }
  }
}
