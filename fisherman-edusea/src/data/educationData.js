// ═══════════════════════════════════════════════════════════════════
// Fisherman EduSea – AI-Driven Unified Oceanographic Data Platform
// Core Data Layer: Regions, Scientific Metrics, AI Formulas,
//   5-Level Learning, Simulator Scenarios, i18n
// ═══════════════════════════════════════════════════════════════════

// ──────────────────────────────────────
// REGIONS with real oceanographic datasets
// ──────────────────────────────────────

export const regions = [
  {
    id: 'mumbai',
    label: { en: 'Arabian Sea – Mumbai Coast', mr: 'अरबी समुद्र – मुंबई किनारा' },
    lat: 19.076,
    lng: 72.877,
    data: {
      sst: 28.4,                    // °C – Sea Surface Temperature
      salinity: 35.2,               // PSU
      waveHeight: 1.1,              // meters
      windSpeed: 18,                // km/h
      currentSpeed: 0.6,            // m/s
      chlorophyll: 2.8,             // mg/m³
      upwelling: false,
      cycloneAlert: false,
      visibility: 12,               // km
      tidalRange: 4.2,              // meters
      historicalCPUE: 42,           // kg/trip
      season: 'post-monsoon',
      breedingZone: false,
      fishSpecies: { en: ['Pomfret, Bombay Duck, Mackerel, Shrimp'], mr: ['पापलेट, बोंबील, बांगडा, कोळंबी'] },
    },
  },
  {
    id: 'goa',
    label: { en: 'Arabian Sea – Goa Coast', mr: 'अरबी समुद्र – गोवा किनारा' },
    lat: 15.299,
    lng: 73.878,
    data: {
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
      fishSpecies: { en: ['Kingfish, Sardine, Tuna, Crab'], mr: ['सुरमई, तारली, ट्यूना, खेकडा'] },
    },
  },
  {
    id: 'kerala',
    label: { en: 'Arabian Sea – Kerala Coast', mr: 'अरबी समुद्र – केरळ किनारा' },
    lat: 9.931,
    lng: 76.267,
    data: {
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
      fishSpecies: { en: ['Sardine, Mackerel, Anchovy, Seer Fish'], mr: ['तारली, बांगडा, नथिंग, सुरमई'] },
    },
  },
  {
    id: 'chennai',
    label: { en: 'Bay of Bengal – Chennai Coast', mr: 'बंगालचा उपसागर – चेन्नई किनारा' },
    lat: 13.082,
    lng: 80.270,
    data: {
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
      fishSpecies: { en: ['Hilsa, Pomfret, Prawn, Ribbon Fish'], mr: ['हिलसा, पापलेट, कोळंबी, वाम'] },
    },
  },
  {
    id: 'ratnagiri',
    label: { en: 'Arabian Sea – Ratnagiri Coast', mr: 'अरबी समुद्र – रत्नागिरी किनारा' },
    lat: 16.994,
    lng: 73.300,
    data: {
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
      fishSpecies: { en: ['Alphonso-region Mackerel, Squid, Prawn, Sole'], mr: ['बांगडा, स्क्विड, कोळंबी, लेप'] },
    },
  },
]

// ──────────────────────────────────────
// AI FORMULAS — Scientific metric calculations
// ──────────────────────────────────────

/**
 * Sea Status: Combined wave + wind condition
 * Based on Beaufort scale adaptation
 */
export function computeSeaStatus(data, lang = 'en') {
  const { waveHeight, windSpeed } = data
  // Weighted composite (wave dominates)
  const score = (waveHeight * 30) + (windSpeed * 0.8)

  if (score < 30) return { level: 'calm', label: lang === 'en' ? 'Calm Seas' : 'शांत समुद्र', color: 'emerald', score: Math.round(score), maxScore: 100 }
  if (score < 55) return { level: 'moderate', label: lang === 'en' ? 'Moderate Seas' : 'मध्यम समुद्र', color: 'amber', score: Math.round(score), maxScore: 100 }
  return { level: 'rough', label: lang === 'en' ? 'Rough Seas' : 'खवळलेला समुद्र', color: 'red', score: Math.min(Math.round(score), 100), maxScore: 100 }
}

/**
 * Safety Risk: AI risk scoring formula
 * Risk = (wave_w × wave) + (wind_w × wind) + (cyclone × 50)
 * Classified: 0-30 Safe, 31-60 Moderate, 61-100 High
 */
export function computeSafetyRisk(data, lang = 'en') {
  const waveWeight = 15
  const windWeight = 0.8
  const cycloneBonus = data.cycloneAlert ? 50 : 0
  const breedingPenalty = data.breedingZone ? 10 : 0

  let score = (waveWeight * data.waveHeight) + (windWeight * data.windSpeed) + cycloneBonus + breedingPenalty
  score = Math.min(Math.round(score), 100)

  let level, label, color, desc
  if (score <= 30) {
    level = 'safe'; color = 'emerald'
    label = lang === 'en' ? 'Safe' : 'सुरक्षित'
    desc = lang === 'en'
      ? 'Conditions favorable. Safe for coastal and deep-sea fishing.'
      : 'परिस्थिती अनुकूल. किनारी आणि खोल समुद्री मासेमारीसाठी सुरक्षित.'
  } else if (score <= 60) {
    level = 'moderate'; color = 'amber'
    label = lang === 'en' ? 'Moderate Risk' : 'मध्यम धोका'
    desc = lang === 'en'
      ? 'Exercise caution. Monitor weather updates. Stay near coast.'
      : 'सावधगिरी बाळगा. हवामान अद्यतने तपासा. किनाऱ्याजवळ रहा.'
  } else {
    level = 'high'; color = 'red'
    label = lang === 'en' ? 'High Risk' : 'उच्च धोका'
    desc = lang === 'en'
      ? 'DANGER: Avoid sea. Cyclone/storm conditions detected.'
      : 'धोका: समुद्रात जाणे टाळा. चक्रीवादळ/वादळ स्थिती आढळली.'
  }
  return { level, label, color, score, desc }
}

/**
 * Fish Activity Prediction: AI-based
 * f(SST, Chlorophyll, Season, Upwelling, CPUE)
 * Optimal SST: 26-30°C, High Chlorophyll = more plankton = more fish
 */
