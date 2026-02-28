import 'package:flutter/material.dart';
import 'sea_mode_screen.dart';
import 'learning_screen.dart';
import '../services/gps_service.dart';
import '../services/port_service.dart';
import '../services/sos_service.dart';
import '../services/offline_data_service.dart';
import '../ai/fishing_prediction_service.dart';
import '../ai/environmental_model_service.dart';
import '../ai/marine_intelligence_service.dart';
import '../models/environmental_data.dart';
import '../models/fishing_zone.dart';
import '../services/news_service.dart';

/// Landing screen — shows current conditions, risk meter, and navigation
/// to Sea Mode and Learning screens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _gps = GpsService();
  late final PortService _portService;
  late final SosService _sosService;
  late final OfflineDataService _offlineData;
  late final FishingPredictionService _prediction;
  late final EnvironmentalModelService _envModel;
  late final MarineIntelligenceService _intelligence;

  late final NewsService _newsService;

  EnvironmentalData? _envData;
  List<FishingZone> _predictedZones = [];
  List<MarineNewsArticle> _newsArticles = [];
  bool _loading = true;
  bool _downloadingPack = false;
  String? _error;

  static const _backendUrl = 'http://localhost:3000';

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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _offlineData.init();
      await _newsService.init();
      await _portService.loadPorts();

      final pos = await _gps.getCurrentPosition();

      // Unified intelligence pipeline: fetch → evaluate → predict → score
      final result = await _intelligence.assess(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      // Fetch news in parallel (non-blocking for the main pipeline)
      final news = await _newsService.fetchNews();

      setState(() {
        _envData = result.environmentalData;
        _predictedZones = result.rankedZones.map((s) => s.zone).toList();
        _newsArticles = news;
        _loading = false;
      });
    } catch (e) {
      // Try offline data
      final cached = await _offlineData.getCachedEnvironmentalData();
      final cachedZones = await _offlineData.getCachedPredictions();
      final cachedNews = _newsService.getCachedNews();
      setState(() {
        _envData = cached;
        _predictedZones = cachedZones;
        _newsArticles = cachedNews;
        _loading = false;
        _error = cached == null ? e.toString() : null;
      });
    }
  }

  @override
  void dispose() {
    _gps.dispose();
    _newsService.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────
  //  UI
  // ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fisherman EduSea'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.red),
            tooltip: 'SOS',
            onPressed: _handleSos,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildDashboard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sailing), label: 'Sea Mode'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final env = _envData!;
    final risk = env.risk;

    return RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Risk card
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

          // Conditions grid
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

          // Environmental Suitability card
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

          // AI Prediction card
          if (_predictedZones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('AI Fishing Prediction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // ── Download Sea Pack ──
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

          // ── Marine News ────────────────────────────────────
          if (_newsArticles.isNotEmpty) ..._buildNewsSection(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  //  Marine News section
  // ──────────────────────────────────────

  List<Widget> _buildNewsSection() {
    final staleLabel = _newsService.isCacheStale() ? ' (cached)' : '';
    return [
      const SizedBox(height: 24),
      Row(
        children: [
          const Icon(Icons.newspaper, size: 22),
          const SizedBox(width: 8),
          Text(
            'Marine News$staleLabel',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_newsService.lastFetchedAt != null)
            Text(
              _timeAgo(_newsService.lastFetchedAt!),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
      const SizedBox(height: 8),
      ..._newsArticles.map((article) => NewsCard(article: article)),
    ];
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

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

  // ──────────────────────────────────────
  //  Download Sea Pack
  // ──────────────────────────────────────

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
      // Gather all data needed for offline Sea Mode.
      final predictions = _predictedZones;
      final env = _envData;
      if (env == null) throw Exception('No environmental data available.');

      // Ports & restricted zones from their respective services.
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
            content: Text(
              'Sea Pack saved — $receipt',
            ),
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

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SeaModeScreen()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LearningScreen()));
    }
  }

  Future<void> _handleSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send SOS?'),
        content: const Text(
            'This will alert emergency contacts and the coast guard with your location.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
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
}

// ══════════════════════════════════════════════════════════
//  _NewsCard — displays a single marine news article
// ══════════════════════════════════════════════════════════

class NewsCard extends StatelessWidget {
  final MarineNewsArticle article;

  const NewsCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source + timestamp
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.source,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(article.publishedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              article.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: 6),

            // Summary
            Text(
              article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),

            // Tags
            if (article.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: article.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$tag',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
