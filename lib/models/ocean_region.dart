// ═══════════════════════════════════════════════════════════════════
// Fisherman EduSea – Coastal Regions & AI Formula Engine
// Ported from fisherman-edusea/src/data/educationData.js
// ═══════════════════════════════════════════════════════════════════

import '../l10n/app_strings.dart';

// ──────────────────────────────────────
// Region static data (real oceanographic datasets)
// ──────────────────────────────────────

class OceanRegionData {
  final double sst; // °C Sea Surface Temperature
  final double salinity; // PSU
  final double waveHeight; // meters
  final double windSpeed; // km/h
  final double currentSpeed; // m/s
  final double chlorophyll; // mg/m³
  final bool upwelling;
  final bool cycloneAlert;
  final double visibility; // km
  final double tidalRange; // meters
  final double historicalCPUE; // kg/trip
  final String season;
  final bool breedingZone;
  final List<String> fishSpeciesEn;
  final List<String> fishSpeciesMr;

  const OceanRegionData({
    required this.sst,
    required this.salinity,
    required this.waveHeight,
    required this.windSpeed,
    required this.currentSpeed,
    required this.chlorophyll,
    required this.upwelling,
    required this.cycloneAlert,
    required this.visibility,
    required this.tidalRange,
    required this.historicalCPUE,
    required this.season,
    required this.breedingZone,
    required this.fishSpeciesEn,
    required this.fishSpeciesMr,
  });
}

class OceanRegion {
  final String id;
  final String labelEn;
  final String labelMr;
  final double lat;
  final double lng;
  final OceanRegionData data;

  const OceanRegion({
    required this.id,
    required this.labelEn,
    required this.labelMr,
    required this.lat,
    required this.lng,
    required this.data,
  });

  String label(AppLang lang) => lang == AppLang.en ? labelEn : labelMr;
}

const List<OceanRegion> oceanRegions = [
  OceanRegion(
    id: 'mumbai',
    labelEn: 'Arabian Sea – Mumbai Coast',
    labelMr: 'अरबी समुद्र – मुंबई किनारा',
    lat: 19.076,
    lng: 72.877,
    data: OceanRegionData(
      sst: 28.4,
      salinity: 35.2,
      waveHeight: 1.1,
      windSpeed: 18,
      currentSpeed: 0.6,
      chlorophyll: 2.8,
      upwelling: false,
      cycloneAlert: false,
      visibility: 12,
      tidalRange: 4.2,
      historicalCPUE: 42,
      season: 'post-monsoon',
      breedingZone: false,
      fishSpeciesEn: ['Pomfret', 'Bombay Duck', 'Mackerel', 'Shrimp'],
      fishSpeciesMr: ['पापलेट', 'बोंबील', 'बांगडा', 'कोळंबी'],
    ),
  ),
  OceanRegion(
    id: 'goa',
    labelEn: 'Arabian Sea – Goa Coast',
    labelMr: 'अरबी समुद्र – गोवा किनारा',
    lat: 15.299,
    lng: 73.878,
    data: OceanRegionData(
      sst: 29.1,
      salinity: 34.8,
      waveHeight: 0.7,
      windSpeed: 12,
      currentSpeed: 0.4,
      chlorophyll: 3.5,
      upwelling: true,
      cycloneAlert: false,
      visibility: 15,
      tidalRange: 2.1,
      historicalCPUE: 55,
      season: 'post-monsoon',
      breedingZone: false,
      fishSpeciesEn: ['Kingfish', 'Sardine', 'Tuna', 'Crab'],
      fishSpeciesMr: ['सुरमई', 'तारली', 'ट्यूना', 'खेकडा'],
    ),
  ),
  OceanRegion(
    id: 'kerala',
    labelEn: 'Arabian Sea – Kerala Coast',
    labelMr: 'अरबी समुद्र – केरळ किनारा',
    lat: 9.931,
    lng: 76.267,
    data: OceanRegionData(
      sst: 30.2,
      salinity: 33.9,
      waveHeight: 1.8,
      windSpeed: 28,
      currentSpeed: 0.8,
      chlorophyll: 4.2,
      upwelling: true,
      cycloneAlert: false,
      visibility: 10,
      tidalRange: 1.0,
      historicalCPUE: 68,
      season: 'post-monsoon',
      breedingZone: false,
      fishSpeciesEn: ['Sardine', 'Mackerel', 'Anchovy', 'Seer Fish'],
      fishSpeciesMr: ['तारली', 'बांगडा', 'नथिंग', 'सुरमई'],
    ),
  ),
  OceanRegion(
    id: 'chennai',
    labelEn: 'Bay of Bengal – Chennai Coast',
    labelMr: 'बंगालचा उपसागर – चेन्नई किनारा',
    lat: 13.082,
    lng: 80.270,
    data: OceanRegionData(
      sst: 29.8,
      salinity: 32.5,
      waveHeight: 2.3,
      windSpeed: 35,
      currentSpeed: 1.1,
      chlorophyll: 1.5,
      upwelling: false,
      cycloneAlert: true,
      visibility: 7,
      tidalRange: 0.8,
      historicalCPUE: 35,
      season: 'cyclone-season',
      breedingZone: true,
      fishSpeciesEn: ['Hilsa', 'Pomfret', 'Prawn', 'Ribbon Fish'],
      fishSpeciesMr: ['हिलसा', 'पापलेट', 'कोळंबी', 'वाम'],
    ),
  ),
  OceanRegion(
    id: 'ratnagiri',
    labelEn: 'Arabian Sea – Ratnagiri Coast',
    labelMr: 'अरबी समुद्र – रत्नागिरी किनारा',
    lat: 16.994,
    lng: 73.300,
    data: OceanRegionData(
      sst: 27.6,
      salinity: 35.0,
      waveHeight: 0.5,
      windSpeed: 10,
      currentSpeed: 0.3,
      chlorophyll: 3.1,
      upwelling: true,
      cycloneAlert: false,
      visibility: 18,
      tidalRange: 2.5,
      historicalCPUE: 60,
      season: 'post-monsoon',
      breedingZone: false,
      fishSpeciesEn: ['Mackerel', 'Squid', 'Prawn', 'Sole'],
      fishSpeciesMr: ['बांगडा', 'स्क्विड', 'कोळंबी', 'लेप'],
    ),
  ),
];

