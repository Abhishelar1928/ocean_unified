/**
 * stateCoastMap – Maps Indian coastal states to representative lat/lon coordinates.
 * These coordinates are used as query parameters for the Open-Meteo Marine API.
 */
const stateCoastMap = {
  Maharashtra: {
    label: "Mumbai Coast",
    lat: 19.076,
    lon: 72.8777,
  },
  Gujarat: {
    label: "Gujarat Coast",
    lat: 21.1702,
    lon: 72.8311,
  },
  Kerala: {
    label: "Kerala Coast",
    lat: 9.9312,
    lon: 76.2673,
  },
  "Tamil Nadu": {
    label: "Chennai Coast",
    lat: 13.0827,
    lon: 80.2707,
  },
  "Andhra Pradesh": {
    label: "AP Coast",
    lat: 17.6868,
    lon: 83.2185,
  },
  "West Bengal": {
    label: "Sundarbans Coast",
    lat: 21.9497,
    lon: 88.9,
  },
};

module.exports = stateCoastMap;