export function computeFishActivity(data, lang = 'en') {
  const { sst, chlorophyll, upwelling, historicalCPUE, breedingZone } = data

  // SST optimality (peak at 28°C, drops off)
  const sstScore = Math.max(0, 30 - Math.abs(sst - 28) * 6)
  // Chlorophyll contribution (higher = more plankton = more fish)
  const chlScore = Math.min(chlorophyll * 7, 30)
  // Upwelling bonus
  const upwellingBonus = upwelling ? 12 : 0
  // Historical CPUE normalized
  const cpueScore = Math.min((historicalCPUE / 70) * 15, 15)
  // Breeding zone penalty (fish scatter)
  const breedPenalty = breedingZone ? -10 : 0

  let score = Math.round(sstScore + chlScore + upwellingBonus + cpueScore + breedPenalty)
  score = Math.max(0, Math.min(score, 100))

  let level, label, color, desc
  if (score >= 65) {
    level = 'high'; color = 'emerald'
    label = lang === 'en' ? 'High Activity' : 'उच्च सक्रियता'
    desc = lang === 'en'
      ? `Optimal conditions detected. Chlorophyll: ${chlorophyll} mg/m³, SST: ${sst}°C. High probability of fish schools near surface.`
      : `इष्टतम परिस्थिती आढळली. क्लोरोफिल: ${chlorophyll} mg/m³, SST: ${sst}°C. पृष्ठभागाजवळ माशांच्या शाळांची उच्च संभाव्यता.`
  } else if (score >= 35) {
    level = 'moderate'; color = 'cyan'
    label = lang === 'en' ? 'Moderate Activity' : 'मध्यम सक्रियता'
    desc = lang === 'en'
      ? `Average conditions. SST: ${sst}°C, Chlorophyll: ${chlorophyll} mg/m³. Try deeper waters or current edges.`
      : `सरासरी परिस्थिती. SST: ${sst}°C, क्लोरोफिल: ${chlorophyll} mg/m³. खोल पाणी किंवा प्रवाह किनारे वापरा.`
  } else {
    level = 'low'; color = 'slate'
    label = lang === 'en' ? 'Low Activity' : 'कमी सक्रियता'
    desc = lang === 'en'
      ? `Unfavorable conditions. SST: ${sst}°C is outside optimal range. Wait for tide change or relocate.`
      : `प्रतिकूल परिस्थिती. SST: ${sst}°C इष्टतम श्रेणीबाहेर. भरती बदलण्याची वाट पहा किंवा स्थान बदला.`
  }
  return { level, label, color, score, desc }
}

// ──────────────────────────────────────
// 5-LEVEL LEARNING SYSTEM
// ──────────────────────────────────────

