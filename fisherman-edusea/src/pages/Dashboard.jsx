import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Thermometer, Droplets, Waves, Wind, Leaf, Gauge, MapPin,
  Navigation, Eye, ArrowUpDown, Fish, ShieldAlert, Activity,
  BookOpen, Crosshair, TrendingUp, Anchor, AlertTriangle,
  RefreshCw, Clock, Loader2, WifiOff, Satellite, MessageSquare
} from 'lucide-react'
import {
  regions, computeSeaStatus, computeSafetyRisk, computeFishActivity, uiStrings
} from '../data/educationData'
import RiskMeter from '../components/RiskMeter'
import StatusIndicator from '../components/StatusIndicator'
import ProgressPanel from '../components/ProgressPanel'

// ─── Backend API config ──────────────────────────────────────
const API_BASE = 'http://localhost:5000/api'

// Maps the frontend region IDs to backend state names
const regionToState = {
  mumbai: 'Maharashtra',
  goa: 'Gujarat',      // Closest mapping — Gujarat coast
  kerala: 'Kerala',
  chennai: 'Tamil Nadu',
  ratnagiri: 'Maharashtra', // Ratnagiri is in Maharashtra
}

// All backend states for the live dropdown
const backendStates = [
  { key: 'Maharashtra', label: { en: 'Maharashtra – Mumbai Coast', mr: 'महाराष्ट्र – मुंबई किनारा' } },
  { key: 'Gujarat', label: { en: 'Gujarat – Gujarat Coast', mr: 'गुजरात – गुजरात किनारा' } },
  { key: 'Kerala', label: { en: 'Kerala – Kerala Coast', mr: 'केरळ – केरळ किनारा' } },
  { key: 'Tamil Nadu', label: { en: 'Tamil Nadu – Chennai Coast', mr: 'तमिळनाडू – चेन्नई किनारा' } },
  { key: 'Andhra Pradesh', label: { en: 'Andhra Pradesh – AP Coast', mr: 'आंध्र प्रदेश – AP किनारा' } },
  { key: 'West Bengal', label: { en: 'West Bengal – Sundarbans Coast', mr: 'पश्चिम बंगाल – सुंदरबन किनारा' } },
]

