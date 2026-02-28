const express = require("express");
const stateCoastMap = require("../config/stateCoastMap");
const { getStateData, getAllData, refreshAllStates } = require("../services/scheduler");
const generateAdaptiveLearning = require("../services/generateLearning");

const router = express.Router();

/**
 * GET /marine-data?state=Maharashtra
 *
 * Returns latest marine parameters, calculated risk, and AI advisory
 * for the given Indian coastal state.
 *
 * Query params:
 *   state (optional) – State name (e.g., Maharashtra, Gujarat, Kerala, etc.)
 *                       If omitted, returns data for ALL states.
 */
router.get("/marine-data", (req, res) => {
  const { state } = req.query;

  // If no state specified, return all
  if (!state) {
    const all = getAllData();
    return res.json({
      success: true,
      count: Object.keys(all).length,
      available_states: Object.keys(stateCoastMap),
      data: all,
    });
  }

  // Validate state name
  if (!stateCoastMap[state]) {
    return res.status(400).json({
      success: false,
      error: `Invalid state: "${state}". Available states: ${Object.keys(stateCoastMap).join(", ")}`,
    });
  }

  const data = getStateData(state);

  if (!data) {
    return res.status(503).json({
      success: false,
      error: `Data for "${state}" is not yet available. The system is still fetching initial data. Please retry in a minute.`,
    });
  }

  return res.json({
    success: true,
    data,
  });
});

/**
 * POST /marine-data/refresh
 * Manually triggers a data refresh for all states.
 */
router.post("/marine-data/refresh", async (req, res) => {
  try {
    await refreshAllStates();
    const all = getAllData();
    return res.json({
      success: true,
      message: "Data refreshed successfully.",
      count: Object.keys(all).length,
      data: all,
    });
  } catch (err) {
    console.error("[Route] Refresh error:", err.message);
    return res.status(500).json({
      success: false,
      error: "Failed to refresh data.",
    });
  }
});

/**
 * POST /generate-learning
 * Generates AI-driven adaptive learning modules based on marine conditions.
 *
 * Body: { state, sst, waveHeight, windSpeed, riskLevel }
 */
router.post("/generate-learning", async (req, res) => {
  const { state, sst, waveHeight, windSpeed, riskLevel } = req.body;

  if (!state) {
    return res.status(400).json({
      success: false,
      error: 'Missing required field: "state".',
    });
  }

  try {
    console.log(`[Learning] Generating adaptive modules for ${state}...`);
    const result = await generateAdaptiveLearning({
      state,
      sst: sst ?? null,
      waveHeight: waveHeight ?? null,
      windSpeed: windSpeed ?? null,
      riskLevel: riskLevel || "Safe",
    });

    return res.json({
      success: true,
      ...result,
    });
  } catch (err) {
    console.error("[Learning] Generation error:", err.message);
    return res.status(500).json({
      success: false,
      error: "Failed to generate learning modules.",
    });
  }
});

/**
 * GET /states
 * Returns list of available states with their coordinates.
 */
router.get("/states", (req, res) => {
  return res.json({
    success: true,
    states: stateCoastMap,
  });
});

module.exports = router;