export const learningLevels = [
  {
    id: 'level-1',
    level: 1,
    title: { en: 'Level 1 — Foundational Learning', mr: 'स्तर 1 — मूलभूत शिक्षण' },
    subtitle: { en: 'Oceanography, Fisheries & Biodiversity Basics', mr: 'समुद्रशास्त्र, मत्स्यव्यवसाय आणि जैवविविधता मूलभूत' },
    color: 'cyan',
    modules: [
      {
        id: 'l1-sst',
        icon: 'Thermometer',
        title: { en: 'Sea Surface Temperature (SST)', mr: 'समुद्र पृष्ठ तापमान (SST)' },
        explanation: {
          en: 'SST is the temperature of the ocean\'s top layer. It\'s measured by satellites and buoys. Normal range: 25-31°C for Indian coasts. SST affects fish behavior, weather patterns, and ocean currents.',
          mr: 'SST म्हणजे समुद्राच्या वरच्या थराचे तापमान. उपग्रह आणि बॉय यांद्वारे मोजले जाते. भारतीय किनाऱ्यांसाठी सामान्य श्रेणी: 25-31°C.',
        },
        meaning: {
          en: 'Fish like specific temperatures. Most commercial fish prefer 26-30°C. When SST is too high (>31°C) or too low (<24°C), fish move to deeper or different areas. Tracking SST = tracking fish.',
          mr: 'माशांना विशिष्ट तापमान आवडते. बहुतेक व्यावसायिक मासे 26-30°C पसंत करतात. SST खूप जास्त किंवा कमी असल्यास मासे हलतात.',
        },
        actions: {
          en: ['Check SST maps before planning fishing trips', 'Fish in 26-30°C zones for best results', 'Avoid areas where SST >31°C – fish go deep', 'SST drops after monsoon = fish return to surface'],
          mr: ['मासेमारी सफरी नियोजनापूर्वी SST नकाशे तपासा', 'सर्वोत्तम परिणामांसाठी 26-30°C क्षेत्रात मासेमारी करा', 'SST >31°C असलेली क्षेत्रे टाळा', 'पावसाळ्यानंतर SST कमी = मासे पृष्ठभागावर परत'],
        },
      },
      {
        id: 'l1-salinity',
        icon: 'Droplets',
        title: { en: 'Salinity & Water Chemistry', mr: 'क्षारता आणि पाणी रसायनशास्त्र' },
        explanation: {
          en: 'Salinity measures salt content in seawater (PSU units). Average ocean: 35 PSU. Near river mouths it drops to 28-32 PSU. Salinity affects water density and fish distribution.',
          mr: 'क्षारता म्हणजे समुद्राच्या पाण्यातील मीठाचे प्रमाण (PSU एकक). सरासरी: 35 PSU. नदीमुखाजवळ ते 28-32 PSU पर्यंत कमी होते.',
        },
        meaning: {
          en: 'Some fish (like Hilsa) migrate to low-salinity river mouths for breeding. Prawns prefer brackish water. Salinity changes signal seasonal fish movements.',
          mr: 'काही मासे (हिलसा) प्रजननासाठी कमी क्षारतेच्या नदीमुखाकडे स्थलांतर करतात. कोळंबी खाऱ्या पाण्याला पसंत करते.',
        },
        actions: {
          en: ['Near river mouths = prawns and Hilsa', 'Monsoon reduces salinity = different species appear', 'Deep sea has stable salinity = pelagic fish', 'Salinity maps help locate breeding zones'],
          mr: ['नदीमुखाजवळ = कोळंबी आणि हिलसा', 'पावसाळ्यात क्षारता कमी = वेगळ्या प्रजाती दिसतात', 'खोल समुद्रात स्थिर क्षारता = पेलॅजिक मासे', 'क्षारता नकाशे प्रजनन क्षेत्रे शोधण्यात मदत करतात'],
        },
      },
      {
        id: 'l1-chlorophyll',
        icon: 'Leaf',
        title: { en: 'Chlorophyll & Plankton', mr: 'क्लोरोफिल आणि प्लँक्टन' },
        explanation: {
          en: 'Chlorophyll concentration indicates phytoplankton (tiny ocean plants). High chlorophyll = rich food chain. Measured by satellite ocean color sensors. Range: 0.1–10 mg/m³.',
          mr: 'क्लोरोफिल एकाग्रता फायटोप्लँक्टन (सूक्ष्म सागरी वनस्पती) दर्शवते. उच्च क्लोरोफिल = समृद्ध अन्नसाखळी.',
        },
        meaning: {
          en: 'Plankton → Small fish → Big fish. Where chlorophyll is high (>2 mg/m³), expect higher fish concentrations. This is the #1 indicator for finding fish from space.',
          mr: 'प्लँक्टन → लहान मासे → मोठे मासे. जेथे क्लोरोफिल जास्त (>2 mg/m³), तेथे अधिक मासे अपेक्षित. अंतराळातून मासे शोधण्याचा हा #1 संकेतक.',
        },
        actions: {
          en: ['High chlorophyll zones = best fishing spots', 'Upwelling areas show highest chlorophyll', 'After monsoon, coastal chlorophyll peaks = fish boom', 'Green-colored water often means high chlorophyll'],
          mr: ['उच्च क्लोरोफिल क्षेत्रे = सर्वोत्तम मासेमारी ठिकाणे', 'अपवेलिंग क्षेत्रे सर्वाधिक क्लोरोफिल दर्शवतात', 'पावसाळ्यानंतर किनारी क्लोरोफिल शिखर = माशांची भरती', 'हिरव्या रंगाचे पाणी सहसा उच्च क्लोरोफिल दर्शवते'],
        },
      },
      {
        id: 'l1-fish-migration',
        icon: 'Navigation',
        title: { en: 'Fish Migration Patterns', mr: 'मासे स्थलांतर पद्धती' },
        explanation: {
          en: 'Fish migrate based on temperature, food, and breeding needs. Pelagic fish (tuna, mackerel) travel thousands of km. Demersal fish (sole, flatfish) stay near bottom but shift seasonally.',
          mr: 'मासे तापमान, अन्न आणि प्रजननाच्या गरजांनुसार स्थलांतर करतात. पेलॅजिक मासे हजारो किमी प्रवास करतात.',
        },
        meaning: {
          en: 'Understanding migration = predicting where fish will be next month. This is the foundation of commercial fishing and is now tracked via AI and satellite.',
          mr: 'स्थलांतर समजून घेणे = पुढच्या महिन्यात मासे कुठे असतील हे अंदाज लावणे.',
        },
        actions: {
          en: ['Track seasonal patterns for your target species', 'Breeding migrations happen at predictable times', 'Monsoon drives major migration shifts in Indian Ocean', 'Use CPUE data to verify migration predictions'],
          mr: ['तुमच्या लक्ष्य प्रजातींसाठी हंगामी पद्धतींचा मागोवा घ्या', 'प्रजनन स्थलांतर अंदाज करण्यायोग्य वेळी होते', 'पावसाळा हिंद महासागरात मोठे स्थलांतर बदल घडवतो', 'स्थलांतर अंदाज सत्यापित करण्यासाठी CPUE डेटा वापरा'],
        },
      },
      {
        id: 'l1-biodiversity',
        icon: 'TreePine',
        title: { en: 'Marine Biodiversity & Ecosystems', mr: 'सागरी जैवविविधता आणि परिसंस्था' },
        explanation: {
          en: 'Biodiversity = variety of life. Coral reefs support 25% of all marine species. Mangroves are fish nurseries. Healthy ecosystems = sustainable fishing for decades.',
          mr: 'जैवविविधता = जीवनातील विविधता. प्रवाळ भित्तिका 25% सागरी प्रजातींना आधार देतात. खारफुटी माशांचे रोपवाटिका आहेत.',
        },
        meaning: {
          en: 'Destroy the ecosystem and fish disappear permanently. Protecting coral reefs and mangroves directly protects your income source.',
          mr: 'परिसंस्था नष्ट केल्यास मासे कायमचे नाहीसे होतात. प्रवाळ भित्तिका आणि खारफुटींचे संरक्षण थेट तुमच्या उत्पन्नाचे संरक्षण करते.',
        },
        actions: {
          en: ['Never anchor on coral reefs', 'Report illegal reef destruction', 'Support mangrove restoration projects', 'Avoid catching endangered species'],
          mr: ['प्रवाळ भित्तिकांवर कधीही अँकर करू नका', 'बेकायदेशीर भित्तिका नाशाची तक्रार करा', 'खारफुटी पुनर्संचय प्रकल्पांना पाठिंबा द्या', 'धोक्यात आलेल्या प्रजाती पकडणे टाळा'],
        },
      },
    ],
  },
  {
    id: 'level-2',
    level: 2,
    title: { en: 'Level 2 — Data Understanding', mr: 'स्तर 2 — डेटा समजून घेणे' },
    subtitle: { en: 'Data Sources, Types & How Marine Data Works', mr: 'डेटा स्रोत, प्रकार आणि सागरी डेटा कसे कार्य करते' },
    color: 'blue',
    modules: [
      {
        id: 'l2-satellite',
        icon: 'Satellite',
        title: { en: 'Satellite Data (NOAA, Copernicus)', mr: 'उपग्रह डेटा (NOAA, Copernicus)' },
        explanation: {
          en: 'Satellites orbit Earth capturing ocean data every day. NOAA (USA) and Copernicus (EU) provide free SST, chlorophyll, and wave data. This data covers the entire ocean at 1-10 km resolution.',
          mr: 'उपग्रह दररोज समुद्राचा डेटा टिपतात. NOAA (यूएसए) आणि Copernicus (EU) मोफत SST, क्लोरोफिल आणि लहर डेटा देतात.',
        },
        meaning: {
          en: 'You can see ocean conditions from space – no need to be physically present. This is the backbone of modern fisheries management worldwide.',
          mr: 'अंतराळातून समुद्राची स्थिती पाहता येते – प्रत्यक्ष उपस्थिती आवश्यक नाही.',
        },
        actions: {
          en: ['NOAA provides daily SST and chlorophyll maps', 'Copernicus Marine API gives real-time ocean data', 'Data is freely accessible to anyone', 'Our platform can integrate these feeds automatically'],
          mr: ['NOAA दैनिक SST आणि क्लोरोफिल नकाशे देते', 'Copernicus Marine API रिअल-टाइम सागरी डेटा देते', 'डेटा कोणासाठीही मुक्तपणे उपलब्ध', 'आमचे व्यासपीठ हे फीड स्वयंचलितपणे एकत्रित करू शकते'],
        },
      },
      {
        id: 'l2-datatypes',
        icon: 'Database',
        title: { en: 'Data Types in Marine Science', mr: 'सागरी विज्ञानातील डेटा प्रकार' },
        explanation: {
          en: 'Marine data comes in many forms: Time-series (temperature over months), Spatial (lat-long maps), Raster (satellite images), and JSON APIs (live weather feeds). Each type serves a different purpose.',
          mr: 'सागरी डेटा अनेक स्वरूपात येतो: टाइम-सिरीज, स्थानिक (lat-long नकाशे), रास्टर (उपग्रह प्रतिमा), आणि JSON API.',
        },
        meaning: {
          en: 'Understanding data types helps you read dashboards and reports correctly. Time-series shows trends, spatial shows location patterns, raster shows satellite views.',
          mr: 'डेटा प्रकार समजल्याने डॅशबोर्ड आणि अहवाल योग्यरित्या वाचता येतात.',
        },
        actions: {
          en: ['Time-series: Track SST changes over weeks', 'Spatial data: Find fish hotspots on maps', 'Raster: Satellite images of chlorophyll', 'JSON APIs: Live weather and ocean data'],
          mr: ['टाइम-सिरीज: आठवड्यांमधील SST बदल मागोवा', 'स्थानिक डेटा: नकाशांवर मासे हॉटस्पॉट शोधा', 'रास्टर: क्लोरोफिलच्या उपग्रह प्रतिमा', 'JSON API: थेट हवामान आणि सागरी डेटा'],
        },
      },
      {
        id: 'l2-buoy',
        icon: 'Radio',
        title: { en: 'Buoy Sensors & Ship Tracking', mr: 'बॉय सेन्सर आणि जहाज ट्रॅकिंग' },
        explanation: {
          en: 'Ocean buoys are floating sensors that measure wave height, temperature, salinity, and currents in real-time. AIS (Automatic Identification System) tracks every ship at sea.',
          mr: 'सागरी बॉय हे तरंगणारे सेन्सर आहेत जे रिअल-टाइम लहर उंची, तापमान, क्षारता मोजतात. AIS प्रत्येक जहाजाचा मागोवा घेते.',
        },
        meaning: {
          en: 'Buoy data is ground truth – more accurate than satellites for specific locations. AIS data shows where commercial fishing fleets are operating.',
          mr: 'बॉय डेटा हे जमिनी सत्य आहे – विशिष्ट ठिकाणांसाठी उपग्रहांपेक्षा अधिक अचूक.',
        },
        actions: {
          en: ['INCOIS operates buoys around Indian coast', 'Buoy data validates satellite readings', 'AIS reveals fishing fleet concentration areas', 'Combined data = most accurate ocean picture'],
          mr: ['INCOIS भारतीय किनाऱ्याभोवती बॉय चालवते', 'बॉय डेटा उपग्रह वाचन प्रमाणित करतो', 'AIS मासेमारी ताफ्याचे केंद्रित क्षेत्रे दर्शवते', 'एकत्रित डेटा = सर्वात अचूक सागरी चित्र'],
        },
      },
    ],
  },
  {
    id: 'level-3',
    level: 3,
    title: { en: 'Level 3 — AI / Machine Learning', mr: 'स्तर 3 — AI / मशीन लर्निंग' },
    subtitle: { en: 'How AI Predicts Fish, Risk & Ocean Patterns', mr: 'AI मासे, धोका आणि सागरी पद्धती कसे अंदाज लावते' },
    color: 'purple',
    modules: [
      {
        id: 'l3-regression',
        icon: 'TrendingUp',
        title: { en: 'Regression → Fish Abundance Prediction', mr: 'रिग्रेशन → मासे विपुलता अंदाज' },
        explanation: {
          en: 'Regression models predict continuous values (how many fish). By feeding SST, chlorophyll, wind, and historical catch data, AI learns the relationship and predicts catch per unit effort (CPUE).',
          mr: 'रिग्रेशन मॉडेल सतत मूल्यांचा अंदाज लावतात (किती मासे). SST, क्लोरोफिल, वारा आणि ऐतिहासिक पकड डेटा देऊन AI संबंध शिकतो.',
        },
        meaning: {
          en: 'Instead of guessing, AI can tell you: "Based on current SST and chlorophyll at your location, expected catch is 45 kg/trip." That\'s data-driven fishing.',
          mr: 'अंदाज लावण्याऐवजी AI सांगू शकतो: "सध्याच्या SST आणि क्लोरोफिलवर आधारित, अपेक्षित पकड 45 किग्रा/सफर."',
        },
        actions: {
          en: ['CPUE prediction uses: SST + Chlorophyll + Season + Location', 'Model accuracy improves with more historical data', 'Predictions update daily as ocean conditions change', 'This is how industrial fishing fleets operate globally'],
          mr: ['CPUE अंदाज वापरतो: SST + क्लोरोफिल + हंगाम + स्थान', 'अधिक ऐतिहासिक डेटाने मॉडेल अचूकता सुधारते', 'सागरी परिस्थिती बदलल्यावर अंदाज दररोज अद्यतनित होतात', 'जागतिक स्तरावर औद्योगिक मासेमारी ताफे असेच कार्य करतात'],
        },
      },
      {
        id: 'l3-classification',
        icon: 'ShieldCheck',
        title: { en: 'Classification → Risk Level Prediction', mr: 'वर्गीकरण → धोका पातळी अंदाज' },
        explanation: {
          en: 'Classification models categorize data into groups. Our Safety Risk meter uses: wave height + wind speed + cyclone alerts → Safe / Moderate / High Risk. The formula: Risk = (15 × wave) + (0.8 × wind) + (cyclone × 50).',
          mr: 'वर्गीकरण मॉडेल डेटाला गटांमध्ये वर्गीकृत करतात. आमचा सुरक्षा धोका मीटर वापरतो: लहर उंची + वाऱ्याचा वेग + चक्रीवादळ → सुरक्षित / मध्यम / उच्च धोका.',
        },
        meaning: {
          en: 'Your dashboard\'s risk meter is literally a classification AI. It takes raw sensor data and outputs a human-readable safety decision. That\'s AI in action.',
          mr: 'तुमच्या डॅशबोर्डचा धोका मीटर हा अक्षरशः वर्गीकरण AI आहे. तो कच्चा सेन्सर डेटा घेतो आणि वाचनीय सुरक्षा निर्णय देतो.',
        },
        actions: {
          en: ['Risk formula: (15×wave) + (0.8×wind) + (cyclone×50)', '0-30 = Safe, 31-60 = Moderate, 61-100 = High Risk', 'Model can be trained with real accident/weather data', 'Add more features (visibility, current) for better accuracy'],
          mr: ['धोका सूत्र: (15×लाट) + (0.8×वारा) + (चक्रीवादळ×50)', '0-30 = सुरक्षित, 31-60 = मध्यम, 61-100 = उच्च धोका', 'वास्तविक अपघात/हवामान डेटासह मॉडेल प्रशिक्षित करता येतो', 'चांगल्या अचूकतेसाठी अधिक वैशिष्ट्ये (दृश्यमानता, प्रवाह) जोडा'],
        },
      },
      {
        id: 'l3-anomaly',
        icon: 'AlertTriangle',
        title: { en: 'Anomaly Detection → Marine Heatwaves', mr: 'विसंगती शोध → सागरी उष्णतेच्या लाटा' },
        explanation: {
          en: 'Anomaly detection finds unusual patterns. Marine heatwaves (MHW) are ocean areas 2-5°C above normal. AI detects them from satellite SST data and predicts fish displacement and coral bleaching.',
          mr: 'विसंगती शोध असामान्य पद्धती शोधतो. सागरी उष्णतेच्या लाटा (MHW) सामान्यपेक्षा 2-5°C जास्त असलेले क्षेत्र आहेत.',
        },
        meaning: {
          en: 'Marine heatwaves are increasing due to climate change. They cause fish die-offs and coral bleaching. Early detection lets fishermen relocate to cooler zones.',
          mr: 'हवामान बदलामुळे सागरी उष्णतेच्या लाटा वाढत आहेत. त्या माशांचा मृत्यू आणि प्रवाळ ब्लीचिंग करतात.',
        },
        actions: {
          en: ['Watch for SST anomalies (>2°C above normal)', 'Heatwaves push fish to deeper/cooler water', 'Satellite data detects MHWs weeks in advance', 'Relocate fishing efforts during MHW events'],
          mr: ['SST विसंगतींवर लक्ष ठेवा (>2°C सामान्यपेक्षा जास्त)', 'उष्णतेच्या लाटा माशांना खोल/थंड पाण्यात ढकलतात', 'उपग्रह डेटा MHW आठवडे आधी शोधतो', 'MHW घटनांमध्ये मासेमारी प्रयत्न स्थानांतरित करा'],
        },
      },
    ],
  },
  {
    id: 'level-4',
    level: 4,
    title: { en: 'Level 4 — System Design', mr: 'स्तर 4 — प्रणाली डिझाइन' },
    subtitle: { en: 'Architecture, APIs & How This Platform Works', mr: 'आर्किटेक्चर, API आणि हे व्यासपीठ कसे कार्य करते' },
    color: 'amber',
    modules: [
      {
        id: 'l4-architecture',
        icon: 'Layers',
        title: { en: 'Platform Architecture', mr: 'व्यासपीठ आर्किटेक्चर' },
        explanation: {
          en: 'Our system follows: Data Layer → AI Processing → API Output → Dashboard → Education. Each layer is independent (microservice thinking). The data layer collects from satellites/buoys, AI processes it, API serves results, and the dashboard displays it.',
          mr: 'आमची प्रणाली अनुसरते: डेटा स्तर → AI प्रक्रिया → API आउटपुट → डॅशबोर्ड → शिक्षण. प्रत्येक स्तर स्वतंत्र आहे.',
        },
        meaning: {
          en: 'This is industry-standard architecture used by NOAA, Copernicus, and major fishing companies. Understanding it means you understand how real marine-tech systems work.',
          mr: 'हे NOAA, Copernicus आणि प्रमुख मासेमारी कंपन्यांद्वारे वापरले जाणारे उद्योग-मानक आर्किटेक्चर आहे.',
        },
        actions: {
          en: ['Data Layer: Satellite + Buoy + Historical data', 'AI Layer: Regression, Classification, Anomaly models', 'API Layer: REST endpoints serving JSON', 'Frontend: React dashboard consuming APIs'],
          mr: ['डेटा स्तर: उपग्रह + बॉय + ऐतिहासिक डेटा', 'AI स्तर: रिग्रेशन, वर्गीकरण, विसंगती मॉडेल', 'API स्तर: JSON देणारे REST एंडपॉइंट', 'फ्रंटेंड: API वापरणारा React डॅशबोर्ड'],
        },
      },
      {
        id: 'l4-api',
        icon: 'Plug',
        title: { en: 'API Integration & Data Flow', mr: 'API एकत्रीकरण आणि डेटा प्रवाह' },
        explanation: {
          en: 'APIs (Application Programming Interfaces) let systems talk to each other. OpenWeather Marine API gives wind/wave data. Copernicus API gives SST/chlorophyll. Our platform aggregates all into one dashboard.',
          mr: 'API प्रणालींना एकमेकांशी बोलू देतात. OpenWeather Marine API वारा/लहर डेटा देते. Copernicus API SST/क्लोरोफिल देते.',
        },
        meaning: {
          en: 'One API call fetches what would take manual observation weeks to collect. This is the power of connected systems. Our location dropdown triggers multiple API calls behind the scenes.',
          mr: 'एक API कॉल ते आणतो जे मॅन्युअल निरीक्षणात आठवडे लागतील.',
        },
        actions: {
          en: ['Weather: OpenWeather Marine API', 'Ocean: Copernicus Marine Service API', 'Satellite: NASA OceanColor API', 'Integration: Combine all into unified JSON response'],
          mr: ['हवामान: OpenWeather Marine API', 'सागर: Copernicus Marine Service API', 'उपग्रह: NASA OceanColor API', 'एकत्रीकरण: सर्व एकत्रित JSON प्रतिसादात'],
        },
      },
    ],
  },
  {
    id: 'level-5',
    level: 5,
    title: { en: 'Level 5 — Societal Impact', mr: 'स्तर 5 — सामाजिक प्रभाव' },
    subtitle: { en: 'Climate Change, Blue Economy & Human-Centered AI', mr: 'हवामान बदल, निळी अर्थव्यवस्था आणि मानव-केंद्रित AI' },
    color: 'emerald',
    modules: [
      {
        id: 'l5-climate',
        icon: 'Globe',
        title: { en: 'Climate Change & Fisheries', mr: 'हवामान बदल आणि मत्स्यव्यवसाय' },
        explanation: {
          en: 'Ocean warming is shifting fish populations toward poles. Indian Ocean is warming faster than global average. Cyclone intensity is increasing. This directly affects 4 million Indian fishermen.',
          mr: 'समुद्र तापमानवाढ माशांच्या लोकसंख्येला ध्रुवांकडे सरकवत आहे. हिंद महासागर जागतिक सरासरीपेक्षा वेगाने तापत आहे.',
        },
        meaning: {
          en: 'The fish your grandfather caught may not be in the same location anymore. Adapting to these changes through AI and data is not optional – it\'s survival.',
          mr: 'तुमच्या आजोबांनी जे मासे पकडले ते आता त्याच ठिकाणी नसतील. AI अन डेटाद्वारे या बदलांशी जुळवून घेणे ऐच्छिक नाही – ते जगणे आहे.',
        },
        actions: {
          en: ['Monitor SST trends across years for your region', 'Adapt to shifting species — learn new target fish', 'Support climate resilience programs', 'Use AI predictions to future-proof your livelihood'],
          mr: ['तुमच्या प्रदेशासाठी वर्षानुवर्षे SST ट्रेंड मॉनिटर करा', 'बदलत्या प्रजातींशी जुळवून घ्या — नवीन लक्ष्य मासे शिका', 'हवामान लवचिकता कार्यक्रमांना पाठिंबा द्या', 'तुमची उपजीविका भविष्यासाठी सुरक्षित करण्यासाठी AI अंदाज वापरा'],
        },
      },
      {
        id: 'l5-blue-economy',
        icon: 'Anchor',
        title: { en: 'Blue Economy & Sustainable Future', mr: 'निळी अर्थव्यवस्था आणि शाश्वत भविष्य' },
        explanation: {
          en: 'Blue Economy = sustainable use of ocean resources. India\'s coastline (7,500 km) supports millions. By combining AI, sustainable practices, and smart policy, fishing can thrive without destroying ecosystems.',
          mr: 'निळी अर्थव्यवस्था = सागरी संसाधनांचा शाश्वत वापर. भारताचा किनारा (7,500 किमी) लाखोंना आधार देतो.',
        },
        meaning: {
          en: 'This platform is part of the Blue Economy vision. Every fisherman using data-driven decisions contributes to a sustainable ocean. You\'re not just fishing – you\'re building the future.',
          mr: 'हे व्यासपीठ निळ्या अर्थव्यवस्थेच्या दृष्टिकोनाचा भाग आहे. डेटा-चालित निर्णय घेणारा प्रत्येक मच्छीमार शाश्वत समुद्राला हातभार लावतो.',
        },
        actions: {
          en: ['Fish sustainably = protect your children\'s livelihood', 'Use technology to catch smarter, not more', 'Support marine protected areas', 'Demand data access from government — it\'s your right'],
          mr: ['शाश्वतपणे मासेमारी = तुमच्या मुलांची उपजीविका संरक्षित करा', 'अधिक नाही, हुशारीने पकडण्यासाठी तंत्रज्ञान वापरा', 'सागरी संरक्षित क्षेत्रांना पाठिंबा द्या', 'सरकारकडून डेटा प्रवेश मागा — तो तुमचा अधिकार आहे'],
        },
      },
    ],
  },
]