// ──────────────────────────────────────
// AI FORMULA RESULTS
// ──────────────────────────────────────

class SeaStatusResult {
  final String level; // 'calm' | 'moderate' | 'rough'
  final String label;
  final int score;
  final String colorKey; // 'emerald' | 'amber' | 'red'

  const SeaStatusResult({
    required this.level,
    required this.label,
    required this.score,
    required this.colorKey,
  });
}

class SafetyRiskResult {
  final String level; // 'safe' | 'moderate' | 'high'
  final String label;
  final String description;
  final int score;
  final String colorKey;

  const SafetyRiskResult({
    required this.level,
    required this.label,
    required this.description,
    required this.score,
    required this.colorKey,
  });
}

class FishActivityResult {
  final String level; // 'high' | 'moderate' | 'low'
  final String label;
  final String description;
  final int score;
  final String colorKey;

  const FishActivityResult({
    required this.level,
    required this.label,
    required this.description,
    required this.score,
    required this.colorKey,
  });
}

// ──────────────────────────────────────
// AI FORMULAS — ported from educationData.js
// ──────────────────────────────────────

/// Sea Status: wave + wind Beaufort-based composite
SeaStatusResult computeSeaStatus(OceanRegionData data, AppLang lang) {
  final score = (data.waveHeight * 30) + (data.windSpeed * 0.8);
  final clamped = score.clamp(0, 100).round();

  if (score < 30) {
    return SeaStatusResult(
      level: 'calm',
      label: lang == AppLang.en ? 'Calm Seas' : 'शांत समुद्र',
      score: clamped,
      colorKey: 'emerald',
    );
  } else if (score < 55) {
    return SeaStatusResult(
      level: 'moderate',
      label: lang == AppLang.en ? 'Moderate Seas' : 'मध्यम समुद्र',
      score: clamped,
      colorKey: 'amber',
    );
  } else {
    return SeaStatusResult(
      level: 'rough',
      label: lang == AppLang.en ? 'Rough Seas' : 'खवळलेला समुद्र',
      score: clamped,
      colorKey: 'red',
    );
  }
}

