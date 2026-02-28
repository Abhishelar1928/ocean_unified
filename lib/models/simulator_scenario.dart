// ═══════════════════════════════════════════════════════════════════
// Fisherman EduSea – Decision Simulator Scenarios
// Ported from fisherman-edusea/src/data/educationData.js
// ═══════════════════════════════════════════════════════════════════

class BilingualText {
  final String en;
  final String mr;
  const BilingualText({required this.en, required this.mr});
}

class SimulatorOption {
  final String id;
  final BilingualText text;
  const SimulatorOption({required this.id, required this.text});
}

class SimulatorScenario {
  final String id;
  final BilingualText situation;
  final BilingualText question;
  final List<SimulatorOption> options;
  final String correct; // option id
  final BilingualText explanation;
  final BilingualText safetyMessage;

  const SimulatorScenario({
    required this.id,
    required this.situation,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    required this.safetyMessage,
  });
}

const List<SimulatorScenario> simulatorScenarios = [
  SimulatorScenario(
    id: 'scenario-1',
    situation: BilingualText(
      en: 'Region: Mumbai Coast. Wave height: 2.5m. Wind speed: 45 km/h. SST: 29°C. Cyclone alert: Active. Risk Score = (15×2.5) + (0.8×45) + 50 = 123.5 → HIGH RISK.',
      mr: 'प्रदेश: मुंबई किनारा. लहर उंची: 2.5m. वाऱ्याचा वेग: 45 km/h. SST: 29°C. चक्रीवादळ इशारा: सक्रिय. धोका गुण = (15×2.5) + (0.8×45) + 50 = 123.5 → उच्च धोका.',
    ),
    question: BilingualText(
      en: 'The AI system shows HIGH RISK. What should you do?',
      mr: 'AI प्रणाली उच्च धोका दर्शवते. तुम्ही काय करावे?',
    ),
    options: [
      SimulatorOption(
        id: 'a',
        text: BilingualText(
          en: 'Go deep sea — SST is optimal for fish',
          mr: 'खोल समुद्रात जा — SST मासांसाठी इष्टतम आहे',
        ),
      ),
      SimulatorOption(
        id: 'b',
        text: BilingualText(
          en: 'Stay near coast with safety equipment',
          mr: 'सुरक्षा उपकरणांसह किनाऱ्याजवळ रहा',
        ),
      ),
      SimulatorOption(
        id: 'c',
        text: BilingualText(
          en: 'Cancel the trip — cyclone + high waves',
          mr: 'सफर रद्द करा — चक्रीवादळ + उंच लाटा',
        ),
      ),
    ],
    correct: 'c',
    explanation: BilingualText(
      en: 'Risk Score exceeds 100 (maximum danger). Cyclone alert adds +50 alone. Even though SST is optimal for fish, the combined wave (2.5m) + wind (45 km/h) + cyclone makes this LETHAL. Cancel immediately.',
      mr: 'धोका गुण 100 ओलांडतो (कमाल धोका). एकट्या चक्रीवादळ इशाऱ्याने +50 जोडले. SST मासांसाठी इष्टतम असले तरी, एकत्रित लाट + वारा + चक्रीवादळ हे प्राणघातक बनवते.',
    ),
    safetyMessage: BilingualText(
      en: '⚠ AI Risk Score > 60 = Do NOT go to sea. Your life > any catch.',
      mr: '⚠ AI धोका गुण > 60 = समुद्रात जाऊ नका. तुमचे जीवन > कोणतीही पकड.',
    ),
  ),
  SimulatorScenario(
    id: 'scenario-2',
    situation: BilingualText(
      en: 'Region: Goa Coast. SST: 29.1°C. Chlorophyll: 3.5 mg/m³ (HIGH). Upwelling detected. Wind: 12 km/h. Waves: 0.7m. No alerts. Fish Activity Score: 78% (HIGH).',
      mr: 'प्रदेश: गोवा किनारा. SST: 29.1°C. क्लोरोफिल: 3.5 mg/m³ (उच्च). अपवेलिंग आढळले. वारा: 12 km/h. लाटा: 0.7m. माशांची सक्रियता: 78%.',
    ),
    question: BilingualText(
      en: 'Dashboard shows high fish activity with safe conditions. Best action?',
      mr: 'डॅशबोर्ड सुरक्षित परिस्थितीसह उच्च माशांची सक्रियता दर्शवतो. सर्वोत्तम कृती?',
    ),
    options: [
      SimulatorOption(
        id: 'a',
        text: BilingualText(
          en: 'Head to upwelling zone with GPS-marked spots',
          mr: 'GPS-चिन्हांकित ठिकाणांसह अपवेलिंग क्षेत्रात जा',
        ),
      ),
      SimulatorOption(
        id: 'b',
        text: BilingualText(
          en: 'Stay in port — chlorophyll means pollution',
          mr: 'बंदरात रहा — क्लोरोफिल म्हणजे प्रदूषण',
        ),
      ),
      SimulatorOption(
        id: 'c',
        text: BilingualText(
          en: 'Go deep sea far from upwelling area',
          mr: 'अपवेलिंग क्षेत्रापासून दूर खोल समुद्रात जा',
        ),
      ),
    ],
    correct: 'a',
    explanation: BilingualText(
      en: 'This is a PERFECT fishing scenario. High chlorophyll (3.5 mg/m³) + upwelling + optimal SST = massive plankton bloom = fish feeding frenzy. Low risk (waves 0.7m, wind 12 km/h). Use GPS to mark the upwelling zone.',
      mr: 'हा परिपूर्ण मासेमारी प्रसंग आहे. उच्च क्लोरोफिल + अपवेलिंग + इष्टतम SST = मोठे प्लँक्टन = मासे खात आहेत.',
    ),
    safetyMessage: BilingualText(
      en: '🐟 High chlorophyll + upwelling = nature\'s fish magnet. Trust the science!',
      mr: '🐟 उच्च क्लोरोफिल + अपवेलिंग = निसर्गाचे मासे चुंबक. विज्ञानावर विश्वास ठेवा!',
    ),
  ),
  SimulatorScenario(
    id: 'scenario-3',
    situation: BilingualText(
      en: 'Region: Chennai. SST anomaly detected: +3.2°C above normal (Marine Heatwave). Chlorophyll dropping rapidly. Fish CPUE last week: 50% below average.',
      mr: 'प्रदेश: चेन्नई. SST विसंगती आढळली: सामान्यपेक्षा +3.2°C जास्त (सागरी उष्णतेची लाट). क्लोरोफिल वेगाने कमी होत आहे. मागील आठवड्यात CPUE: सरासरीपेक्षा 50% कमी.',
    ),
    question: BilingualText(
      en: 'AI detected a marine heatwave. What should you do?',
      mr: 'AI ने सागरी उष्णतेची लाट शोधली. तुम्ही काय करावे?',
    ),
    options: [
      SimulatorOption(
        id: 'a',
        text: BilingualText(
          en: 'Fish longer hours to compensate for low catch',
          mr: 'कमी पकडीची भरपाई करण्यासाठी जास्त तास मासेमारी करा',
        ),
      ),
      SimulatorOption(
        id: 'b',
        text: BilingualText(
          en: 'Relocate to cooler zones where SST is normal',
          mr: 'SST सामान्य असलेल्या थंड क्षेत्रात स्थानांतरित करा',
        ),
      ),
      SimulatorOption(
        id: 'c',
        text: BilingualText(
          en: 'Ignore it — heatwaves don\'t affect fishing',
          mr: 'दुर्लक्ष करा — उष्णतेच्या लाटांचा मासेमारीवर परिणाम नाही',
        ),
      ),
    ],
    correct: 'b',
    explanation: BilingualText(
      en: 'Marine heatwave (+3.2°C) has already displaced fish. Chlorophyll dropping = plankton dying = food chain collapsing in that zone. Fish have migrated to cooler waters. Follow the SST maps to normal-temperature zones.',
      mr: 'सागरी उष्णतेच्या लाटेने मासे आधीच विस्थापित केले आहेत. क्लोरोफिल कमी = प्लँक्टन मरत आहे = अन्नसाखळी कोसळत आहे.',
    ),
    safetyMessage: BilingualText(
      en: '🌡 Marine heatwaves displace fish. Follow the data, not old habits.',
      mr: '🌡 सागरी उष्णतेच्या लाटा माशांना विस्थापित करतात. डेटा अनुसरा, जुन्या सवयी नाही.',
    ),
  ),
  SimulatorScenario(
    id: 'scenario-4',
    situation: BilingualText(
      en: 'You caught 200 kg of juvenile pomfret (undersized). Market will buy at ₹80/kg. GPS shows you\'re near a known breeding ground. Season: Pre-breeding.',
      mr: 'तुम्हाला 200 किलो लहान पापलेट (कमी आकाराचे) मिळाले. बाजार ₹80/किलो ला खरेदी करेल. GPS दर्शवतो तुम्ही प्रजनन क्षेत्राजवळ आहात.',
    ),
    question: BilingualText(
      en: 'What is the scientifically correct action?',
      mr: 'वैज्ञानिकदृष्ट्या योग्य कृती काय आहे?',
    ),
    options: [
      SimulatorOption(
        id: 'a',
        text: BilingualText(
          en: 'Sell all 200 kg — money is money',
          mr: 'सर्व 200 किलो विका — पैसा म्हणजे पैसा',
        ),
      ),
      SimulatorOption(
        id: 'b',
        text: BilingualText(
          en: 'Release fish + leave breeding zone + report location',
          mr: 'मासे सोडा + प्रजनन क्षेत्र सोडा + स्थान कळवा',
        ),
      ),
      SimulatorOption(
        id: 'c',
        text: BilingualText(
          en: 'Keep big ones, release small ones',
          mr: 'मोठे ठेवा, लहान सोडा',
        ),
      ),
    ],
    correct: 'b',
    explanation: BilingualText(
      en: 'Juvenile fish near breeding grounds = future population. 200 kg of juveniles represents thousands of adult fish over 2-3 years. Releasing them + avoiding the breeding zone + reporting the location to fisheries dept ensures sustainable stocks for all fishermen.',
      mr: 'प्रजनन क्षेत्राजवळील लहान मासे = भविष्यातील लोकसंख्या. 200 किलो लहान मासे 2-3 वर्षापर्यंत हजारो प्रौढ माशांचे प्रतिनिधित्व करतात.',
    ),
    safetyMessage: BilingualText(
      en: '🌊 200 kg today vs 2000 kg next year. Sustainability = long-term profit.',
      mr: '🌊 आज 200 किलो विरुद्ध पुढच्या वर्षी 2000 किलो. शाश्वतता = दीर्घकालीन नफा.',
    ),
  ),
  SimulatorScenario(
    id: 'scenario-5',
    situation: BilingualText(
      en: 'Engine failure 5 km offshore. Current: 1.1 m/s pushing you further out. You have: radio (charged), 3 flares, life jackets. Battery: 60%. Sunset: 2 hours.',
      mr: 'किनाऱ्यापासून 5 किमी वर इंजिन बिघाड. प्रवाह: 1.1 m/s बाहेर ढकलत आहे. तुमच्याकडे: रेडिओ (चार्ज), 3 फ्लेअर्स, लाइफ जॅकेट. बॅटरी: 60%. सूर्यास्त: 2 तास.',
    ),
    question: BilingualText(
      en: 'With limited resources, what\'s the optimal sequence?',
      mr: 'मर्यादित संसाधनांसह, इष्टतम क्रम काय आहे?',
    ),
    options: [
      SimulatorOption(
        id: 'a',
        text: BilingualText(
          en: 'Flare → Swim → Radio (save battery)',
          mr: 'फ्लेअर → पोहणे → रेडिओ (बॅटरी वाचवा)',
        ),
      ),
      SimulatorOption(
        id: 'b',
        text: BilingualText(
          en: 'Radio (with GPS coords) → Life jackets on → Flare when rescue visible',
          mr: 'रेडिओ (GPS निर्देशांकांसह) → लाइफ जॅकेट → बचाव दिसल्यावर फ्लेअर',
        ),
      ),
      SimulatorOption(
        id: 'c',
        text: BilingualText(
          en: 'Swim toward shore immediately',
          mr: 'लगेच किनाऱ्याकडे पोहा',
        ),
      ),
    ],
    correct: 'b',
    explanation: BilingualText(
      en: 'Optimal: 1) Radio with GPS coordinates (most effective rescue method), 2) Life jackets on (current is pushing you – need flotation), 3) Save flares for visual confirmation when rescue approaches. Swimming against 1.1 m/s current = physical exhaustion and drowning risk.',
      mr: 'इष्टतम: 1) GPS निर्देशांकांसह रेडिओ, 2) लाइफ जॅकेट घाला (प्रवाह ढकलत आहे), 3) बचाव जवळ आल्यावर फ्लेअर्स वापरा.',
    ),
    safetyMessage: BilingualText(
      en: '📻 Radio + GPS = fastest rescue. Never swim against strong current.',
      mr: '📻 रेडिओ + GPS = सर्वात जलद बचाव. मजबूत प्रवाहाविरुद्ध कधी पोहू नका.',
    ),
  ),
];