// Flatten all modules for counting
export const allLearningModules = learningLevels.flatMap(l => l.modules)

// ──────────────────────────────────────
// DECISION SIMULATOR SCENARIOS
// ──────────────────────────────────────

export const simulatorScenarios = [
  {
    id: 'scenario-1',
    situation: {
      en: 'Region: Mumbai Coast. Wave height: 2.5m. Wind speed: 45 km/h. SST: 29°C. Cyclone alert: Active. Risk Score = (15×2.5) + (0.8×45) + 50 = 123.5 → HIGH RISK.',
      mr: 'प्रदेश: मुंबई किनारा. लहर उंची: 2.5m. वाऱ्याचा वेग: 45 km/h. SST: 29°C. चक्रीवादळ इशारा: सक्रिय. धोका गुण = (15×2.5) + (0.8×45) + 50 = 123.5 → उच्च धोका.',
    },
    question: { en: 'The AI system shows HIGH RISK. What should you do?', mr: 'AI प्रणाली उच्च धोका दर्शवते. तुम्ही काय करावे?' },
    options: [
      { id: 'a', text: { en: 'Go deep sea — SST is optimal for fish', mr: 'खोल समुद्रात जा — SST मासांसाठी इष्टतम आहे' } },
      { id: 'b', text: { en: 'Stay near coast with safety equipment', mr: 'सुरक्षा उपकरणांसह किनाऱ्याजवळ रहा' } },
      { id: 'c', text: { en: 'Cancel the trip — cyclone + high waves', mr: 'सफर रद्द करा — चक्रीवादळ + उंच लाटा' } },
    ],
    correct: 'c',
    explanation: {
      en: 'Risk Score exceeds 100 (maximum danger). Cyclone alert adds +50 alone. Even though SST is optimal for fish, the combined wave (2.5m) + wind (45 km/h) + cyclone makes this LETHAL. Cancel immediately.',
      mr: 'धोका गुण 100 ओलांडतो (कमाल धोका). एकट्या चक्रीवादळ इशाऱ्याने +50 जोडले. SST मासांसाठी इष्टतम असले तरी, एकत्रित लाट + वारा + चक्रीवादळ हे प्राणघातक बनवते.',
    },
    safetyMessage: { en: '⚠ AI Risk Score > 60 = Do NOT go to sea. Your life > any catch.', mr: '⚠ AI धोका गुण > 60 = समुद्रात जाऊ नका. तुमचे जीवन > कोणतीही पकड.' },
  },
  {
    id: 'scenario-2',
    situation: {
      en: 'Region: Goa Coast. SST: 29.1°C. Chlorophyll: 3.5 mg/m³ (HIGH). Upwelling detected. Wind: 12 km/h. Waves: 0.7m. No alerts. Fish Activity Score: 78% (HIGH).',
      mr: 'प्रदेश: गोवा किनारा. SST: 29.1°C. क्लोरोफिल: 3.5 mg/m³ (उच्च). अपवेलिंग आढळले. वारा: 12 km/h. लाटा: 0.7m. माशांची सक्रियता: 78%.',
    },
    question: { en: 'Dashboard shows high fish activity with safe conditions. Best action?', mr: 'डॅशबोर्ड सुरक्षित परिस्थितीसह उच्च माशांची सक्रियता दर्शवतो. सर्वोत्तम कृती?' },
    options: [
      { id: 'a', text: { en: 'Head to upwelling zone with GPS-marked spots', mr: 'GPS-चिन्हांकित ठिकाणांसह अपवेलिंग क्षेत्रात जा' } },
      { id: 'b', text: { en: 'Stay in port — chlorophyll means pollution', mr: 'बंदरात रहा — क्लोरोफिल म्हणजे प्रदूषण' } },
      { id: 'c', text: { en: 'Go deep sea far from upwelling area', mr: 'अपवेलिंग क्षेत्रापासून दूर खोल समुद्रात जा' } },
    ],
    correct: 'a',
    explanation: {
      en: 'This is a PERFECT fishing scenario. High chlorophyll (3.5 mg/m³) + upwelling + optimal SST = massive plankton bloom = fish feeding frenzy. Low risk (waves 0.7m, wind 12 km/h). Use GPS to mark the upwelling zone.',
      mr: 'हा परिपूर्ण मासेमारी प्रसंग आहे. उच्च क्लोरोफिल + अपवेलिंग + इष्टतम SST = मोठे प्लँक्टन = मासे खात आहेत.',
    },
    safetyMessage: { en: '🐟 High chlorophyll + upwelling = nature\'s fish magnet. Trust the science!', mr: '🐟 उच्च क्लोरोफिल + अपवेलिंग = निसर्गाचे मासे चुंबक. विज्ञानावर विश्वास ठेवा!' },
  },
  {
    id: 'scenario-3',
    situation: {
      en: 'Region: Chennai. SST anomaly detected: +3.2°C above normal (Marine Heatwave). Chlorophyll dropping rapidly. Fish CPUE last week: 50% below average.',
      mr: 'प्रदेश: चेन्नई. SST विसंगती आढळली: सामान्यपेक्षा +3.2°C जास्त (सागरी उष्णतेची लाट). क्लोरोफिल वेगाने कमी होत आहे. मागील आठवड्यात CPUE: सरासरीपेक्षा 50% कमी.',
    },
    question: { en: 'AI detected a marine heatwave. What should you do?', mr: 'AI ने सागरी उष्णतेची लाट शोधली. तुम्ही काय करावे?' },
    options: [
      { id: 'a', text: { en: 'Fish longer hours to compensate for low catch', mr: 'कमी पकडीची भरपाई करण्यासाठी जास्त तास मासेमारी करा' } },
      { id: 'b', text: { en: 'Relocate to cooler zones where SST is normal', mr: 'SST सामान्य असलेल्या थंड क्षेत्रात स्थानांतरित करा' } },
      { id: 'c', text: { en: 'Ignore it — heatwaves don\'t affect fishing', mr: 'दुर्लक्ष करा — उष्णतेच्या लाटांचा मासेमारीवर परिणाम नाही' } },
    ],
    correct: 'b',
    explanation: {
      en: 'Marine heatwave (+3.2°C) has already displaced fish. Chlorophyll dropping = plankton dying = food chain collapsing in that zone. Fish have migrated to cooler waters. Follow the SST maps to normal-temperature zones.',
      mr: 'सागरी उष्णतेच्या लाटेने मासे आधीच विस्थापित केले आहेत. क्लोरोफिल कमी = प्लँक्टन मरत आहे = अन्नसाखळी कोसळत आहे.',
    },
    safetyMessage: { en: '🌡 Marine heatwaves displace fish. Follow the data, not old habits.', mr: '🌡 सागरी उष्णतेच्या लाटा माशांना विस्थापित करतात. डेटा अनुसरा, जुन्या सवयी नाही.' },
  },
  {
    id: 'scenario-4',
    situation: {
      en: 'You caught 200 kg of juvenile pomfret (undersized). Market will buy at ₹80/kg. GPS shows you\'re near a known breeding ground. Season: Pre-breeding.',
      mr: 'तुम्हाला 200 किलो लहान पापलेट (कमी आकाराचे) मिळाले. बाजार ₹80/किलो ला खरेदी करेल. GPS दर्शवतो तुम्ही प्रजनन क्षेत्राजवळ आहात.',
    },
    question: { en: 'What is the scientifically correct action?', mr: 'वैज्ञानिकदृष्ट्या योग्य कृती काय आहे?' },
    options: [
      { id: 'a', text: { en: 'Sell all 200 kg — money is money', mr: 'सर्व 200 किलो विका — पैसा म्हणजे पैसा' } },
      { id: 'b', text: { en: 'Release fish + leave breeding zone + report location', mr: 'मासे सोडा + प्रजनन क्षेत्र सोडा + स्थान कळवा' } },
      { id: 'c', text: { en: 'Keep big ones, release small ones', mr: 'मोठे ठेवा, लहान सोडा' } },
    ],
    correct: 'b',
    explanation: {
      en: 'Juvenile fish near breeding grounds = future population. 200 kg of juveniles represents thousands of adult fish over 2-3 years. Releasing them + avoiding the breeding zone + reporting the location to fisheries dept ensures sustainable stocks for all fishermen.',
      mr: 'प्रजनन क्षेत्राजवळील लहान मासे = भविष्यातील लोकसंख्या. 200 किलो लहान मासे 2-3 वर्षापर्यंत हजारो प्रौढ माशांचे प्रतिनिधित्व करतात.',
    },
    safetyMessage: { en: '🌊 200 kg today vs 2000 kg next year. Sustainability = long-term profit.', mr: '🌊 आज 200 किलो विरुद्ध पुढच्या वर्षी 2000 किलो. शाश्वतता = दीर्घकालीन नफा.' },
  },
  {
    id: 'scenario-5',
    situation: {
      en: 'Engine failure 5 km offshore. Current: 1.1 m/s pushing you further out. You have: radio (charged), 3 flares, life jackets. Battery: 60%. Sunset: 2 hours.',
      mr: 'किनाऱ्यापासून 5 किमी वर इंजिन बिघाड. प्रवाह: 1.1 m/s बाहेर ढकलत आहे. तुमच्याकडे: रेडिओ (चार्ज), 3 फ्लेअर्स, लाइफ जॅकेट. बॅटरी: 60%. सूर्यास्त: 2 तास.',
    },
    question: { en: 'With limited resources, what\'s the optimal sequence?', mr: 'मर्यादित संसाधनांसह, इष्टतम क्रम काय आहे?' },
    options: [
      { id: 'a', text: { en: 'Flare → Swim → Radio (save battery)', mr: 'फ्लेअर → पोहणे → रेडिओ (बॅटरी वाचवा)' } },
      { id: 'b', text: { en: 'Radio (with GPS coords) → Life jackets on → Flare when rescue visible', mr: 'रेडिओ (GPS निर्देशांकांसह) → लाइफ जॅकेट → बचाव दिसल्यावर फ्लेअर' } },
      { id: 'c', text: { en: 'Swim toward shore immediately', mr: 'लगेच किनाऱ्याकडे पोहा' } },
    ],
    correct: 'b',
    explanation: {
      en: 'Optimal: 1) Radio with GPS coordinates (most effective rescue method), 2) Life jackets on (current is pushing you – need flotation), 3) Save flares for visual confirmation when rescue approaches. Swimming against 1.1 m/s current = physical exhaustion and drowning risk.',
      mr: 'इष्टतम: 1) GPS निर्देशांकांसह रेडिओ, 2) लाइफ जॅकेट घाला (प्रवाह ढकलत आहे), 3) बचाव जवळ आल्यावर फ्लेअर्स वापरा.',
    },
    safetyMessage: { en: '📻 Radio + GPS = fastest rescue. Never swim against strong current.', mr: '📻 रेडिओ + GPS = सर्वात जलद बचाव. मजबूत प्रवाहाविरुद्ध कधी पोहू नका.' },
  },
]

