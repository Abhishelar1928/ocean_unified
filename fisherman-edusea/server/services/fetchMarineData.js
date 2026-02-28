const axios = require("axios");

const MARINE_API_BASE = "https://marine-api.open-meteo.com/v1/marine";
const WEATHER_API_BASE = "https://api.open-meteo.com/v1/forecast";

/**
 * Fetches live marine data from Open-Meteo Marine + Weather APIs.
 * @param {number} lat  – Latitude of the coastal region
 * @param {number} lon  – Longitude of the coastal region
 * @returns {Object}    – Cleaned marine data object
 */
async function fetchMarineData(lat, lon) {
  // Fetch marine parameters (SST, wave height)
  const marineReq = axios.get(MARINE_API_BASE, {
    params: {
      latitude: lat,
      longitude: lon,
      current: "wave_height,sea_surface_temperature",
      timezone: "Asia/Kolkata",
    },
    timeout: 10000,
  });

  // Fetch wind speed from weather API (not available in marine endpoint)
  const weatherReq = axios.get(WEATHER_API_BASE, {
    params: {
      latitude: lat,
      longitude: lon,
      current: "wind_speed_10m",
      timezone: "Asia/Kolkata",
    },
    timeout: 10000,
  });

  const [marineRes, weatherRes] = await Promise.all([marineReq, weatherReq]);

  const marineCurrent = marineRes.data?.current || {};
  const weatherCurrent = weatherRes.data?.current || {};

  return {
    sea_surface_temperature: marineCurrent.sea_surface_temperature ?? null,
    wave_height: marineCurrent.wave_height ?? null,
    wind_speed: weatherCurrent.wind_speed_10m ?? null,
    units: {
      sea_surface_temperature: "°C",
      wave_height: "m",
      wind_speed: "km/h",
    },
    fetched_at: new Date().toISOString(),
  };
}

module.exports = fetchMarineData;
