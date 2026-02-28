/**
 * Deterministic risk calculation for marine conditions.
 *
 * Formula:  Risk = (15 × wave_height) + (0.8 × wind_speed)
 *
 * Classification:
 *   Risk < 30  → Safe
 *   Risk < 60  → Moderate
 *   Risk >= 60 → High
 *
 * @param {number} waveHeight – Wave height in metres
 * @param {number} windSpeed  – Wind speed in km/h
 * @returns {Object}          – { score, level, description }
 */
function calculateRisk(waveHeight, windSpeed) {
  const wave = waveHeight ?? 0;
  const wind = windSpeed ?? 0;

  const score = parseFloat(((15 * wave) + (0.8 * wind)).toFixed(2));

  let level, description;

  if (score < 30) {
    level = "Safe";
    description = "Sea conditions are calm. Suitable for fishing operations.";
  } else if (score < 60) {
    level = "Moderate";
    description =
      "Sea conditions are moderate. Exercise caution and monitor updates.";
  } else {
    level = "High";
    description =
      "Dangerous sea conditions. Avoid venturing into the sea. Stay onshore.";
  }

  return { score, level, description };
}

module.exports = calculateRisk;
