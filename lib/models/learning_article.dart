// ══════════════════════════════════════════════════════════
//  ArticleCategory  –  top-level topic grouping
// ══════════════════════════════════════════════════════════

enum ArticleCategory {
  marineEcosystem,
  sustainableFishing,
  safety,
  weatherNavigation,
  aiTechnology,
  governmentPolicy;

  String get label {
    switch (this) {
      case ArticleCategory.marineEcosystem:
        return 'Marine Ecosystem';
      case ArticleCategory.sustainableFishing:
        return 'Sustainable Fishing';
      case ArticleCategory.safety:
        return 'Safety';
      case ArticleCategory.weatherNavigation:
        return 'Weather & Navigation';
      case ArticleCategory.aiTechnology:
        return 'AI Technology';
      case ArticleCategory.governmentPolicy:
        return 'Government Policy';
    }
  }
}

// ══════════════════════════════════════════════════════════
//  LearningArticle  –  immutable content piece
// ══════════════════════════════════════════════════════════

class LearningArticle {
  /// Unique stable identifier (used as Hive key for custom articles).
  final String id;
  final String title;

  /// One-to-two sentence overview shown in cards.
  final String summary;

  /// Full Markdown body rendered in the reader view.
  final String body;

  final ArticleCategory category;

  /// Searchable topic keywords.
  final List<String> tags;

  /// 1 = beginner … 5 = expert.
  final int difficulty;

  /// Approximate reading time in minutes.
  final int estimatedReadMinutes;

  /// Optional deep-link or reference URL.
  final String? sourceUrl;

  const LearningArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.tags,
    required this.difficulty,
    required this.estimatedReadMinutes,
    this.sourceUrl,
  });

  // ── Serialisation ────────────────────────────────────────

  factory LearningArticle.fromJson(Map<String, dynamic> json) {
    return LearningArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      body: json['body'] as String,
      category: ArticleCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ArticleCategory.marineEcosystem,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] as int? ?? 1,
      estimatedReadMinutes: json['estimatedReadMinutes'] as int? ?? 3,
      sourceUrl: json['sourceUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'body': body,
        'category': category.name,
        'tags': tags,
        'difficulty': difficulty,
        'estimatedReadMinutes': estimatedReadMinutes,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
      };
}

// ══════════════════════════════════════════════════════════
//  Built-in catalogue  –  fully offline, hard-coded
//  All entries are `const`-safe and require no network.
// ══════════════════════════════════════════════════════════

