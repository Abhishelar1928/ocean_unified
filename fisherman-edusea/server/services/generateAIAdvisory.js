const axios = require("axios");

const OLLAMA_URL = "http://localhost:11434/api/generate";
const MODEL = "llama3.2"; // Change to whichever model you have pulled in Ollama

/**
 * Generates a marine advisory using the local Ollama LLM.
 *
 * @param {Object} data – { sea_surface_temperature, wave_height, wind_speed, risk }
 * @returns {Object}    – { english, marathi, sustainability_tip }
 */
async function generateAIAdvisory(data) {
  const { sea_surface_temperature, wave_height, wind_speed, risk } = data;

  const prompt = `You are an expert marine advisor for Indian fishermen.

Given the following current sea conditions:
- Sea Surface Temperature (SST): ${sea_surface_temperature}°C
- Wave Height: ${wave_height} m
- Wind Speed: ${wind_speed} km/h
- Risk Level: ${risk.level} (score: ${risk.score})

Generate a response in EXACTLY this JSON format (no markdown, no code fences):
{
  "english": "A 2-3 sentence advisory in English for fishermen about whether to go fishing, safety precautions, and expected conditions.",
  "marathi": "The same advisory translated into Marathi (मराठी).",
  "sustainability_tip": "One practical sustainability tip for responsible fishing."
}

Respond ONLY with valid JSON. No explanation before or after.`;

  try {
    const response = await axios.post(
      OLLAMA_URL,
      {
        model: MODEL,
        prompt,
        stream: false,
        options: { temperature: 0.4 },
      },
      { timeout: 120000 }
    );

    const raw = response.data?.response || "";

    // Try to extract JSON from the response
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        english: parsed.english || "Advisory not available.",
        marathi: parsed.marathi || "सल्ला उपलब्ध नाही.",
        sustainability_tip:
          parsed.sustainability_tip || "Practice responsible fishing.",
      };
    }

    // Fallback if parsing fails
    return {
      english: raw.slice(0, 500) || "Advisory generation failed.",
      marathi: "सल्ला तयार करता आला नाही.",
      sustainability_tip: "Practice responsible fishing.",
    };
  } catch (err) {
    console.error("[AI Advisory] Ollama error:", err.message);
    return {
      english: `Risk Level: ${risk.level}. ${risk.description}`,
      marathi: "एआय सल्ला सध्या उपलब्ध नाही. कृपया जोखीम पातळी तपासा.",
      sustainability_tip:
        "Use sustainable nets and follow local fishing regulations.",
      ai_available: false,
    };
  }
}

module.exports = generateAIAdvisory;
