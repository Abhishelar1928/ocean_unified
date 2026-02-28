import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/environmental_data.dart';
import '../models/fishing_zone.dart';
import '../services/offline_data_service.dart';
import 'fishing_prediction_service.dart';

/// Service that fetches real-time environmental data, computes an
/// **environmental suitability score**, and optionally chains into
/// [FishingPredictionService] for a combined ranking — all results
/// are cached locally for offline use via [OfflineDataService].
///
/// Mirrors the server-side logic in:
///   • `server/services/fetchMarineData.js`   – Open-Meteo Marine API
///   • `server/services/calculateRisk.js`     – deterministic risk formula
///   • `server/services/generateLearning.js`  – adaptive learning via Ollama
class EnvironmentalModelService {
  // ──────────────────────────────────────
  //  API endpoints
  // ──────────────────────────────────────
  static const _marineApiBase = 'https://marine-api.open-meteo.com/v1/marine';
  static const _weatherApiBase = 'https://api.open-meteo.com/v1/forecast';

  /// Backend URL for AI-generated learning modules.
  final String _backendUrl;

  /// Offline cache service for persisting computed results.
  final OfflineDataService _offlineDataService;

  /// Fishing-prediction service, lazily used in [evaluateAndPredict].
  final FishingPredictionService _fishingPrediction;

  EnvironmentalModelService({
    required String backendUrl,
    OfflineDataService? offlineDataService,
    FishingPredictionService? fishingPrediction,
  })  : _backendUrl = backendUrl,
        _offlineDataService = offlineDataService ?? OfflineDataService(),
        _fishingPrediction = fishingPrediction ?? FishingPredictionService();

  // ──────────────────────────────────────
  //  Fetch live marine conditions
  // ──────────────────────────────────────