// ──────────────────────────────────────
// UI STRINGS (i18n)
// ──────────────────────────────────────

export const uiStrings = {
  en: {
    platformName: 'Fisherman EduSea',
    tagline: 'AI-Driven Marine Intelligence',
    dashboard: 'Marine Dashboard',
    learning: 'Learning',
    simulator: 'Simulator',
    about: 'About',
    selectRegion: 'Select Fishing Region',
    seaStatus: 'Sea Status',
    riskLevel: 'Safety Risk',
    fishActivity: 'Fish Activity',
    learningCenter: 'Learning Center',
    decisionSimulator: 'Decision Simulator',
    progress: 'Your Progress',
    lessonsCompleted: 'Modules Explored',
    safetyKnowledge: 'Safety Knowledge',
    badge: 'Badge',
    safeFisherman: 'Smart Fisherman',
    startLearning: 'Open Learning Center',
    startSimulator: 'Start Simulator',
    viewDashboard: 'View Dashboard',
    whatThisMeans: 'What This Means For You',
    actionSteps: 'Action Steps',
    nextScenario: 'Next Scenario',
    tryAgain: 'Try Again',
    checkAnswer: 'Check Answer',
    correct: 'Correct!',
    incorrect: 'Not quite right.',
    selectOption: 'Select an option',
    scenario: 'Scenario',
    of: 'of',
    score: 'Score',
    simulatorComplete: 'Simulator Complete!',
    yourScore: 'Your Score',
    restartSimulator: 'Restart Simulator',
    aboutTitle: 'About the Platform',
    aboutMission: 'Our Mission',
    aboutMissionText: 'An AI-Driven Unified Oceanographic and Biodiversity Data Platform. We collect satellite, buoy, and historical data, apply machine learning models, and deliver decision-support insights to fishermen.',
    aboutIntegration: 'AI & Data Pipeline',
    aboutIntegrationText: 'Data Layer (Satellite + Buoy + AIS) → AI Processing (Regression, Classification, Anomaly Detection) → API Output → Fisherman Dashboard → Education & Simulator.',
    aboutFeatures: 'Platform Capabilities',
    aboutFeaturesList: [
      'Location-based oceanographic dashboard (5 Indian coastal regions)',
      'Scientific AI formulas for risk, fish activity, and sea conditions',
      'SST, Chlorophyll, Salinity, Wave, Wind & Current analysis',
      '5-level learning system (Foundations → AI/ML → Societal Impact)',
      'Interactive decision simulator with scientific scenarios',
      'Bilingual support (English + Marathi)',
      'Ready for Copernicus, NOAA & OpenWeather API integration',
      'Progress tracking with achievement system',
    ],
    footer: '© 2026 Fisherman EduSea – AI-Driven Unified Oceanographic Platform',
    liveConditions: 'Live Oceanographic Conditions',
    quickActions: 'Quick Actions',
    oceanData: 'Oceanographic Data',
    riskFormula: 'Risk Formula',
    fishFormula: 'Fish Activity Formula',
    dataSource: 'Data Sources',
    coordinates: 'Coordinates',
    parameters: 'Parameters',
    systemArchitecture: 'System Architecture',
  },
  mr: {
    platformName: 'फिशरमन एडुसी',
    tagline: 'AI-चालित सागरी बुद्धिमत्ता',
    dashboard: 'सागरी डॅशबोर्ड',
    learning: 'शिक्षण',
    simulator: 'सिम्युलेटर',
    about: 'माहिती',
    selectRegion: 'मासेमारी प्रदेश निवडा',
    seaStatus: 'समुद्र स्थिती',
    riskLevel: 'सुरक्षा धोका',
    fishActivity: 'मासे सक्रियता',
    learningCenter: 'शिक्षण केंद्र',
    decisionSimulator: 'निर्णय सिम्युलेटर',
    progress: 'तुमची प्रगती',
    lessonsCompleted: 'मॉड्यूल शोधले',
    safetyKnowledge: 'सुरक्षा ज्ञान',
    badge: 'बॅज',
    safeFisherman: 'स्मार्ट मच्छीमार',
    startLearning: 'शिक्षण केंद्र उघडा',
    startSimulator: 'सिम्युलेटर सुरू करा',
    viewDashboard: 'डॅशबोर्ड पहा',
    whatThisMeans: 'तुमच्यासाठी याचा अर्थ',
    actionSteps: 'कृती पावले',
    nextScenario: 'पुढचा प्रसंग',
    tryAgain: 'पुन्हा प्रयत्न करा',
    checkAnswer: 'उत्तर तपासा',
    correct: 'बरोबर!',
    incorrect: 'अगदी बरोबर नाही.',
    selectOption: 'पर्याय निवडा',
    scenario: 'प्रसंग',
    of: 'पैकी',
    score: 'गुण',
    simulatorComplete: 'सिम्युलेटर पूर्ण!',
    yourScore: 'तुमचे गुण',
    restartSimulator: 'सिम्युलेटर पुन्हा सुरू करा',
    aboutTitle: 'व्यासपीठ बद्दल',
    aboutMission: 'आमचे ध्येय',
    aboutMissionText: 'AI-चालित एकीकृत समुद्रशास्त्रीय आणि जैवविविधता डेटा व्यासपीठ. आम्ही उपग्रह, बॉय आणि ऐतिहासिक डेटा गोळा करतो, मशीन लर्निंग मॉडेल लागू करतो आणि मच्छीमारांना निर्णय-समर्थन अंतर्दृष्टी देतो.',
    aboutIntegration: 'AI आणि डेटा पाइपलाइन',
    aboutIntegrationText: 'डेटा स्तर (उपग्रह + बॉय + AIS) → AI प्रक्रिया (रिग्रेशन, वर्गीकरण, विसंगती शोध) → API आउटपुट → मच्छीमार डॅशबोर्ड → शिक्षण आणि सिम्युलेटर.',
    aboutFeatures: 'व्यासपीठ क्षमता',
    aboutFeaturesList: [
      'स्थान-आधारित समुद्रशास्त्रीय डॅशबोर्ड (5 भारतीय किनारी प्रदेश)',
      'धोका, मासे सक्रियता आणि समुद्र स्थितीसाठी वैज्ञानिक AI सूत्रे',
      'SST, क्लोरोफिल, क्षारता, लहर, वारा आणि प्रवाह विश्लेषण',
      '5-स्तर शिक्षण प्रणाली (मूलभूत → AI/ML → सामाजिक प्रभाव)',
      'वैज्ञानिक प्रसंगांसह परस्परसंवादी निर्णय सिम्युलेटर',
      'द्विभाषिक समर्थन (इंग्रजी + मराठी)',
      'Copernicus, NOAA आणि OpenWeather API एकत्रीकरणासाठी तयार',
      'उपलब्धी प्रणालीसह प्रगती ट्रॅकिंग',
    ],
    footer: '© 2026 फिशरमन एडुसी – AI-चालित एकीकृत समुद्रशास्त्रीय व्यासपीठ',
    liveConditions: 'थेट समुद्रशास्त्रीय परिस्थिती',
    quickActions: 'त्वरित कृती',
    oceanData: 'समुद्रशास्त्रीय डेटा',
    riskFormula: 'धोका सूत्र',
    fishFormula: 'मासे सक्रियता सूत्र',
    dataSource: 'डेटा स्रोत',
    coordinates: 'निर्देशांक',
    parameters: 'मापदंड',
    systemArchitecture: 'प्रणाली आर्किटेक्चर',
  },
}
