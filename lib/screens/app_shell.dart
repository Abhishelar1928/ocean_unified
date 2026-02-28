import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sea_mode_screen.dart';
import 'learning_screen.dart'; // public widgets (ModuleCard, SchemeCard, etc.)
import 'simulator_screen.dart';
import '../models/government_scheme.dart';
import 'home_screen.dart'; // NewsCard

import '../services/gps_service.dart';
import '../services/port_service.dart';
import '../services/sos_service.dart';
import '../services/offline_data_service.dart';
import '../services/news_service.dart';
import '../ai/fishing_prediction_service.dart';
import '../ai/environmental_model_service.dart';
import '../ai/marine_intelligence_service.dart';
import '../models/environmental_data.dart';
import '../models/fishing_zone.dart';
import '../models/ocean_region.dart';
import '../l10n/app_strings.dart';
import '../state/app_state.dart';

// ══════════════════════════════════════════════════════════
//  AppShell — root widget with Home ↔ Sea mode toggle
// ══════════════════════════════════════════════════════════

/// The root entry-point widget for the Fisherman EduSea application.
///
/// Provides a prominent **mode toggle switch** that flips between:
///
/// | Mode      | Features                                              |
/// |-----------|-------------------------------------------------------|
/// | **Home**  | Data analytics · Learning · News · Government Schemes |
/// | **Sea**   | GPS navigation · Best fishing spot · Risk score ·     |
/// |           | Red zone alerts · SOS system · Nearest port            |
///
/// Home Mode is organised as four bottom-navigation tabs.
/// Sea Mode renders [SeaModeScreen] full-screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // ──────────────────────────────────────
  //  Mode & tab state
  // ──────────────────────────────────────

  bool _isSeaMode = false;
  int _homeTabIndex = 0;

  // ──────────────────────────────────────
  //  Services
  // ──────────────────────────────────────

  static const _backendUrl = 'http://localhost:3000';

  final _gps = GpsService();
  late final PortService _portService;
  late final SosService _sosService;
  late final OfflineDataService _offlineData;
  late final FishingPredictionService _prediction;
  late final EnvironmentalModelService _envModel;
  late final MarineIntelligenceService _intelligence;
  late final NewsService _newsService;

  // ──────────────────────────────────────
  //  Dashboard state
  // ──────────────────────────────────────

  EnvironmentalData? _envData;
  List<FishingZone> _predictedZones = [];
  bool _dashboardLoading = true;
  bool _downloadingPack = false;
  String? _dashboardError;

  // ──────────────────────────────────────
  //  Learning state
  // ──────────────────────────────────────

  List<LearningModule> _modules = [];
  bool _modulesLoading = true;
  String _selectedState = 'Maharashtra';
  int _expandedModuleIdx = -1;

  static const _coastalStates = [
    'Maharashtra',
    'Gujarat',
    'Kerala',
    'Tamil Nadu',
    'Andhra Pradesh',
    'West Bengal',
  ];

  // ──────────────────────────────────────
  //  News state
  // ──────────────────────────────────────

  List<MarineNewsArticle> _newsArticles = [];

  // ──────────────────────────────────────
  //  Schemes state
  // ──────────────────────────────────────

  SchemeCategory? _selectedSchemeCategory;
  int _expandedSchemeIdx = -1;

  // ──────────────────────────────────────
  //  Search (shared across Learn & Schemes)
  // ──────────────────────────────────────

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ══════════════════════════════════════
  //  Lifecycle
  // ══════════════════════════════════════

  @override
  void initState() {
    super.initState();

    _portService = PortService(baseUrl: _backendUrl);
    _offlineData = OfflineDataService();
    _sosService = SosService(
      gpsService: _gps,
      portService: _portService,
      offlineData: _offlineData,
      backendUrl: _backendUrl,
      emergencyContacts: const [],
    );
    _prediction = FishingPredictionService();
    _envModel = EnvironmentalModelService(
      backendUrl: _backendUrl,
      offlineDataService: _offlineData,
      fishingPrediction: _prediction,
    );
    _intelligence = MarineIntelligenceService(
      envService: _envModel,
      fishService: _prediction,
      offlineData: _offlineData,
    );
    _newsService = NewsService(backendUrl: _backendUrl);

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _offlineData.init();
      await _newsService.init();
      await _portService.loadPorts();

      final pos = await _gps.getCurrentPosition();

      // ── Intelligence pipeline ──
      final result = await _intelligence.assess(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      // ── News ──
      final news = await _newsService.fetchNews();

      // ── Learning modules ──
      final env = result.environmentalData;
      List<LearningModule> modules;
      try {
        modules = await _envModel.fetchLearningModules(
          state: _selectedState,
          envData: env,
        );
      } catch (_) {
        modules = defaultLearningModules();
      }

      setState(() {
        _envData = result.environmentalData;
        _predictedZones = result.rankedZones.map((s) => s.zone).toList();
        _newsArticles = news;
        _modules = modules;
        _dashboardLoading = false;
        _modulesLoading = false;
      });
    } catch (e) {
      // ── Offline fallback ──
      final cached = await _offlineData.getCachedEnvironmentalData();
      final cachedZones = await _offlineData.getCachedPredictions();
      final cachedNews = _newsService.getCachedNews();

      setState(() {
        _envData = cached;
        _predictedZones = cachedZones;
        _newsArticles = cachedNews;
        _modules = defaultLearningModules();
        _dashboardLoading = false;
        _modulesLoading = false;
        _dashboardError = cached == null ? e.toString() : null;
      });
    }
  }

  @override
  void dispose() {
    _gps.dispose();
    _newsService.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  //  Build
  // ══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ── Sea Mode: full-screen SeaModeScreen ──
    if (_isSeaMode) {
      return SeaModeScreen(
        onModeToggle: () => setState(() => _isSeaMode = false),
      );
    }

    // ── Home Mode: 4-tab scaffold ──
    return Scaffold(
      appBar: _buildHomeAppBar(),
      body: _dashboardLoading
          ? const Center(child: CircularProgressIndicator())
          : _dashboardError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('Error: $_dashboardError',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _bootstrap,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : IndexedStack(
                  index: _homeTabIndex,
                  children: [
                    _buildDashboardTab(),
                    _buildLearnTab(),
                    _buildNewsTab(),
                    _buildSchemesTab(),
                    const SimulatorScreen(),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _homeTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        onTap: (i) => setState(() => _homeTabIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Learn'),
          BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'News'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance),
              label: 'Schemes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.gps_fixed_outlined),
              activeIcon: Icon(Icons.gps_fixed),
              label: 'Simulator'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  //  Home App Bar
  // ──────────────────────────────────────

  PreferredSizeWidget _buildHomeAppBar() {
    final appState = context.watch<AppState>();
    final lang = appState.lang;
    return AppBar(
      title: Text(AppStrings.of(lang).platformName),
      centerTitle: false,
      actions: [
        // Language toggle
        TextButton(
          onPressed: () => appState.toggleLang(),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(
            lang == AppLang.en ? 'मराठी' : 'EN',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        _ModeToggle(
          isSeaMode: _isSeaMode,
          onChanged: (v) => setState(() => _isSeaMode = v),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.sos, color: Colors.red),
          tooltip: 'SOS',
          onPressed: _handleSos,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 0 — Dashboard (Data Analytics)
  // ══════════════════════════════════════════════════════════

  Widget _buildDashboardTab() {
    final appState = context.watch<AppState>();
    final lang = appState.lang;
    final s = AppStrings.of(lang);
    final regionId = appState.selectedRegionId;
    final region = oceanRegions.firstWhere((r) => r.id == regionId,
        orElse: () => oceanRegions.first);
    final seaStatus = computeSeaStatus(region.data, lang);
    final safetyRisk = computeSafetyRisk(region.data, lang);
    final fishActivity = computeFishActivity(region.data, lang);

    final env = _envData;
    if (env == null) {
      return const Center(child: Text('No environmental data available'));
    }
    final risk = env.risk;

    return RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Region selector ──────────────────────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: regionId,
                  isExpanded: true,
                  items: oceanRegions
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.label(lang)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) appState.setRegion(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── AI Formula Panel (from fisherman-edusea) ─────────────────
          Row(
            children: [
              Expanded(
                child: _aiMetricCard(
                  label: s.seaStatus,
                  value: seaStatus.label,
                  score: seaStatus.score,
                  color: _colorFromKey(seaStatus.colorKey),
                  icon: Icons.waves,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _aiMetricCard(
                  label: s.riskLevel,
                  value: safetyRisk.label,
                  score: safetyRisk.score,
                  color: _colorFromKey(safetyRisk.colorKey),
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _aiMetricCard(
                  label: s.fishActivity,
                  value: fishActivity.label,
                  score: fishActivity.score,
                  color: _colorFromKey(fishActivity.colorKey),
                  icon: Icons.set_meal_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Region detail card ───────────────────────────────────────
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safety risk description
                  if (safetyRisk.level == 'high')
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(safetyRisk.description,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(safetyRisk.description,
                        style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  // Fish activity description
                  Text(fishActivity.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(height: 8),
                  // Fish species
                  Wrap(
                    spacing: 6,
                    children: (lang == AppLang.en
                            ? region.data.fishSpeciesEn
                            : region.data.fishSpeciesMr)
                        .map((sp) => Chip(
                              label: Text(sp,
                                  style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  // Key metrics
                  Row(
                    children: [
                      _miniStat('SST', '${region.data.sst}°C'),
                      _miniStat('Chl', '${region.data.chlorophyll} mg/m³'),
                      _miniStat('CPUE', '${region.data.historicalCPUE} kg'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Progress panel ───────────────────────────────────────────
          _buildProgressPanel(appState, s),
          const SizedBox(height: 16),
          Card(
            color: _riskColor(risk.level).withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    risk.level.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _riskColor(risk.level),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Risk Score: ${risk.score}'),
                  const SizedBox(height: 8),
                  Text(risk.description, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Conditions grid ──
          _conditionTile(Icons.thermostat, 'SST',
              '${env.seaSurfaceTemperature.toStringAsFixed(1)} °C'),
          _conditionTile(Icons.waves, 'Wave Height',
              '${env.waveHeight.toStringAsFixed(1)} m'),
          _conditionTile(Icons.air, 'Wind Speed',
              '${env.windSpeed.toStringAsFixed(1)} km/h'),
          if (env.cycloneAlert)
            const ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text('Cyclone Alert Active',
                  style: TextStyle(color: Colors.red)),
            ),

          // ── Environmental Suitability ──
          if (env.environmentalSuitabilityScore != null) ...[
            const SizedBox(height: 16),
            Card(
              color: _suitabilityColor(env.environmentalSuitabilityScore!)
                  .withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          _suitabilityColor(env.environmentalSuitabilityScore!),
                      child: Text(
                        env.environmentalSuitabilityScore!.toStringAsFixed(0),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Environmental Suitability',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            env.suitabilityLabel,
                            style: TextStyle(
                              color: _suitabilityColor(
                                  env.environmentalSuitabilityScore!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── AI Predictions ──
          if (_predictedZones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('AI Fishing Prediction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Sea Pack download card
            _buildSeaPackCard(),
            const SizedBox(height: 8),

            ..._predictedZones.map((z) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: z.fishActivityScore >= 75
                          ? Colors.green
                          : z.fishActivityScore >= 50
                              ? Colors.orange
                              : Colors.red,
                      child: Text(
                        z.fishActivityScore.toStringAsFixed(0),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    title: Text(z.name),
                    subtitle: Text(
                      'Activity: ${z.activityLabel}  •  '
                      'Density: ${z.fishDensity.toStringAsFixed(1)} /km²',
                    ),
                    trailing: z.isFishingAllowed
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.block, color: Colors.red),
                  ),
                )),
          ],

          // Quick-switch banner
          const SizedBox(height: 24),
          _SeaModeBanner(
            onSwitch: () => setState(() => _isSeaMode = true),
          ),
        ],
      ),
    );
  }

  // ── AI metric card (region-based formulas) ────────────────────────

  Widget _aiMetricCard({
    required String label,
    required String value,
    required int score,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 5,
                backgroundColor: Colors.grey[200],
                color: color,
              ),
            ),
            Text('$score',
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.teal)),
            Text(value,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressPanel(AppState appState, AppStrings s) {
    final completed = appState.completedCount;
    final simScore = appState.simulatorScore;
    const total = 5; // 5 simulator scenarios
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.progress,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.lessonsCompleted,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text('$completed',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.safetyKnowledge,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text('$simScore/$total',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? simScore / total : 0,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                color: simScore >= 4
                    ? Colors.green
                    : simScore >= 2
                        ? Colors.amber
                        : Colors.red,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _homeTabIndex = 4),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 14, color: Colors.teal[600]),
                  const SizedBox(width: 4),
                  Text(s.startSimulator,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal[600],
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromKey(String key) {
    switch (key) {
      case 'emerald':
        return Colors.green;
      case 'amber':
        return Colors.amber[600]!;
      case 'red':
        return Colors.red;
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 1 — Learning (Modules)
  // ══════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════

  List<LearningModule> get _filteredModules {
    if (_searchQuery.isEmpty) return _modules;
    return _modules.where((m) {
      return m.title.toLowerCase().contains(_searchQuery) ||
          m.summary.toLowerCase().contains(_searchQuery) ||
          m.tags.any((t) => t.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Widget _buildLearnTab() {
    return Column(
      children: [
        // State selector + search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              // State dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    isDense: true,
                    items: _coastalStates
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        _selectedState = v;
                        _loadModules();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search modules & schemes…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              isDense: true,
            ),
          ),
        ),

        // Module list
        Expanded(
          child: _modulesLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredModules.isEmpty
                  ? const Center(child: Text('No modules match your search'))
                  : RefreshIndicator(
                      onRefresh: _loadModules,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredModules.length,
                        itemBuilder: (_, i) {
                          final modules = _filteredModules;
                          return ModuleCard(
                            module: modules[i],
                            expanded: _expandedModuleIdx == i,
                            onTap: () => setState(() => _expandedModuleIdx =
                                _expandedModuleIdx == i ? -1 : i),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _loadModules() async {
    setState(() => _modulesLoading = true);
    try {
      final pos = await _gps.getCurrentPosition();
      final env = await _envModel.fetchLiveConditions(
        lat: pos.latitude,
        lon: pos.longitude,
      );
      final modules = await _envModel.fetchLearningModules(
        state: _selectedState,
        envData: env,
      );
      setState(() {
        _modules = modules;
        _modulesLoading = false;
      });
    } catch (_) {
      setState(() {
        _modules = defaultLearningModules();
        _modulesLoading = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 2 — News
  // ══════════════════════════════════════════════════════════

  Widget _buildNewsTab() {
    if (_newsArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.newspaper, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No news articles available'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refreshNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final staleLabel = _newsService.isCacheStale() ? '  (cached)' : '';
    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.newspaper, size: 22),
              const SizedBox(width: 8),
              Text(
                'Marine News$staleLabel',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_newsService.lastFetchedAt != null)
                Text(
                  _timeAgo(_newsService.lastFetchedAt!),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._newsArticles.map((a) => NewsCard(article: a)),
        ],
      ),
    );
  }

  Future<void> _refreshNews() async {
    final news = await _newsService.fetchNews();
    setState(() => _newsArticles = news);
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 3 — Government Schemes
  // ══════════════════════════════════════════════════════════

  List<GovernmentScheme> get _filteredSchemes {
    var schemes = governmentSchemes.toList();
    if (_selectedSchemeCategory != null) {
      schemes =
          schemes.where((s) => s.category == _selectedSchemeCategory).toList();
    }
    if (_searchQuery.isEmpty) return schemes;
    return schemes.where((s) {
      return s.name.toLowerCase().contains(_searchQuery) ||
          s.description.toLowerCase().contains(_searchQuery) ||
          s.ministry.toLowerCase().contains(_searchQuery) ||
          s.category.label.toLowerCase().contains(_searchQuery) ||
          s.benefits.any((b) => b.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Widget _buildSchemesTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search government schemes…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              isDense: true,
            ),
          ),
        ),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              CategoryChip(
                label: 'All',
                selected: _selectedSchemeCategory == null,
                onTap: () => setState(() => _selectedSchemeCategory = null),
              ),
              ...SchemeCategory.values.map(
                (c) => CategoryChip(
                  label: c.label,
                  icon: c.icon,
                  selected: _selectedSchemeCategory == c,
                  onTap: () => setState(() => _selectedSchemeCategory =
                      _selectedSchemeCategory == c ? null : c),
                ),
              ),
            ],
          ),
        ),

        // Scheme list
        Expanded(
          child: _filteredSchemes.isEmpty
              ? const Center(child: Text('No schemes match your search'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _filteredSchemes.length,
                  itemBuilder: (_, i) {
                    final schemes = _filteredSchemes;
                    return SchemeCard(
                      scheme: schemes[i],
                      expanded: _expandedSchemeIdx == i,
                      onTap: () => setState(() => _expandedSchemeIdx =
                          _expandedSchemeIdx == i ? -1 : i),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  Sea Pack download
  // ══════════════════════════════════════════════════════════

  Widget _buildSeaPackCard() {
    final hasPack = _offlineData.hasSeaPack;
    final stale = _offlineData.isSeaPackStale;

    return Card(
      color: hasPack && !stale ? Colors.teal.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasPack ? Icons.cloud_done : Icons.cloud_download,
                  color: hasPack && !stale ? Colors.teal : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasPack ? 'Sea Pack Ready' : 'Offline Sea Pack',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _offlineData.seaPackSummary,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (stale && hasPack)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Pack is older than 24 h — consider refreshing.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _downloadingPack
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download),
                label: Text(_downloadingPack
                    ? 'Downloading…'
                    : hasPack
                        ? 'Refresh Sea Pack'
                        : 'Download Sea Pack'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _downloadingPack ? null : _downloadSeaPack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadSeaPack() async {
    setState(() => _downloadingPack = true);
    try {
      final predictions = _predictedZones;
      final env = _envData;
      if (env == null) throw Exception('No environmental data available.');

      final ports = _portService.ports;
      final restricted = _offlineData.getCachedRestrictedZones();

      final receipt = await _offlineData.downloadSeaPack(
        predictions: predictions,
        envData: env,
        ports: ports,
        restricted: restricted,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sea Pack saved — $receipt'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPack = false);
    }
  }

  // ══════════════════════════════════════════════════════════
  //  SOS handler
  // ══════════════════════════════════════════════════════════

  Future<void> _handleSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send SOS?'),
        content:
            const Text('This will alert emergency contacts and the coast guard '
                'with your current location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _sosService.triggerSos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.anySucceeded
                ? 'SOS sent successfully'
                : 'SOS failed — please call 1554 directly'),
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════

  Widget _conditionTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, size: 32),
      title: Text(label),
      trailing: Text(value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return Colors.green;
      case RiskLevel.moderate:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  Color _suitabilityColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.lightGreen;
    if (score >= 25) return Colors.orange;
    return Colors.red;
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ══════════════════════════════════════════════════════════
//  Mode Toggle Widget
// ══════════════════════════════════════════════════════════

/// Pill-shaped Home ↔ Sea mode toggle for the AppBar.
class _ModeToggle extends StatelessWidget {
  final bool isSeaMode;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isSeaMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip(Icons.home_rounded, 'Home', !isSeaMode, () => onChanged(false)),
          _chip(Icons.sailing_rounded, 'Sea', isSeaMode, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.28) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Sea Mode Banner (quick-switch from Dashboard tab)
// ══════════════════════════════════════════════════════════

/// A prominent card shown at the bottom of the Dashboard tab
/// inviting the user to switch to Sea Mode.
class _SeaModeBanner extends StatelessWidget {
  final VoidCallback onSwitch;
  const _SeaModeBanner({required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onSwitch,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.sailing,
                    color: Colors.tealAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Switch to Sea Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPS navigation • Fishing spots • SOS • Alerts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.tealAccent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