  /// Fetches current marine + weather data for [lat] / [lon] from
  /// Open-Meteo APIs and computes the deterministic risk score.
  Future<EnvironmentalData> fetchLiveConditions({
    required double lat,
    required double lon,
  }) async {
    // Fire both requests concurrently.
    final marineUri = Uri.parse(_marineApiBase).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': 'wave_height,sea_surface_temperature',
      'timezone': 'Asia/Kolkata',
    });

    final weatherUri = Uri.parse(_weatherApiBase).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': 'wind_speed_10m',
      'timezone': 'Asia/Kolkata',
    });

    final responses = await Future.wait([
      http.get(marineUri).timeout(const Duration(seconds: 10)),
      http.get(weatherUri).timeout(const Duration(seconds: 10)),
    ]);

    final marineJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final weatherJson = jsonDecode(responses[1].body) as Map<String, dynamic>;

    final marineCurrent = marineJson['current'] as Map<String, dynamic>? ?? {};
    final weatherCurrent =
        weatherJson['current'] as Map<String, dynamic>? ?? {};

    final sst =
        (marineCurrent['sea_surface_temperature'] as num?)?.toDouble() ?? 0;
    final waveHeight = (marineCurrent['wave_height'] as num?)?.toDouble() ?? 0;
    final windSpeed =
        (weatherCurrent['wind_speed_10m'] as num?)?.toDouble() ?? 0;

    final risk = RiskAssessment.calculate(
      waveHeight: waveHeight,
      windSpeed: windSpeed,
    );

    return EnvironmentalData(
      seaSurfaceTemperature: sst,
      waveHeight: waveHeight,
      windSpeed: windSpeed,
      risk: risk,
      fetchedAt: DateTime.now(),
    );
  }

  // ──────────────────────────────────────
  //  Environmental Suitability Evaluation
  // ──────────────────────────────────────

  /// Evaluate an [EnvironmentalData] dataset and return a new copy
  /// that includes the computed **environmental suitability score**.
  ///
  /// Pure + offline — no network calls.  The result is also cached via
  /// [OfflineDataService] so it survives app restarts.
  Future<EnvironmentalData> evaluateEnvironment(EnvironmentalData raw) async {
    final score = EnvironmentalData.computeSuitabilityScore(
      sst: raw.seaSurfaceTemperature,
      chlorophyll: raw.chlorophyll,
      salinity: raw.salinity,
      waveHeight: raw.waveHeight,
      windSpeed: raw.windSpeed,
      visibility: raw.visibility,
      upwelling: raw.upwelling,
    );

    final enriched = raw.copyWithSuitability(score);

    // Persist to local storage so the score is available offline.
    await _offlineDataService.cacheEnvironmentalData(enriched);

    return enriched;
  }

  // ──────────────────────────────────────
  //  Combined: Suitability + Prediction
  // ──────────────────────────────────────

  /// End-to-end pipeline:
  ///   1. Compute environmental suitability score on [envData].
  ///   2. Run [FishingPredictionService.predictFromEnvironment] to
  ///      produce ranked [FishingZone]s, using the suitability score
  ///      as a confidence modifier.
  ///   3. Cache both the enriched [EnvironmentalData] and the
  ///      prediction list locally for offline access.
  ///
  /// Returns a record with the enriched env data and sorted zones.
  Future<({EnvironmentalData env, List<FishingZone> zones})>
      evaluateAndPredict({
    required EnvironmentalData envData,
    required double lat,
    required double lon,
  }) async {
    // Step 1 — compute suitability
    final enrichedEnv = await evaluateEnvironment(envData);

    // Step 2 — run fishing prediction (already offline)
    final zones = _fishingPrediction.predictFromEnvironment(
      env: enrichedEnv,
      latitude: lat,
      longitude: lon,
    );

    // Step 3 — cache predictions
    await _offlineDataService.cachePredictions(zones);

    return (env: enrichedEnv, zones: zones);
  }

  /// Convenience: fetch live data → evaluate suitability → predict
  /// zones.  Falls back to cached data on network failure.
  Future<({EnvironmentalData env, List<FishingZone> zones})>
      fetchEvaluateAndPredict({
    required double lat,
    required double lon,
  }) async {
    try {
      final raw = await fetchLiveConditions(lat: lat, lon: lon);
      return evaluateAndPredict(envData: raw, lat: lat, lon: lon);
    } catch (_) {
      // Offline fallback
      final cachedEnv = await _offlineDataService.getCachedEnvironmentalData();
      final cachedZones = await _offlineDataService.getCachedPredictions();
      if (cachedEnv != null) {
        return (env: cachedEnv, zones: cachedZones);
      }
      rethrow;
    }
  }

  // ──────────────────────────────────────
  //  Adaptive learning modules
  // ──────────────────────────────────────

  /// Request AI-generated learning modules from the backend.
  ///
  /// Modules are personalised based on the fisherman's state and
  /// current environmental conditions.
  Future<List<LearningModule>> fetchLearningModules({
    required String state,
    required EnvironmentalData envData,
  }) async {
    final uri = Uri.parse('$_backendUrl/api/learning');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'state': state,
              'sst': envData.seaSurfaceTemperature,
              'waveHeight': envData.waveHeight,
              'windSpeed': envData.windSpeed,
              'riskLevel': envData.risk.level.name,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final modules = body['modules'] as List<dynamic>? ?? [];
        return modules
            .map((m) => LearningModule.fromJson(m as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Offline — return static modules
    }

    return _staticModules();
  }

  /// Hardcoded modules used when the AI backend is unavailable.
  List<LearningModule> _staticModules() {
    return [
      LearningModule(
        title: 'Understanding Sea Surface Temperature',
        summary:
            'Learn how SST affects fish behaviour and where productive waters are found.',
        difficulty: 1,
        tags: ['SST', 'fish behaviour'],
        content: '### What is SST?\n\n'
            'Sea Surface Temperature is the water temperature at the top layer '
            'of the ocean. It is measured by satellites and weather buoys.\n\n'
            '### Why does it matter?\n\n'
            '- Fish are cold-blooded — they follow comfortable temperatures.\n'
            '- A sudden SST change can signal upwelling, bringing nutrients.\n'
            '- During marine heatwaves (SST > 31 °C), fish dive deeper or migrate.\n\n'
            '### Ideal SST ranges\n\n'
            '| Species        | Optimal SST (°C) |\n'
            '|----------------|------------------|\n'
            '| Mackerel       | 24–28            |\n'
            '| Sardine        | 22–26            |\n'
            '| Tuna (Skipjack)| 28–31            |\n'
            '| Prawns         | 26–30            |\n\n'
            'Use the SST reading in Sea Mode to pick zones with ideal temperatures.',
      ),
      LearningModule(
        title: 'Reading Wave & Wind Conditions',
        summary:
            'Interpret wave height and wind speed data to plan safe fishing trips.',
        difficulty: 1,
        tags: ['safety', 'waves', 'wind'],
        content: '### Risk Formula\n\n'
            'Risk Score = 15 × Wave Height (m) + 0.8 × Wind Speed (km/h)\n\n'
            '| Score | Level    | Action                      |\n'
            '|-------|----------|-----------------------------||\n'
            '| < 30  | Safe     | Normal operations           |\n'
            '| < 60  | Moderate | Caution, stay near coast    |\n'
            '| ≥ 60  | High     | Do not venture out to sea   |\n\n'
            '### Tips\n\n'
            '- Always check the forecast before departure.\n'
            '- Wave height > 2 m: traditional boats should stay ashore.\n'
            '- Wind speed > 40 km/h: risk of capsize for small vessels.\n'
            '- Carry a VHF radio tuned to Channel 16 (emergency).',
      ),
      LearningModule(
        title: 'Sustainable Fishing Practices',
        summary:
            'Best practices for net selection, catch limits, and breeding-season awareness.',
        difficulty: 2,
        tags: ['sustainability', 'regulations'],
        content: '### Key Principles\n\n'
            '1. **Mesh size** — never use mesh smaller than 20 mm for trawls.\n'
            '2. **Breeding season** — observe the 47-day monsoon ban (June–Aug).\n'
            '3. **By-catch** — release juvenile and non-target species.\n'
            '4. **Quota** — stay within the CPUE advisory for your region.\n\n'
            '### Monsoon Fishing Ban\n\n'
            'The central government and most coastal states enforce a 47-day '
            'ban on mechanised fishing from **June 1 to July 31** (east coast: '
            'April 15 to June 14). Violations attract fines and licence suspension.\n\n'
            '### Benefits of Sustainable Fishing\n\n'
            '- Larger average catch size in subsequent seasons.\n'
            '- Higher market price for certified sustainable catch.\n'
            '- Eligibility for eco-certification schemes under PMMSY.',
      ),
      LearningModule(
        title: 'Using AI Fishing Predictions',
        summary:
            'Understand how the app calculates fishing zone scores and how to act on them.',
        difficulty: 2,
        tags: ['AI', 'prediction', 'zones'],
        content: '### How the Score is Calculated\n\n'
            'Each fishing zone receives a **Final Score (0–1)**:\n\n'
            '```\nFinal Score = 0.5 × Fish Activity + 0.3 × Env Quality − 0.2 × Risk\n```\n\n'
            '**Fish Activity** = 0.30×SST + 0.25×Chlorophyll + 0.20×Salinity + 0.25×CPUE\n\n'
            '**Environmental Quality** = normalised wave & current conditions\n\n'
            '**Risk** = 15×Wave Height + 0.8×Wind Speed\n\n'
            '### Interpreting Colours on the Map\n\n'
            '- **Cyan ring** — best recommended zone for today.\n'
            '- **Green circle** — good zone (score > 0.5).\n'
            '- **Red/orange circle** — poor or risky zone.\n\n'
            '### Acting on Predictions\n\n'
            '1. Switch to Sea Mode and tap the destination zone.\n'
            '2. Follow the navigation arrow to the zone centre.\n'
            '3. Re-check score every 10 minutes as conditions change.',
      ),
      LearningModule(
        title: 'Emergency Procedures at Sea',
        summary:
            'What to do during storms, engine failure, and man-overboard situations.',
        difficulty: 3,
        tags: ['safety', 'emergency', 'SOS'],
        content: '### Before You Leave Port\n\n'
            '- Check the weather forecast and INCOIS wave alerts.\n'
            '- Ensure life jackets for all crew members.\n'
            '- Carry charged mobile phone + VHF radio.\n'
            '- Inform a shore contact of your departure point and ETA.\n\n'
            '### Storm / High Waves\n\n'
            '1. Head back to port immediately — do not wait.\n'
            '2. Reduce speed and point bow into the waves.\n'
            '3. Secure all heavy gear and equipment.\n\n'
            '### Engine Failure\n\n'
            '1. Drop anchor if near a shoal.\n'
            '2. Call Coast Guard on VHF Channel 16 or dial **1554**.\n'
            '3. Use SOS button in this app — sends GPS coordinates automatically.\n\n'
            '### Man Overboard\n\n'
            '1. Shout "Man overboard!" and throw a life ring immediately.\n'
            '2. Keep the person in sight — do not lose visual.\n'
            '3. Circle back at low speed — approach from downwind.\n'
            '4. Mark the GPS position and report to Coast Guard.',
      ),
    ];
  }
}

// ──────────────────────────────────────────────────────────
//  Learning module model (lightweight, specific to AI layer)
// ──────────────────────────────────────────────────────────

class LearningModule {
  final String title;
  final String summary;

  /// Difficulty level (1 = beginner … 5 = expert).
  final int difficulty;

  /// Topic tags for filtering.
  final List<String> tags;

  /// Optional body content (Markdown).
  final String? content;

  const LearningModule({
    required this.title,
    required this.summary,
    required this.difficulty,
    required this.tags,
    this.content,
  });

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'difficulty': difficulty,
        'tags': tags,
        'content': content,
      };
}