const builtinArticles = <LearningArticle>[
  // ── Marine Ecosystem ──────────────────────────────────
  LearningArticle(
    id: 'eco_sst_01',
    title: 'Understanding Sea Surface Temperature (SST)',
    summary: 'SST directly influences fish migration patterns. Warmer waters '
        '(28–30 °C) around the Indian coast attract pelagic species like '
        'mackerel and sardines.',
    body: '## What is SST?\n\n'
        'Sea Surface Temperature (SST) is the water temperature measured at '
        'the very top layer of the ocean, typically the upper 1 mm. It is '
        'measured continuously by polar-orbiting satellites (MODIS, VIIRS) '
        'and by weather buoys anchored across the ocean.\n\n'
        '## Why Does SST Matter for Fishermen?\n\n'
        'Fish are ectotherms (cold-blooded), meaning their body temperature '
        'matches the surrounding water. Each species has a preferred '
        'temperature band:\n\n'
        '| Species | Preferred SST |\n'
        '|---------|---------------|\n'
        '| Indian Mackerel | 25 – 29 °C |\n'
        '| Oil Sardine | 24 – 28 °C |\n'
        '| Tuna (Skipjack) | 22 – 30 °C |\n'
        '| Pomfret | 22 – 27 °C |\n\n'
        '## Reading an SST Map\n\n'
        '1. **Blue zones** (< 24 °C) — nutrients are deep; fish less abundant '
        'at surface.\n'
        '2. **Green zones** (24 – 28 °C) — productive band; most Indian coast '
        'fish aggregate here.\n'
        '3. **Red/orange zones** (> 30 °C) — marine heat stress; fish dive '
        'deep or migrate away.\n\n'
        '## Upwelling — The Fisherman\'s Gold Mine\n\n'
        'When cold, nutrient-rich water rises from the deep (upwelling), SST '
        'drops 2–4 °C below surroundings. These cold patches attract plankton '
        '→ bait fish → large predator fish.\n\n'
        '**Tip:** On INCOIS ESSO maps, look for a sharp temperature gradient '
        '(≥ 1 °C / 10 km). This "thermal front" is a prime trawling zone.',
    category: ArticleCategory.marineEcosystem,
    tags: ['SST', 'fish behaviour', 'marine ecosystem', 'upwelling'],
    difficulty: 1,
    estimatedReadMinutes: 5,
    sourceUrl: 'https://incois.gov.in/portal/osf/sst.jsp',
  ),
  LearningArticle(
    id: 'eco_chloro_02',
    title: 'Chlorophyll-a and Phytoplankton Blooms',
    summary:
        'Chlorophyll concentration indicates phytoplankton density — the base '
        'of the oceanic food chain and a reliable indicator of fish aggregation '
        'zones.',
    body: '## The Ocean Food Chain\n\n'
        'Phytoplankton (microscopic algae) are the **primary producers** of '
        'the sea. They convert sunlight + CO₂ + nutrients into organic matter, '
        'feeding zooplankton, which in turn feed small fish, and up the chain '
        'to the species fishermen target.\n\n'
        '## Chlorophyll-a as an Indicator\n\n'
        'Chlorophyll-a (Chl-a) is the green pigment used for photosynthesis. '
        'Satellite sensors (MODIS-Aqua, OCM-3 on EOS-06) measure ocean colour '
        'reflectance and derive Chl-a concentration in mg/m³.\n\n'
        '| Chl-a (mg/m³) | Productivity | Likely Species |\n'
        '|---------------|-------------|----------------|\n'
        '| < 0.1 | Very low | Open-ocean tuna |\n'
        '| 0.1 – 0.5 | Moderate | Mixed pelagics |\n'
        '| 0.5 – 2.0 | High | Sardine, mackerel |\n'
        '| > 2.0 | Very high (bloom) | Anchovies, herring |\n\n'
        '## How to Use Chl-a Maps\n\n'
        '1. Download weekly Chl-a composites from INCOIS Potential Fishing '
        'Zone (PFZ) advisories.\n'
        '2. Overlay with SST — the **convergence** of a thermal front and a '
        'high Chl-a patch is the ideal fishing location.\n'
        '3. Remember: blooms dissipate quickly. Always use the latest 3-day '
        'composite.\n\n'
        '## Caution\n\n'
        'A very high Chl-a (> 5 mg/m³) often indicates a **harmful algal '
        'bloom (HAB)**. These can be toxic to fish and humans. Avoid harvesting '
        'shellfish from HAB-affected waters.',
    category: ArticleCategory.marineEcosystem,
    tags: ['chlorophyll', 'phytoplankton', 'fish behaviour', 'ocean colour'],
    difficulty: 2,
    estimatedReadMinutes: 6,
    sourceUrl: 'https://incois.gov.in/portal/pfz/pfz.jsp',
  ),

  // ── Weather & Navigation ───────────────────────────────
  LearningArticle(
    id: 'wx_wave_01',
    title: 'Reading Wave & Wind Conditions Before Departure',
    summary:
        'Understanding wave height and wind speed helps plan safer trips and '
        'avoid capsizing risks.',
    body: '## The Safety Risk Formula\n\n'
        'Our AI system computes a **Risk Score** before each trip:\n\n'
        '```\nRisk Score = 15 × Wave Height (m) + 0.8 × Wind Speed (km/h)\n```\n\n'
        '| Score | Level | Advice |\n'
        '|-------|-------|--------|\n'
        '| < 30 | Safe ✅ | Normal operations |\n'
        '| 30 – 59 | Moderate ⚠️ | Small craft advisory; avoid night trips |\n'
        '| ≥ 60 | High 🔴 | Stay ashore; life risk |\n\n'
        '## Wave Height\n\n'
        '- **Significant Wave Height (SWH)** is the average height of the '
        'highest one-third of waves over 20 minutes.\n'
        '- Traditional craft (OBM < 20 ft): safe limit ≤ 1.5 m SWH.\n'
        '- Mechanised trawler (30–40 ft): safe limit ≤ 2.5 m SWH.\n'
        '- Never venture out above your craft\'s certified wave limit.\n\n'
        '## Wind Speed & Direction\n\n'
        '- Beaufort scale 1–3 (< 29 km/h): ideal for small boats.\n'
        '- Beaufort 4–5 (29–61 km/h): advisory zone.\n'
        '- Beaufort 6+ (> 62 km/h): gale conditions; stay port.\n'
        '- Watch for **sea breeze reversal** (afternoon onshore wind); '
        'plan return trips before 14:00.\n\n'
        '## Pre-Departure Checklist\n\n'
        '1. ☑ Check INCOIS daily marine forecast (iNWS app or 1800-425-0226).\n'
        '2. ☑ Note cyclone and depression advisories from IMD.\n'
        '3. ☑ Carry VHF radio (channel 16 for distress).\n'
        '4. ☑ File departure notice with Fisheries Department or harbour master.',
    category: ArticleCategory.weatherNavigation,
    tags: ['safety', 'waves', 'wind', 'weather', 'risk'],
    difficulty: 1,
    estimatedReadMinutes: 5,
    sourceUrl: 'https://incois.gov.in/portal/ww/wwf.jsp',
  ),
  LearningArticle(
    id: 'wx_navic_02',
    title: 'Using NavIC for Offshore Navigation',
    summary: 'NavIC — India\'s own satellite navigation system — provides 5-m '
        'accuracy and sends emergency warnings directly to equipped receivers '
        'installed on fishing boats.',
    body: '## What is NavIC?\n\n'
        'NavIC (Navigation with Indian Constellation) is ISRO\'s regional '
        'satellite navigation system, covering India and 1,500 km beyond its '
        'borders. It uses 8 satellites in geostationary (GEO) and '
        'geosynchronous inclined (GSO) orbits.\n\n'
        '## Why Better Than GPS for Fishermen?\n\n'
        '| Feature | GPS | NavIC |\n'
        '|---------|-----|-------|\n'
        '| Coverage | Global | India + Indian Ocean |\n'
        '| Horizontal accuracy | ~10 m | ~5 m |\n'
        '| Distress messaging | No | **Yes — two-way** |\n'
        '| Cyclone alert push | No | **Yes** |\n\n'
        '## NavIC Receivers on Fishing Boats\n\n'
        'The Government of India has been distributing free NavIC-equipped '
        'transponders through the Fisheries Department. The device:\n\n'
        '- Displays vessel position and waypoints.\n'
        '- Receives **cyclone and high-sea alerts** directly from INCOIS.\n'
        '- Has a **panic button** that transmits SOS with GPS coordinates to '
        'Coast Guard and MRCC Mumbai/Chennai.\n\n'
        '## How to Contact the Coast Guard via NavIC\n\n'
        '1. Press and hold the red SOS button for 3 seconds.\n'
        '2. The MRCC receives position, vessel ID, and alert code.\n'
        '3. Acknowledge messages by pressing the tick (✓) button.\n'
        '4. MRCC will respond within 5 minutes.\n\n'
        '**Helpline:** MRCC Mumbai: +91-22-2150-4440\nCoast Guard Distress: 1554',
    category: ArticleCategory.weatherNavigation,
    tags: ['NavIC', 'navigation', 'GPS', 'SOS', 'ISRO'],
    difficulty: 2,
    estimatedReadMinutes: 6,
  ),

  // ── Sustainable Fishing ────────────────────────────────
  LearningArticle(
    id: 'sus_practices_01',
    title: 'Sustainable Fishing Practices',
    summary: 'Follow catch limits, choose the right net mesh size, and respect '
        'breeding-season bans to protect our fisheries for the next generation.',
    body: '## Why Sustainability Matters\n\n'
        'Over the last 30 years, global fish stocks have declined by 30 %. '
        'The Arabian Sea and Bay of Bengal, once among the most productive '
        'fishing grounds, show signs of overfishing in coastal zones.\n\n'
        '## The Five Key Principles\n\n'
        '### 1. Mesh Size\n'
        '- Minimum 20 mm for trawl nets (to allow juveniles to escape).\n'
        '- 45 mm for gill nets targeting pomfret and seer fish.\n'
        '- "Mono-filament" (nylon) nets < 16 mm are **illegal** in most states.\n\n'
        '### 2. Monsoon Ban (June – August)\n'
        '- A 47-day ban is enforced on mechanised trawling along the East Coast '
        '(June 15 – July 31) and West Coast (June 1 – July 31).\n'
        '- Fine for violation: ₹25,000 – ₹5 lakh + vessel impoundment.\n\n'
        '### 3. By-catch Reduction\n'
        '- Use Turtle Excluder Devices (TEDs) on trawl nets.\n'
        '- Release juvenile fish, turtle, and dolphin immediately.\n\n'
        '### 4. Catch-Per-Unit-Effort (CPUE) Monitoring\n'
        '- If your catch per trip has dropped > 30 % vs same season last year, '
        'move to a different ground or reduce effort by one trip per week.\n\n'
        '### 5. IUU (Illegal, Unreported, Unregulated) Fishing\n'
        '- Log all catches in the FRAS (Fisheries Resource Assessment Survey) '
        'mobile app.\n'
        '- Report sightings of illegal boats to Coast Guard (1554).',
    category: ArticleCategory.sustainableFishing,
    tags: ['sustainability', 'regulations', 'mesh size', 'ban period'],
    difficulty: 2,
    estimatedReadMinutes: 7,
  ),
  LearningArticle(
    id: 'sus_mcs_02',
    title: 'Marine Conservation Zones & Restricted Waters',
    summary:
        'India\'s 7,500 km coastline includes Marine Protected Areas (MPAs) '
        'and ecologically sensitive zones where fishing is restricted or '
        'banned to protect coral reefs, mangroves, and biodiversity.',
    body: '## Types of Marine Protected Areas\n\n'
        '| Type | Restriction Level | Examples |\n'
        '|------|------------------|----------|\n'
        '| Marine National Park | No fishing/entry | Gulf of Mannar, Mahatma Gandhi MNP |\n'
        '| Marine Sanctuary | No trawling; limited traditional fishing | Malvan, Gahirmatha |\n'
        '| Ecologically Sensitive Area (ESA) | Regulated use | Lakshadweep, Andamans |\n'
        '| Coastal Regulation Zone I (CRZ-I) | No construction; fishing allowed | All coasts |\n\n'
        '## Why Are These Zones Protected?\n\n'
        '- **Coral Reefs**: Home to 25 % of all marine species; extremely '
        'sensitive to trawl damage and anchor dragging.\n'
        '- **Mangroves**: Nursery habitat for 80 % of commercial fish species '
        'along Indian coasts.\n'
        '- **Sea Turtles**: 5 of 7 species nest on Indian beaches; protected '
        'under Wildlife Protection Act 1972.\n\n'
        '## How to Identify Restricted Zones\n\n'
        '1. Consult the sea chart issued by the Fisheries Department.\n'
        '2. Use the **EduSea app** — zones are shown as red polygons on the '
        'live map with an alert when you approach within 1 km.\n'
        '3. Call the District Fisheries Officer or check the MPEDA portal.\n\n'
        '**Penalty for fishing in MPA**: ₹5,000 – ₹50,000 + imprisonment up '
        'to 3 years under the Wildlife Protection Act.',
    category: ArticleCategory.sustainableFishing,
    tags: ['conservation', 'MPA', 'restricted zone', 'coral reef', 'mangrove'],
    difficulty: 2,
    estimatedReadMinutes: 6,
  ),

  // ── Safety ─────────────────────────────────────────────
  LearningArticle(
    id: 'safe_emergency_01',
    title: 'Emergency Procedures at Sea',
    summary:
        'What to do when your engine fails, your boat takes on water, or a '
        'crew member is injured far from shore.',
    body: '## Step 1 — Stay Calm & Assess\n\n'
        'Panic is the biggest killer in marine emergencies. Take 10 seconds '
        'to assess before acting:\n'
        '- Is the vessel sinking? If yes → **abandon ship** protocol.\n'
        '- Is there a medical emergency? → radio for medevac.\n'
        '- Is the engine dead? → anchor, then call for assistance.\n\n'
        '## Distress Signals\n\n'
        '| Method | Code / Action |\n'
        '|--------|---------------|\n'
        '| VHF Radio | Mayday × 3 on channel 16 |\n'
        '| NavIC transponder | Hold red button 3 s |\n'
        '| Flare (red parachute) | Fire vertically at night |\n'
        '| Mirror (daylight) | Flash towards aircraft/ship |\n'
        '| Orange smoke | Fire downwind in daytime |\n\n'
        '## Abandon Ship Protocol\n\n'
        '1. **Send Mayday** before leaving the vessel (position + souls on '
        'board).\n'
        '2. Don life jackets on all crew — ensure \'click\' of clip.\n'
        '3. Deploy life raft if available; board from the high side.\n'
        '4. **Stay with the vessel** if it is still floating — it is easier '
        'to spot than a raft.\n'
        '5. Use a whistle, mirror, or torch to attract rescuers.\n\n'
        '## Hypothermia Prevention\n\n'
        'In the Arabian Sea (water temp ≥ 26 °C), hypothermia is less '
        'immediate than in cold oceans, but:\n'
        '- Stay out of water if possible (increases survival time × 3).\n'
        '- Adopt HELP (Heat Escape Lessening Position): knees to chest, arms '
        'tight to body.\n\n'
        '## Emergency Contacts\n\n'
        '- Indian Coast Guard: **1554**\n'
        '- MRCC Mumbai: +91-22-2150-4440\n'
        '- MRCC Chennai: +91-44-2583-3002\n'
        '- INCOIS Helpline: 1800-425-0226',
    category: ArticleCategory.safety,
    tags: ['emergency', 'SOS', 'Mayday', 'life jacket', 'Coast Guard'],
    difficulty: 1,
    estimatedReadMinutes: 8,
  ),
  LearningArticle(
    id: 'safe_equip_02',
    title: 'Essential Safety Equipment on Every Fishing Boat',
    summary:
        'A checklist of mandatory and recommended safety equipment for fishing '
        'vessels — from life jackets to EPIRB beacons.',
    body: '## Legally Mandatory Equipment (MMD Notification)\n\n'
        'Under the Indian Merchant Shipping (Inland Small Craft) Rules, all '
        'mechanised fishing vessels above 10 GT must carry:\n\n'
        '- Life jackets: 1 per person + 2 spare.\n'
        '- Fire extinguisher: 1 × 5 kg DCP.\n'
        '- Distress flares: 4 red handheld + 2 parachute rockets.\n'
        '- VHF radio transceiver (waterproof, channels 16/70).\n'
        '- First aid kit (Min. 35-item kit as per Guidelines 2019).\n'
        '- Anchor + chain (10 m minimum for < 20 ft craft).\n\n'
        '## Recommended Additional Equipment\n\n'
        '| Equipment | Purpose |\n'
        '|-----------|----------|\n'
        '| EPIRB (406 MHz) | Automatic satellite alert on capsize |\n'
        '| NavIC transponder | Two-way coastal authority communication |\n'
        '| Radar reflector | Visibility to large vessels at night |\n'
        '| Waterproof torch + spare batteries | Night signalling |\n'
        '| Emergency desalination pump | Fresh water if adrift |\n'
        '| GPS plotter (backup to NavIC) | Independent position fix |\n\n'
        '## Life Jacket Donning — 5 Seconds\n\n'
        '1. Hold jacket by collar, slip over head.\n'
        '2. Buckle chest strap — you should feel resistance.\n'
        '3. Pull crotch strap between legs and clip.\n'
        '4. Pull down on front panel to snug fit.\n'
        '5. In water: pull inflation cord (manual inflatable jackets).\n\n'
        '## Maintenance Schedule\n\n'
        '- Monthly: Inspect jacket fabric, bladder inflation, whistle.\n'
        '- 6-Monthly: Service EPIRB (battery + hydrostatic release).\n'
        '- Annually: Replace flares (check expiry date on packaging).',
    category: ArticleCategory.safety,
    tags: ['life jacket', 'EPIRB', 'VHF radio', 'safety equipment'],
    difficulty: 1,
    estimatedReadMinutes: 7,
  ),

  // ── AI Technology ───────────────────────────────────────
  LearningArticle(
    id: 'ai_pfz_01',
    title: 'How AI Predicts Potential Fishing Zones (PFZ)',
    summary: 'Machine-learning models combine satellite SST, chlorophyll, wave '
        'height, and historical catch data to score fishing zones 1–100.',
    body: '## What is a PFZ Advisory?\n\n'
        'A Potential Fishing Zone (PFZ) advisory is a daily spatial forecast '
        'that identifies hotspots where fish concentrations are likely to be '
        'high, based on environmental conditions.\n\n'
        '## Data Inputs to the Model\n\n'
        '| Sensor | Variable | Refresh |\n'
        '|--------|----------|---------|\n'
        '| MODIS Aqua/Terra | SST, Chl-a | Daily |\n'
        '| NOAA WAVEWATCH III | Wave height, period | 6-hourly |\n'
        '| ERA5 Reanalysis | Wind speed/direction | Hourly |\n'
        '| CMEMS | Sea-level anomaly, currents | 3-hourly |\n'
        '| Historical logbooks | Species-wise catch data | Seasonal |\n\n'
        '## How the Score is Calculated\n\n'
        '```\nZone Score = \n  w₁ × SST_suitability +\n'
        '  w₂ × Chlorophyll_index +\n'
        '  w₃ × Wind_penalty +\n'
        '  w₄ × Wave_penalty +\n'
        '  w₅ × Historical_cpue\n```\n\n'
        'Weights (w₁–w₅) are trained using 10 years of CMFRI catch data, '
        'optimised with a Gradient Boosted Tree (XGBoost) model.\n\n'
        '## Interpreting the Score\n\n'
        '- **> 70** (Green pin): High probability — fish aggregation likely.\n'
        '- **40 – 70** (Amber pin): Moderate — worth exploring.\n'
        '- **< 40** (Red pin): Low — conditions unfavourable.\n\n'
        '## Limitations\n\n'
        '- Training data skews toward trawl fisheries; artisanal performance '
        'may differ.\n'
        '- Cloud cover can delay SST/Chl-a by 2–4 days.\n'
        '- Biological factors (spawning aggregations) are not modelled.\n\n'
        '**Always combine AI scores with local knowledge and current conditions.**',
    category: ArticleCategory.aiTechnology,
    tags: ['AI', 'predict', 'PFZ', 'machine learning', 'satellite'],
    difficulty: 3,
    estimatedReadMinutes: 8,
    sourceUrl: 'https://incois.gov.in/portal/pfz/pfz.jsp',
  ),

  // ── Government Policy ──────────────────────────────────
  LearningArticle(
    id: 'gov_pmmsy_01',
    title: 'Pradhan Mantri Matsya Sampada Yojana (PMMSY) Overview',
    summary: 'PMMSY is a ₹20,050 crore flagship scheme (2020–2025) to double '
        'fishermen\'s income through infrastructure, technology, and welfare.',
    body: '## Scheme at a Glance\n\n'
        '| Parameter | Details |\n'
        '|-----------|----------|\n'
        '| Total Outlay | ₹20,050 crore |\n'
        '| Period | FY 2020-21 to 2024-25 |\n'
        '| Nodal Ministry | Fisheries, Animal Husbandry & Dairying |\n'
        '| Implementing Agency | NFDB + State Fisheries Depts. |\n\n'
        '## Key Components\n\n'
        '### A. Fishers\' Welfare\n'
        '- Accidental insurance cover of ₹5 lakh (Pradhan Mantri Fishermen '
        'Bima Yojana rollout).\n'
        '- Kisan Credit Card (KCC) extension to fishermen for working capital.\n\n'
        '### B. Infrastructure\n'
        '- Modernisation of 1,381 fishing harbours & fish landing centres.\n'
        '- Cold chain from vessel to market (refrigerated trucks, ice plants).\n\n'
        '### C. Post-harvest\n'
        '- Fish processing clusters near harbours.\n'
        '- Digital traceability (QR-coded fish export certificates).\n\n'
        '### D. Marine Fisheries\n'
        '- Deep-sea vessel subsidy (up to 60 % for SC/ST/women).\n'
        '- Seaweed cultivation support.\n'
        '- Open-sea cage culture pilot.\n\n'
        '## How to Apply\n\n'
        '1. Visit **pmmsy.dof.gov.in**.\n'
        '2. Select component (vessel modernisation, fish landing centre, etc.).\n'
        '3. Submit Aadhaar, fishing licence, and bank details.\n'
        '4. State Fisheries Dept. approves and disburses subsidy within 60 '
        'days.\n\n'
        '**Helpline:** 1800-425-1660 (toll-free)',
    category: ArticleCategory.governmentPolicy,
    tags: ['PMMSY', 'government scheme', 'subsidy', 'infrastructure'],
    difficulty: 2,
    estimatedReadMinutes: 7,
    sourceUrl: 'https://pmmsy.dof.gov.in',
  ),
];