/// Safety Risk: AI risk scoring
/// Risk = (15 × wave) + (0.8 × wind) + (cyclone × 50) + (breedingZone × 10)
SafetyRiskResult computeSafetyRisk(OceanRegionData data, AppLang lang) {
  double score = (15 * data.waveHeight) +
      (0.8 * data.windSpeed) +
      (data.cycloneAlert ? 50 : 0) +
      (data.breedingZone ? 10 : 0);
  final clamped = score.clamp(0, 100).round();

  if (clamped <= 30) {
    return SafetyRiskResult(
      level: 'safe',
      label: lang == AppLang.en ? 'Safe' : 'सुरक्षित',
      description: lang == AppLang.en
          ? 'Conditions favorable. Safe for coastal and deep-sea fishing.'
          : 'परिस्थिती अनुकूल. किनारी आणि खोल समुद्री मासेमारीसाठी सुरक्षित.',
      score: clamped,
      colorKey: 'emerald',
    );
  } else if (clamped <= 60) {
    return SafetyRiskResult(
      level: 'moderate',
      label: lang == AppLang.en ? 'Moderate Risk' : 'मध्यम धोका',
      description: lang == AppLang.en
          ? 'Exercise caution. Monitor weather updates. Stay near coast.'
          : 'सावधगिरी बाळगा. हवामान अद्यतने तपासा. किनाऱ्याजवळ रहा.',
      score: clamped,
      colorKey: 'amber',
    );
  } else {
    return SafetyRiskResult(
      level: 'high',
      label: lang == AppLang.en ? 'High Risk' : 'उच्च धोका',
      description: lang == AppLang.en
          ? 'DANGER: Avoid sea. Cyclone/storm conditions detected.'
          : 'धोका: समुद्रात जाणे टाळा. चक्रीवादळ/वादळ स्थिती आढळली.',
      score: clamped,
      colorKey: 'red',
    );
  }
}

/// Fish Activity Prediction: SST + Chlorophyll + Upwelling + CPUE
FishActivityResult computeFishActivity(OceanRegionData data, AppLang lang) {
  final sstScore = (30 - (data.sst - 28).abs() * 6).clamp(0, 30).toDouble();
  final chlScore = (data.chlorophyll * 7).clamp(0, 30).toDouble();
  final upwellingBonus = data.upwelling ? 12.0 : 0.0;
  final cpueScore = ((data.historicalCPUE / 70) * 15).clamp(0, 15).toDouble();
  final breedPenalty = data.breedingZone ? 10.0 : 0.0;

  final score =
      (sstScore + chlScore + upwellingBonus + cpueScore - breedPenalty)
          .clamp(0, 100)
          .round();

  if (score >= 65) {
    return FishActivityResult(
      level: 'high',
      label: lang == AppLang.en ? 'High Activity' : 'उच्च सक्रियता',
      description: lang == AppLang.en
          ? 'Optimal conditions. Chlorophyll: ${data.chlorophyll} mg/m³, SST: ${data.sst}°C. High probability of fish schools near surface.'
          : 'इष्टतम परिस्थिती. क्लोरोफिल: ${data.chlorophyll} mg/m³, SST: ${data.sst}°C.',
      score: score,
      colorKey: 'emerald',
    );
  } else if (score >= 35) {
    return FishActivityResult(
      level: 'moderate',
      label: lang == AppLang.en ? 'Moderate Activity' : 'मध्यम सक्रियता',
      description: lang == AppLang.en
          ? 'Average conditions. SST: ${data.sst}°C, Chlorophyll: ${data.chlorophyll} mg/m³.'
          : 'सरासरी परिस्थिती. SST: ${data.sst}°C.',
      score: score,
      colorKey: 'cyan',
    );
  } else {
    return FishActivityResult(
      level: 'low',
      label: lang == AppLang.en ? 'Low Activity' : 'कमी सक्रियता',
      description: lang == AppLang.en
          ? 'Unfavorable. SST: ${data.sst}°C outside optimal range. Wait for tide change or relocate.'
          : 'प्रतिकूल परिस्थिती. SST: ${data.sst}°C इष्टतम श्रेणीबाहेर.',
      score: score,
      colorKey: 'slate',
    );
  }
}
