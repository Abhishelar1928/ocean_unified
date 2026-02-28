const axios = require("axios");
const stateCoastMap = require("../config/stateCoastMap");

const OLLAMA_URL = "http://localhost:11434/api/generate";
const MODEL = "llama3.2";

/**
 * Sea name mapping for Indian coastal states.
 */
const stateSeaMap = {
  Maharashtra: "Arabian Sea",
  Gujarat: "Arabian Sea",
  Kerala: "Arabian Sea",
  "Tamil Nadu": "Bay of Bengal",
  "Andhra Pradesh": "Bay of Bengal",
  "West Bengal": "Bay of Bengal",
};

/**
 * Personalization logic — injects priority topics based on conditions.
 */
function getPersonalizationHints(data) {
  const hints = [];
  const { sst, waveHeight, windSpeed, riskLevel } = data;

  if (riskLevel === "High") {
    hints.push(
      "PRIORITY: Include a safety-first module about surviving dangerous sea conditions."
    );
  }
  if (sst !== null && sst > 30) {
    hints.push(
      "IMPORTANT: SST is unusually high — include a topic about marine heatwaves and their effect on fish migration."
    );
  }
  if (waveHeight !== null && waveHeight > 3) {
    hints.push(
      "IMPORTANT: Wave height is very high — include a topic about navigating high wave conditions safely."
    );
  }
  if (windSpeed !== null && windSpeed > 40) {
    hints.push(
      "IMPORTANT: Wind speed is very high — include storm preparedness learning."
    );
  }
  return hints;
}

/**
 * Generates context-aware, AI-driven learning modules via Ollama.
 *
 * @param {Object} params
 * @param {string} params.state     – Indian coastal state
 * @param {number} params.sst       – Sea Surface Temperature (°C)
 * @param {number} params.waveHeight – Wave height (m)
 * @param {number} params.windSpeed  – Wind speed (km/h)
 * @param {string} params.riskLevel  – Safe/Moderate/High
 * @returns {Object} – { modules: [...], generatedAt, aiAvailable }
 */
async function generateAdaptiveLearning(params) {
  const { state, sst, waveHeight, windSpeed, riskLevel } = params;
  const sea = stateSeaMap[state] || "Indian Ocean";
  const coast = stateCoastMap[state]?.label || state;
  const hints = getPersonalizationHints(params);

  const prompt = `You are a marine science expert helping Indian fishermen learn about ocean science relevant to their daily lives.

Context — Current conditions for ${state} (${coast}, ${sea}):
- Sea Surface Temperature (SST): ${sst}°C
- Wave Height: ${waveHeight} m
- Wind Speed: ${windSpeed} km/h
- Risk Level: ${riskLevel}

${hints.length > 0 ? "Personalization directives:\n" + hints.map((h) => "• " + h).join("\n") : ""}

Generate EXACTLY 3 personalized learning modules relevant to this specific region and current conditions. Each module must be practical and understandable by fishermen with limited formal education.

Respond ONLY with valid JSON in this EXACT format (no markdown, no code fences, no explanations before or after):
{
  "modules": [
    {
      "title_en": "Topic title in English",
      "title_mr": "Topic title in Marathi",
      "explanation_en": "Clear explanation in English (max 120 words). Use simple language.",
      "explanation_mr": "Same explanation in Marathi.",
      "actionSteps_en": ["Step 1", "Step 2", "Step 3"],
      "actionSteps_mr": ["पायरी 1", "पायरी 2", "पायरी 3"],
      "tag": "safety | seasonal | informational | urgent"
    },
    {
      "title_en": "...",
      "title_mr": "...",
      "explanation_en": "...",
      "explanation_mr": "...",
      "actionSteps_en": ["..."],
      "actionSteps_mr": ["..."],
      "tag": "..."
    },
    {
      "title_en": "...",
      "title_mr": "...",
      "explanation_en": "...",
      "explanation_mr": "...",
      "actionSteps_en": ["..."],
      "actionSteps_mr": ["..."],
      "tag": "..."
    }
  ]
}

Respond ONLY with the JSON object. No extra text.`;

  try {
    const response = await axios.post(
      OLLAMA_URL,
      {
        model: MODEL,
        prompt,
        stream: false,
        options: { temperature: 0.5 },
      },
      { timeout: 120000 }
    );

    const raw = response.data?.response || "";

    // Extract JSON from response
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      if (Array.isArray(parsed.modules) && parsed.modules.length > 0) {
        return {
          modules: parsed.modules.map((m, i) => ({
            id: `ai-module-${i + 1}`,
            title: { en: m.title_en, mr: m.title_mr },
            explanation: { en: m.explanation_en, mr: m.explanation_mr },
            actionSteps: { en: m.actionSteps_en, mr: m.actionSteps_mr },
            tag: m.tag || "informational",
          })),
          generatedAt: new Date().toISOString(),
          aiAvailable: true,
          context: { state, sea, coast, sst, waveHeight, windSpeed, riskLevel },
        };
      }
    }

    // If parsing fails, return fallback
    return generateFallbackModules(params, sea, coast);
  } catch (err) {
    console.error("[AI Learning] Ollama error:", err.message);
    return generateFallbackModules(params, sea, coast);
  }
}

