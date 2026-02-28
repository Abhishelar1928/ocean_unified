const cron = require("node-cron");
const stateCoastMap = require("../config/stateCoastMap");
const fetchMarineData = require("./fetchMarineData");
const calculateRisk = require("./calculateRisk");
const generateAIAdvisory = require("./generateAIAdvisory");

/**
 * In-memory store for the latest marine data per state.
 * Structure: { [stateName]: { marine, risk, advisory, last_updated } }
 */
const dataStore = {};

/**
 * Refresh marine data and AI advisory for all states.
 */
async function refreshAllStates() {
  console.log(`[Scheduler] Refreshing marine data at ${new Date().toISOString()}`);

  const states = Object.keys(stateCoastMap);

  for (const state of states) {
    const { lat, lon, label } = stateCoastMap[state];
    try {
      console.log(`  → Fetching data for ${state} (${label})...`);

      const marine = await fetchMarineData(lat, lon);
      const risk = calculateRisk(marine.wave_height, marine.wind_speed);
      const advisory = await generateAIAdvisory({ ...marine, risk });

      dataStore[state] = {
        state,
        region: label,
        coordinates: { lat, lon },
        marine,
        risk,
        advisory,
        last_updated: new Date().toISOString(),
      };

      console.log(`  ✓ ${state}: Risk=${risk.level} (${risk.score})`);
    } catch (err) {
      console.error(`  ✗ ${state}: ${err.message}`);
      // Keep previous data if available
      if (!dataStore[state]) {
        dataStore[state] = {
          state,
          region: label,
          coordinates: { lat, lon },
          marine: null,
          risk: null,
          advisory: null,
          last_updated: null,
          error: "Initial fetch failed. Retrying on next cycle.",
        };
      }
    }
  }

  console.log("[Scheduler] Refresh complete.\n");
}

/**
 * Starts the cron job that refreshes data every 6 hours.
 * Also triggers an immediate first fetch.
 */
function startScheduler() {
  // Immediate fetch on startup
  refreshAllStates();

  // Schedule: every 6 hours → "0 */6 * * *"
  cron.schedule("0 */6 * * *", () => {
    refreshAllStates();
  });

  console.log("[Scheduler] Cron job registered — runs every 6 hours.\n");
}

/**
 * Get stored data for a specific state.
 * @param {string} state
 * @returns {Object|null}
 */
function getStateData(state) {
  return dataStore[state] || null;
}

/**
 * Get stored data for all states.
 * @returns {Object}
 */
function getAllData() {
  return dataStore;
}

module.exports = { startScheduler, getStateData, getAllData, refreshAllStates };
