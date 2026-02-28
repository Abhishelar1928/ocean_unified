import 'package:flutter/material.dart';

import '../models/government_scheme.dart';
import '../services/gps_service.dart';
import '../ai/environmental_model_service.dart';

/// Adaptive learning screen that displays AI-generated educational modules
/// personalised to the fisherman's region and current sea conditions,
/// **plus** a searchable catalogue of Government Schemes for Fishermen
/// (insurance, boat subsidy, fuel subsidy, disaster compensation).
///
/// All scheme data is embedded as constants — works fully offline.
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  static const _backendUrl = 'http://localhost:3000';

  final _gps = GpsService();
  late final EnvironmentalModelService _envModel;
  // ── Learning modules state ──
  List<LearningModule> _modules = [];
  bool _loading = true;
  String _selectedState = 'Maharashtra';
  int _expandedModuleIdx = -1;

  // ── Search state ──
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Schemes state ──
  SchemeCategory? _selectedCategory;
  int _expandedSchemeIdx = -1;

  // ── Website-layout category filter ──
  // Maps display label → tag substring used to filter modules.
  static const _categories = [
    _Category('All', Icons.waves_rounded, Color(0xFF0077B6), null),
    _Category(
        'Marine Ecosystem', Icons.water_rounded, Color(0xFF0096C7), 'SST'),
    _Category('Sustainable Fishing', Icons.phishing_rounded, Color(0xFF2D6A4F),
        'sustainability'),
    _Category('Government Schemes', Icons.account_balance_rounded,
        Color(0xFF7B2D8B), null),
    _Category('Safety Guidelines', Icons.health_and_safety_rounded,
        Color(0xFFB5451B), 'safety'),
  ];
  int _selectedCategoryIdx = 0;

  static const _coastalStates = [
    'Maharashtra',
    'Gujarat',
    'Kerala',
    'Tamil Nadu',
    'Andhra Pradesh',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    _envModel = EnvironmentalModelService(backendUrl: _backendUrl);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _loading = true);

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
        _loading = false;
      });
    } catch (_) {
      // Fall back to default modules (offline)
      setState(() {
        _modules = _defaultModules();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gps.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Filtered data helpers
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<LearningModule> get _filteredModules {
    final cat =
        _selectedCategoryIdx > 0 ? _categories[_selectedCategoryIdx] : null;

    // Category "Government Schemes" shows no modules (schemes section covers it).
    if (cat?.tag == null && _selectedCategoryIdx == 3) return [];

    var list = _modules;

    // Apply category tag filter.
    if (cat != null && cat.tag != null) {
      list = list.where((m) {
        return m.tags.any((t) => t.toLowerCase().contains(cat.tag!));
      }).toList();
    }

    // Apply search filter.
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) {
        return m.title.toLowerCase().contains(_searchQuery) ||
            m.summary.toLowerCase().contains(_searchQuery) ||
            m.tags.any((t) => t.toLowerCase().contains(_searchQuery));
      }).toList();
    }
    return list;
  }

  List<GovernmentScheme> get _filteredSchemes {
    var schemes = governmentSchemes;
    if (_selectedCategory != null) {
      schemes = schemes.where((s) => s.category == _selectedCategory).toList();
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  UI – modern website layout
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    final schemes = _filteredSchemes;
    final modules = _filteredModules;
    final showSchemesSection =
        _selectedCategoryIdx == 0 || _selectedCategoryIdx == 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // State selector in AppBar
      appBar: AppBar(
        title: const Text('Learning Platform'),
        backgroundColor: const Color(0xFF023E8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedState,
              dropdownColor: const Color(0xFF023E8A),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _coastalStates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedState = v);
                  _loadModules();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadModules,
        child: CustomScrollView(
          slivers: [
            // ─────────────────────────────────────
            // 1. Hero banner
            // ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildHero()),

            // ─────────────────────────────────────
            // 2. Search bar
            // ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar()),

            // ─────────────────────────────────────
            // 3. Category row
            // ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildCategoryRow()),

            // ─────────────────────────────────────
            // 4. Content grid header
            // ─────────────────────────────────────
            if (modules.isNotEmpty || _loading)
              SliverToBoxAdapter(
                child: _sectionHeader(
                  icon: Icons.menu_book_rounded,
                  title: 'Learning Modules',
                  subtitle: 'Tap a card to expand and read',
                ),
              ),

            // ─────────────────────────────────────
            // 4. Content grid (2-column)
            // ─────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (modules.isEmpty && _selectedCategoryIdx != 3)
              SliverToBoxAdapter(
                child: _emptyState(
                  icon: Icons.search_off_rounded,
                  message: 'No modules match your search',
                ),
              )
            else
              _buildModuleGrid(modules),

            // ─────────────────────────────────────
            // 5. Government Schemes section
            // ─────────────────────────────────────
            if (showSchemesSection) ...[
              SliverToBoxAdapter(
                child: _sectionHeader(
                  icon: Icons.account_balance_rounded,
                  title: 'Government Schemes',
                  subtitle:
                      'Financial support, insurance & subsidies for fishermen',
                  color: const Color(0xFF6A0DAD),
                ),
              ),
              SliverToBoxAdapter(child: _buildSchemeFilters()),
              if (schemes.isEmpty)
                SliverToBoxAdapter(
                  child: _emptyState(
                    icon: Icons.policy_rounded,
                    message: 'No schemes match your search',
                  ),
                )
              else
                _buildSchemesSliver(schemes),
            ],

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Hero section
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildHero() {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF023E8A), Color(0xFF0077B6), Color(0xFF00B4D8)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative wave rings
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 40),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.06), width: 30),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.waves_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Fisherman EduSea',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Marine Learning\nPlatform',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI-curated lessons on ocean science, safety\n'
                  'regulations and government welfare schemes.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Search bar
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF023E8A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search articles, modules & schemes…',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon:
                const Icon(Icons.search_rounded, color: Color(0xFF0077B6)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 20),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Category row
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildCategoryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Browse by Topic',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2A3B),
            ),
          ),
        ),
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = _selectedCategoryIdx == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  decoration: BoxDecoration(
                    color: selected ? cat.color : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected ? cat.color : Colors.grey.withOpacity(0.2),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: cat.color.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon,
                          color: selected ? Colors.white : cat.color, size: 28),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          cat.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF1B2A3B),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Module content grid (2-column)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  SliverPadding _buildModuleGrid(List<LearningModule> modules) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _ModuleGridCard(
            module: modules[i],
            expanded: _expandedModuleIdx == i,
            onTap: () => setState(
              () => _expandedModuleIdx = _expandedModuleIdx == i ? -1 : i,
            ),
          ),
          childCount: modules.length,
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Scheme filters + expandable list
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildSchemeFilters() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CategoryChip(
              label: 'All',
              selected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            ...SchemeCategory.values.map(
              (c) => CategoryChip(
                label: c.label,
                icon: c.icon,
                selected: _selectedCategory == c,
                onTap: () => setState(() =>
                    _selectedCategory = _selectedCategory == c ? null : c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildSchemesSliver(List<GovernmentScheme> schemes) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SchemeCard(
              scheme: schemes[i],
              expanded: _expandedSchemeIdx == i,
              onTap: () => setState(
                () => _expandedSchemeIdx = _expandedSchemeIdx == i ? -1 : i,
              ),
            ),
          ),
          childCount: schemes.length,
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Shared small widgets
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = const Color(0xFF0077B6),
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2A3B),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey[600], height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Static fallback modules (offline)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<LearningModule> _defaultModules() => defaultLearningModules();
}

// ══════════════════════════════════════════════════════════
//  Category descriptor (immutable, const-safe)
// ══════════════════════════════════════════════════════════

class _Category {
  final String label;
  final IconData icon;
  final Color color;

  /// Tag substring to filter modules by (null = show all).
  final String? tag;
  const _Category(this.label, this.icon, this.color, this.tag);
}

// ══════════════════════════════════════════════════════════
//  Module grid card (2-column layout)
// ══════════════════════════════════════════════════════════

class _ModuleGridCard extends StatelessWidget {
  final LearningModule module;
  final bool expanded;
  final VoidCallback onTap;

  const _ModuleGridCard({
    required this.module,
    required this.expanded,
    required this.onTap,
  });

  /// Colour palette for the card headers, cycled by difficulty.
  static const _headerGradients = [
    [Color(0xFF0077B6), Color(0xFF00B4D8)], // blue
    [Color(0xFF2D6A4F), Color(0xFF52B788)], // green
    [Color(0xFF7B2D8B), Color(0xFFB14FC5)], // purple
    [Color(0xFFB5451B), Color(0xFFE07A5F)], // red-orange
    [Color(0xFF1D3557), Color(0xFF457B9D)], // navy
  ];

  static const _diffLabels = [
    '',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
    'Master'
  ];

  @override
  Widget build(BuildContext context) {
    final grad = _headerGradients[module.difficulty.clamp(1, 5) - 1];
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: expanded ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Coloured image-placeholder header ──
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: grad,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -18,
                    top: -18,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // Difficulty pill
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _diffLabels[module.difficulty.clamp(1, 5)],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Wave icon centred
                  Center(
                    child: Icon(
                      _iconForTags(module.tags),
                      color: Colors.white.withOpacity(0.55),
                      size: 42,
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2A3B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        module.summary,
                        maxLines: expanded ? 100 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                    // Tag row
                    Wrap(
                      spacing: 4,
                      children: module.tags
                          .take(2)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: grad[0].withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(t,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: grad[0],
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    // Read More / Close button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: grad[0], width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          expanded ? 'Close' : 'Read More',
                          style: TextStyle(
                              fontSize: 11,
                              color: grad[0],
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded content ──
            if (expanded && module.content != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Text(
                  module.content!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForTags(List<String> tags) {
    for (final t in tags) {
      final tl = t.toLowerCase();
      if (tl.contains('safety') || tl.contains('emergency')) {
        return Icons.health_and_safety_rounded;
      }
      if (tl.contains('sustain') || tl.contains('regulation')) {
        return Icons.eco_rounded;
      }
      if (tl.contains('sst') || tl.contains('temperature')) {
        return Icons.thermostat_rounded;
      }
      if (tl.contains('wave') || tl.contains('wind')) {
        return Icons.air_rounded;
      }
      if (tl.contains('ai') || tl.contains('predict')) {
        return Icons.auto_awesome_rounded;
      }
    }
    return Icons.school_rounded;
  }
}

/// Default learning modules for offline use.
List<LearningModule> defaultLearningModules() {
  return [
    LearningModule(
      title: 'Understanding Sea Surface Temperature (SST)',
      summary: 'SST directly influences fish migration patterns. Warmer waters '
          '(28–30 °C) around the Indian coast typically attract pelagic species '
          'like mackerel and sardines.',
      difficulty: 1,
      tags: ['SST', 'fish behaviour'],
      content: '### What is SST?\n\n'
          'Sea Surface Temperature is the water temperature at the top layer '
          'of the ocean. It is measured by satellites and weather buoys.\n\n'
          '### Why does it matter?\n\n'
          '- Fish are cold-blooded — they follow comfortable temperatures.\n'
          '- A sudden SST change can signal upwelling, bringing nutrients.\n'
          '- During marine heatwaves (SST > 31 °C), fish dive deeper or migrate.',
    ),
    LearningModule(
      title: 'Reading Wave & Wind Conditions',
      summary: 'Knowing how to interpret wave height and wind speed helps '
          'plan safer trips and avoid capsizing risks.',
      difficulty: 1,
      tags: ['safety', 'waves', 'wind'],
      content: '### Risk Formula\n\n'
          'Risk Score = 15 × Wave Height (m) + 0.8 × Wind Speed (km/h)\n\n'
          '| Score | Level    |\n'
          '|-------|----------|\n'
          '| < 30  | Safe     |\n'
          '| < 60  | Moderate |\n'
          '| ≥ 60  | High     |\n\n'
          'Always check conditions before departure and carry a radio.',
    ),
    LearningModule(
      title: 'Sustainable Fishing Practices',
      summary: 'Follow catch limits, choose the right net mesh size, and '
          'respect breeding-season bans to protect our fisheries.',
      difficulty: 2,
      tags: ['sustainability', 'regulations'],
      content: '### Key Principles\n\n'
          '1. **Mesh size** — never use mesh smaller than 20 mm for trawls.\n'
          '2. **Breeding season** — observe the 47-day monsoon ban (June–Aug).\n'
          '3. **By-catch** — release juvenile and non-target species.\n'
          '4. **Quota** — stay within the CPUE advisory for your region.\n\n'
          'Sustainable fishing today means fish for tomorrow.',
    ),
  ];
}

// ══════════════════════════════════════════════════════════
//  Module card widget
// ══════════════════════════════════════════════════════════

class ModuleCard extends StatelessWidget {
  final LearningModule module;
  final bool expanded;
  final VoidCallback onTap;

  const ModuleCard({
    required this.module,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  DifficultyBadge(level: module.difficulty),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(module.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              const SizedBox(height: 8),

              // Tags
              Wrap(
                spacing: 6,
                children: module.tags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),

              // Summary
              const SizedBox(height: 6),
              Text(module.summary,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),

              // Expanded content
              if (expanded && module.content != null) ...[
                const Divider(height: 24),
                Text(module.content!,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Scheme card widget
// ══════════════════════════════════════════════════════════

class SchemeCard extends StatelessWidget {
  final GovernmentScheme scheme;
  final bool expanded;
  final VoidCallback onTap;

  const SchemeCard({
    required this.scheme,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = scheme.category;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge + title
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 14, color: cat.color),
                        const SizedBox(width: 4),
                        Text(cat.label,
                            style: TextStyle(
                                color: cat.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              const SizedBox(height: 8),

              // Scheme name
              Text(scheme.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),

              // Description
              Text(scheme.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),

              // Expanded details
              if (expanded) ...[
                const Divider(height: 24),

                // Ministry
                _detailRow(Icons.account_balance, 'Ministry', scheme.ministry),
                const SizedBox(height: 8),

                // Eligibility
                _detailRow(
                    Icons.person_search, 'Eligibility', scheme.eligibility),
                const SizedBox(height: 10),

                // Benefits
                const Text('Benefits:',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                ...scheme.benefits.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: TextStyle(
                                color: cat.color, fontWeight: FontWeight.bold)),
                        Expanded(
                            child:
                                Text(b, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // How to apply
                _detailRow(
                    Icons.description, 'How to Apply', scheme.howToApply),

                if (scheme.website != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          scheme.website!,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Category filter chip
// ══════════════════════════════════════════════════════════

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Difficulty badge
// ══════════════════════════════════════════════════════════

class DifficultyBadge extends StatelessWidget {
  final int level;
  const DifficultyBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level <= 1
        ? Colors.green
        : level <= 3
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Lv $level',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