export default function Dashboard({ lang, region, completedModules, simulatorScore }) {
  const navigate = useNavigate()
  const s = uiStrings[lang]

  // ─── State ──────────────────────────────────────────────────
  const [selectedState, setSelectedState] = useState(regionToState[region] || 'Maharashtra')
  const [marineData, setMarineData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [lastFetched, setLastFetched] = useState(null)

  // ─── Fetch marine data from backend ─────────────────────────
  const fetchMarineData = useCallback(async (state) => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetch(`${API_BASE}/marine-data?state=${encodeURIComponent(state)}`)
      if (!res.ok) {
        const errBody = await res.json().catch(() => ({}))
        throw new Error(errBody.error || `Server error (${res.status})`)
      }
      const json = await res.json()
      if (json.success && json.data) {
        setMarineData(json.data)
        setLastFetched(new Date())
      } else {
        throw new Error('Invalid response format')
      }
    } catch (err) {
      console.error('[Dashboard] Fetch error:', err.message)
      setError(err.message)
      // Keep previous data if available
    } finally {
      setLoading(false)
    }
  }, [])

  // ─── Auto-fetch when selectedState changes ──────────────────
  useEffect(() => {
    fetchMarineData(selectedState)
  }, [selectedState, fetchMarineData])

  // ─── Sync with parent region prop ───────────────────────────
  useEffect(() => {
    const mapped = regionToState[region]
    if (mapped && mapped !== selectedState) {
      setSelectedState(mapped)
    }
  }, [region])

  // ─── Fallback to static data ────────────────────────────────
  const currentRegion = regions.find(r => r.id === region) || regions[0]
  const staticData = currentRegion.data

  // ─── Derived live values (with fallback) ────────────────────
  const live = marineData?.marine || null
  const liveRisk = marineData?.risk || null
  const liveAdvisory = marineData?.advisory || null
  const coords = marineData?.coordinates || { lat: currentRegion.lat, lon: currentRegion.lng }

  // Use live SST/wave/wind if available, otherwise static
  const displaySST = live?.sea_surface_temperature ?? staticData.sst
  const displayWave = live?.wave_height ?? staticData.waveHeight
  const displayWind = live?.wind_speed ?? staticData.windSpeed

  // Build a merged data object for the existing formula functions
  const mergedData = {
    ...staticData,
    sst: displaySST,
    waveHeight: displayWave,
    windSpeed: displayWind,
  }

  const seaStatus = computeSeaStatus(mergedData, lang)
  const risk = computeSafetyRisk(mergedData, lang)
  const fishAct = computeFishActivity(mergedData, lang)

  // Risk color helper
  const riskColorClass = (level) => {
    if (!level) return 'text-slate-400'
    const l = level.toLowerCase()
    if (l === 'safe') return 'text-emerald-400'
    if (l === 'moderate') return 'text-amber-400'
    return 'text-red-400'
  }
  const riskBgClass = (level) => {
    if (!level) return 'bg-slate-500/20 border-slate-500/30'
    const l = level.toLowerCase()
    if (l === 'safe') return 'bg-emerald-500/15 border-emerald-500/30'
    if (l === 'moderate') return 'bg-amber-500/15 border-amber-500/30'
    return 'bg-red-500/15 border-red-500/30'
  }

  const paramCards = [
    { icon: Thermometer, label: 'SST', value: `${displaySST}°C`, sub: lang === 'en' ? 'Sea Surface Temp' : 'पृष्ठ तापमान', live: !!live?.sea_surface_temperature },
    { icon: Droplets, label: lang === 'en' ? 'Salinity' : 'क्षारता', value: `${staticData.salinity} PSU`, sub: lang === 'en' ? 'Salt content' : 'मीठ प्रमाण', live: false },
    { icon: Waves, label: lang === 'en' ? 'Wave Height' : 'लहर उंची', value: `${displayWave} m`, sub: lang === 'en' ? 'Significant wave' : 'महत्त्वपूर्ण लहर', live: !!live?.wave_height },
    { icon: Wind, label: lang === 'en' ? 'Wind Speed' : 'वारा वेग', value: `${displayWind} km/h`, sub: lang === 'en' ? 'Surface wind' : 'पृष्ठ वारा', live: !!live?.wind_speed },
    { icon: Leaf, label: lang === 'en' ? 'Chlorophyll' : 'क्लोरोफिल', value: `${staticData.chlorophyll} mg/m³`, sub: lang === 'en' ? 'Phytoplankton' : 'फायटोप्लँक्टन', live: false },
    { icon: Navigation, label: lang === 'en' ? 'Current' : 'प्रवाह', value: `${staticData.currentSpeed} m/s`, sub: lang === 'en' ? 'Ocean current' : 'समुद्री प्रवाह', live: false },
    { icon: Eye, label: lang === 'en' ? 'Visibility' : 'दृश्यमानता', value: `${staticData.visibility} km`, sub: lang === 'en' ? 'Atmospheric' : 'वातावरणीय', live: false },
    { icon: ArrowUpDown, label: lang === 'en' ? 'Tidal Range' : 'भरती श्रेणी', value: `${staticData.tidalRange} m`, sub: lang === 'en' ? 'High-to-low diff' : 'उच्च-निम्न फरक', live: false },
  ]

  return (
    <div className="space-y-6 animate-fade-in-up">

      {/* ─── Live State Selector + Status Bar ──────────────────── */}
      <div className="glass-panel rounded-2xl p-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <Satellite className="w-5 h-5 text-cyan-400" />
            <div>
              <h2 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                {lang === 'en' ? 'Live Marine Data' : 'थेट सागरी डेटा'}
              </h2>
              <div className="flex items-center gap-2 mt-1">
                <select
                  value={selectedState}
                  onChange={e => setSelectedState(e.target.value)}
                  className="region-select glass-light rounded-lg px-3 py-1.5 text-sm text-white font-medium pr-8 cursor-pointer focus:outline-none focus:ring-1 focus:ring-cyan-500/50"
                >
                  {backendStates.map(s => (
                    <option key={s.key} value={s.key} className="bg-slate-800 text-slate-200">
                      {s.label[lang]}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {/* Status indicator */}
            {loading ? (
              <span className="flex items-center gap-1.5 text-xs text-cyan-400">
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
                {lang === 'en' ? 'Fetching...' : 'प्राप्त करत आहे...'}
              </span>
            ) : error ? (
              <span className="flex items-center gap-1.5 text-xs text-red-400">
                <WifiOff className="w-3.5 h-3.5" />
                {lang === 'en' ? 'Offline' : 'ऑफलाइन'}
              </span>
            ) : (
              <span className="flex items-center gap-1.5 text-xs text-emerald-400">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                {lang === 'en' ? 'Live' : 'थेट'}
              </span>
            )}

            {/* Last updated */}
            {marineData?.last_updated && (
              <span className="flex items-center gap-1 text-[10px] text-slate-500">
                <Clock className="w-3 h-3" />
                {new Date(marineData.last_updated).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
              </span>
            )}

            {/* Refresh button */}
            <button
              onClick={() => fetchMarineData(selectedState)}
              disabled={loading}
              className="glass-light rounded-lg p-2 text-cyan-400 hover:text-cyan-300 hover:bg-cyan-500/10 transition-colors disabled:opacity-50"
              title={lang === 'en' ? 'Refresh' : 'रिफ्रेश'}
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        {/* Error banner */}
        {error && (
          <div className="mt-3 flex items-center gap-2 bg-red-500/10 border border-red-500/20 rounded-lg px-3 py-2 text-xs text-red-300">
            <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" />
            {error}
            <span className="text-slate-500 ml-1">
              ({lang === 'en' ? 'Showing cached/static data' : 'कॅश्ड/स्थिर डेटा दाखवत आहे'})
            </span>
          </div>
        )}
      </div>

      {/* ─── Region Header ──────────────────────────────────────── */}
      <div className="glass-panel rounded-2xl p-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <MapPin className="w-4 h-4 text-cyan-400" />
              <h1 className="text-lg font-bold text-white">
                {marineData ? `${marineData.state} – ${marineData.region}` : currentRegion.label[lang]}
              </h1>
              {live && (
                <span className="ml-1 px-1.5 py-0.5 rounded text-[9px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 uppercase">
                  Live
                </span>
              )}
            </div>
            <p className="text-xs text-slate-400">
              {s.coordinates}: {coords.lat}°N, {coords.lon || coords.lng}°E
              {staticData.cycloneAlert && (
                <span className="ml-2 inline-flex items-center gap-1 text-red-400 font-semibold">
                  <AlertTriangle className="w-3 h-3" />
                  {lang === 'en' ? 'CYCLONE ALERT' : 'चक्रीवादळ इशारा'}
                </span>
              )}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <div className="glass-light rounded-lg px-3 py-1.5 text-xs text-slate-300">
              <Fish className="w-3 h-3 inline mr-1" />
              {staticData.fishSpecies[lang]}
            </div>
          </div>
        </div>
      </div>

      {/* ─── Live Risk Level Banner (from backend) ──────────────── */}
      {liveRisk && (
        <div className={`rounded-xl p-4 border ${riskBgClass(liveRisk.level)}`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <ShieldAlert className={`w-6 h-6 ${riskColorClass(liveRisk.level)}`} />
              <div>
                <div className="flex items-center gap-2">
                  <span className={`text-sm font-bold ${riskColorClass(liveRisk.level)}`}>
                    {lang === 'en' ? 'Live Risk' : 'थेट जोखीम'}: {liveRisk.level}
                  </span>
                  <span className="text-xs text-slate-500">
                    ({lang === 'en' ? 'Score' : 'गुण'}: {liveRisk.score})
                  </span>
                </div>
                <p className="text-xs text-slate-400 mt-0.5">{liveRisk.description}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ─── AI Advisory Panel ──────────────────────────────────── */}
      {liveAdvisory && (
        <div className="glass-panel rounded-xl p-5 space-y-3">
          <h2 className="text-sm font-bold text-purple-300 flex items-center gap-2">
            <MessageSquare className="w-4 h-4 text-purple-400" />
            {lang === 'en' ? 'AI Advisory' : 'AI सल्ला'}
            {!liveAdvisory.ai_available && liveAdvisory.ai_available !== undefined && (
              <span className="text-[10px] text-slate-500 font-normal ml-2">(Fallback — Ollama offline)</span>
            )}
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {/* English advisory */}
            <div className="glass-card rounded-lg p-3.5">
              <h3 className="text-[10px] text-slate-500 uppercase tracking-wider mb-1.5">English</h3>
              <p className="text-xs text-slate-200 leading-relaxed">{liveAdvisory.english}</p>
            </div>
            {/* Marathi advisory */}
            <div className="glass-card rounded-lg p-3.5">
              <h3 className="text-[10px] text-slate-500 uppercase tracking-wider mb-1.5">मराठी</h3>
              <p className="text-xs text-slate-200 leading-relaxed">{liveAdvisory.marathi}</p>
            </div>
          </div>

          {/* Sustainability tip */}
          {liveAdvisory.sustainability_tip && (
            <div className="flex items-start gap-2 bg-emerald-500/10 border border-emerald-500/20 rounded-lg px-3 py-2.5">
              <Leaf className="w-3.5 h-3.5 text-emerald-400 mt-0.5 flex-shrink-0" />
              <p className="text-xs text-emerald-300">{liveAdvisory.sustainability_tip}</p>
            </div>
          )}
        </div>
      )}

      {/* ─── AI Metric Cards ────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <RiskMeter
          label={s.seaStatus}
          value={seaStatus.score}
          maxValue={seaStatus.maxScore}
          color={seaStatus.color}
          description={seaStatus.label}
          icon={Waves}
        />
        <RiskMeter
          label={s.riskLevel}
          value={risk.score}
          maxValue={100}
          color={risk.color}
          description={risk.desc}
          icon={ShieldAlert}
        />
        <RiskMeter
          label={s.fishActivity}
          value={fishAct.score}
          maxValue={100}
          color={fishAct.color}
          description={fishAct.desc}
          icon={Activity}
        />
      </div>

      {/* ─── Oceanographic Parameters Grid ──────────────────────── */}
      <div>
        <h2 className="text-sm font-bold text-slate-300 mb-3 flex items-center gap-2">
          <Gauge className="w-4 h-4 text-cyan-400" />
          {s.oceanData}
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {paramCards.map((p, i) => (
            <div key={i} className={`glass-card rounded-xl p-3.5 animate-fade-in-up delay-${(i + 1) * 100} relative`}>
              {p.live && (
                <span className="absolute top-2 right-2 w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" title="Live data" />
              )}
              <div className="flex items-center gap-2 mb-2">
                <p.icon className="w-4 h-4 text-cyan-400/70" />
                <span className="text-[10px] text-slate-500 uppercase tracking-wider">{p.label}</span>
              </div>
              <div className="text-lg font-bold text-white">{p.value}</div>
              <div className="text-[10px] text-slate-500 mt-0.5">{p.sub}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ─── Bottom Section: AI Formulas + Progress + Actions ──── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* AI Formula explanations */}
        <div className="lg:col-span-2 space-y-3">
          <h2 className="text-sm font-bold text-slate-300 flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-purple-400" />
            {lang === 'en' ? 'AI Formulas Active' : 'सक्रिय AI सूत्रे'}
          </h2>

          <div className="glass-card rounded-xl p-4">
            <h3 className="text-xs font-semibold text-amber-400 mb-2">{s.riskFormula}</h3>
            <code className="text-xs text-slate-300 font-mono block bg-slate-800/50 rounded-lg p-3 leading-relaxed">
              Risk = (15 × wave_height) + (0.8 × wind_speed) + (cyclone × 50) + (breeding × 10){'\n'}
              Risk = (15 × {displayWave}) + (0.8 × {displayWind}) + ({staticData.cycloneAlert ? 1 : 0} × 50) + ({staticData.breedingZone ? 1 : 0} × 10){'\n'}
              <span className={`font-bold ${risk.color === 'emerald' ? 'text-emerald-400' : risk.color === 'amber' ? 'text-amber-400' : 'text-red-400'}`}>
                Risk = {risk.score} → {risk.label}
              </span>
            </code>
          </div>

          <div className="glass-card rounded-xl p-4">
            <h3 className="text-xs font-semibold text-cyan-400 mb-2">{s.fishFormula}</h3>
            <code className="text-xs text-slate-300 font-mono block bg-slate-800/50 rounded-lg p-3 leading-relaxed">
              FishActivity = f(SST_optimality, Chlorophyll, Upwelling, CPUE, BreedingZone){'\n'}
              SST_score = max(0, 30 - |{displaySST} - 28| × 6) = {Math.max(0, 30 - Math.abs(displaySST - 28) * 6).toFixed(1)}{'\n'}
              Chl_score = min({staticData.chlorophyll} × 7, 30) = {Math.min(staticData.chlorophyll * 7, 30).toFixed(1)}{'\n'}
              <span className={`font-bold ${fishAct.color === 'emerald' ? 'text-emerald-400' : fishAct.color === 'cyan' ? 'text-cyan-400' : 'text-slate-400'}`}>
                Activity = {fishAct.score}% → {fishAct.label}
              </span>
            </code>
          </div>
        </div>

        {/* Sidebar: Progress + Actions */}
        <div className="space-y-4">
          <ProgressPanel lang={lang} completedModules={completedModules} simulatorScore={simulatorScore} />

          {/* Quick actions */}
          <div className="glass-panel rounded-xl p-4 space-y-2">
            <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">{s.quickActions}</h3>
            <button
              onClick={() => navigate('/learning')}
              className="w-full flex items-center gap-2 px-3 py-2.5 rounded-lg bg-cyan-500/10 hover:bg-cyan-500/20 border border-cyan-500/20 text-cyan-300 text-xs font-medium transition-colors"
            >
              <BookOpen className="w-3.5 h-3.5" />
              {s.startLearning}
            </button>
            <button
              onClick={() => navigate('/simulator')}
              className="w-full flex items-center gap-2 px-3 py-2.5 rounded-lg bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-300 text-xs font-medium transition-colors"
            >
              <Crosshair className="w-3.5 h-3.5" />
              {s.startSimulator}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