/**
 * Deterministic fallback modules when Ollama is unavailable.
 * Uses personalization logic to pick contextually relevant topics.
 */
function generateFallbackModules(params, sea, coast) {
  const { state, sst, waveHeight, windSpeed, riskLevel } = params;
  const modules = [];

  // Module 1: Always relevant — based on risk level
  if (riskLevel === "High") {
    modules.push({
      id: "ai-module-1",
      title: {
        en: "🚨 Emergency Safety Protocol",
        mr: "🚨 आपत्कालीन सुरक्षा प्रोटोकॉल",
      },
      explanation: {
        en: `Current conditions near ${coast} show HIGH risk (wave: ${waveHeight}m, wind: ${windSpeed}km/h). Do NOT venture into the ${sea}. Secure your boats with double mooring. Keep emergency supplies ready. Monitor IMD and INCOIS alerts continuously. Inform fellow fishermen about the danger.`,
        mr: `${coast} जवळील सध्याची परिस्थिती उच्च जोखीम दर्शवते (लहर: ${waveHeight}मी, वारा: ${windSpeed}किमी/ता). ${sea} मध्ये जाऊ नका. दुहेरी मूरिंगसह आपल्या बोटी सुरक्षित करा. आपत्कालीन पुरवठा तयार ठेवा.`,
      },
      actionSteps: {
        en: [
          "Do NOT go to sea — conditions are dangerous",
          "Secure boats with double mooring lines",
          "Keep emergency kit ready: torch, radio, water, first aid",
          "Monitor INCOIS and IMD weather alerts",
        ],
        mr: [
          "समुद्रात जाऊ नका — परिस्थिती धोकादायक आहे",
          "दुहेरी मूरिंग लाइनने बोटी सुरक्षित करा",
          "आपत्कालीन किट तयार ठेवा: टॉर्च, रेडिओ, पाणी, प्रथमोपचार",
          "INCOIS आणि IMD हवामान इशारे तपासा",
        ],
      },
      tag: "urgent",
    });
  } else {
    modules.push({
      id: "ai-module-1",
      title: {
        en: `Understanding ${sea} Conditions Today`,
        mr: `आजच्या ${sea} परिस्थिती समजून घेणे`,
      },
      explanation: {
        en: `Current sea conditions near ${coast}, ${state}: SST is ${sst}°C (${sst >= 26 && sst <= 30 ? "optimal for most fish" : "outside optimal range"}), waves at ${waveHeight}m and wind at ${windSpeed}km/h. Risk level is ${riskLevel}. These conditions ${riskLevel === "Safe" ? "are favorable for fishing operations" : "require caution while fishing"}.`,
        mr: `${coast}, ${state} जवळील सध्याची सागरी परिस्थिती: SST ${sst}°C, लहरी ${waveHeight}मी आणि वारा ${windSpeed}किमी/ता. जोखीम पातळी ${riskLevel} आहे.`,
      },
      actionSteps: {
        en: [
          `SST at ${sst}°C — ${sst >= 26 && sst <= 30 ? "good range for fishing" : "check deeper waters for better temperature"}`,
          "Monitor wave conditions throughout the day",
          "Carry communication equipment for safety",
          "Share conditions with fellow fishermen",
        ],
        mr: [
          `SST ${sst}°C — ${sst >= 26 && sst <= 30 ? "मासेमारीसाठी चांगली श्रेणी" : "चांगल्या तापमानासाठी खोल पाणी तपासा"}`,
          "दिवसभर लहर परिस्थिती तपासत रहा",
          "सुरक्षिततेसाठी संपर्क उपकरणे बाळगा",
          "साथी मच्छीमारांशी परिस्थिती सामायिक करा",
        ],
      },
      tag: riskLevel === "Moderate" ? "safety" : "informational",
    });
  }

  // Module 2: SST-based
  if (sst !== null && sst > 30) {
    modules.push({
      id: "ai-module-2",
      title: {
        en: "Marine Heatwave Alert — What It Means for Fishing",
        mr: "सागरी उष्णतेची लाट — मासेमारीसाठी याचा अर्थ",
      },
      explanation: {
        en: `The SST near ${coast} is ${sst}°C, which is above the 30°C threshold. This indicates a possible marine heatwave. Fish tend to migrate to cooler, deeper waters during such events. Coral bleaching risk increases. Adjust your fishing zones accordingly.`,
        mr: `${coast} जवळील SST ${sst}°C आहे, जे 30°C उंबरठ्यापेक्षा जास्त आहे. हे संभाव्य सागरी उष्णतेची लाट दर्शवते. अशा घटनांमध्ये मासे थंड, खोल पाण्याकडे स्थलांतर करतात.`,
      },
      actionSteps: {
        en: [
          "Fish in deeper waters where temperatures are cooler",
          "Target species that tolerate warmer waters",
          "Avoid reef areas — coral bleaching may be occurring",
          "Plan shorter trips and carry extra water",
        ],
        mr: [
          "तापमान थंड असलेल्या खोल पाण्यात मासेमारी करा",
          "उबदार पाणी सहन करणाऱ्या प्रजातींना लक्ष्य करा",
          "रीफ क्षेत्रे टाळा — कोरल ब्लीचिंग होऊ शकते",
          "लहान सफरी नियोजित करा आणि अतिरिक्त पाणी बाळगा",
        ],
      },
      tag: "seasonal",
    });
  } else {
    modules.push({
      id: "ai-module-2",
      title: {
        en: `Best Fishing Practices for ${state}`,
        mr: `${state} साठी सर्वोत्तम मासेमारी पद्धती`,
      },
      explanation: {
        en: `The ${sea} near ${coast} supports diverse fish species. With current SST at ${sst}°C, focus on areas with higher chlorophyll concentration for better catch. Use traditional knowledge combined with modern data for optimal results.`,
        mr: `${coast} जवळील ${sea} मध्ये विविध मासे प्रजाती आढळतात. सध्याच्या SST ${sst}°C सह, चांगल्या पकडीसाठी उच्च क्लोरोफिल एकाग्रता असलेल्या क्षेत्रांवर लक्ष केंद्रित करा.`,
      },
      actionSteps: {
        en: [
          "Check chlorophyll maps for plankton-rich zones",
          "Fish during early morning for best results",
          "Use appropriate net mesh size for the target species",
          "Record catch data to track patterns over time",
        ],
        mr: [
          "प्लँक्टन-समृद्ध क्षेत्रांसाठी क्लोरोफिल नकाशे तपासा",
          "सर्वोत्तम परिणामांसाठी सकाळी लवकर मासेमारी करा",
          "लक्ष्य प्रजातींसाठी योग्य जाळी आकार वापरा",
          "कालांतराने पद्धती ट्रॅक करण्यासाठी पकड डेटा नोंदवा",
        ],
      },
      tag: "informational",
    });
  }

  // Module 3: Sustainability — always included
  modules.push({
    id: "ai-module-3",
    title: {
      en: "Sustainable Fishing for Future Generations",
      mr: "भावी पिढ्यांसाठी शाश्वत मासेमारी",
    },
    explanation: {
      en: `The ${sea} ecosystem is vital for millions of fishermen across ${state} and neighboring states. Overfishing and destructive practices threaten long-term livelihoods. Follow fishing bans during breeding seasons, use legal net sizes, and report illegal trawling.`,
      mr: `${sea} परिसंस्था ${state} आणि शेजारील राज्यांतील लाखो मच्छीमारांसाठी महत्त्वपूर्ण आहे. अत्यधिक मासेमारी आणि विनाशकारी पद्धती दीर्घकालीन उपजीविकेला धोका निर्माण करतात.`,
    },
    actionSteps: {
      en: [
        "Respect fishing ban periods during breeding seasons",
        "Use legal minimum mesh sizes for nets",
        "Avoid catching juvenile fish — let them grow",
        "Report illegal trawling in restricted zones",
      ],
      mr: [
        "प्रजनन हंगामात मासेमारी बंदी कालावधीचा आदर करा",
        "जाळ्यांसाठी कायदेशीर किमान जाळी आकार वापरा",
        "बाळ मासे पकडणे टाळा — त्यांना वाढू द्या",
        "प्रतिबंधित क्षेत्रांमध्ये बेकायदेशीर ट्रॉलिंगची तक्रार करा",
      ],
    },
    tag: "informational",
  });

  return {
    modules,
    generatedAt: new Date().toISOString(),
    aiAvailable: false,
    context: {
      state,
      sea,
      coast: stateCoastMap[state]?.label || coast,
      sst,
      waveHeight,
      windSpeed,
      riskLevel,
    },
  };
}

module.exports = generateAdaptiveLearning;
