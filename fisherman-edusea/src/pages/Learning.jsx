import { useState, useEffect, useCallback } from 'react'
import {
  BookOpen, Filter, ChevronRight, ChevronDown, Loader2, WifiOff,
  RefreshCw, Satellite, Zap, Shield, Sun, Info, ArrowRight,
  Lightbulb, CheckCircle2, AlertTriangle, Leaf, Brain
} from 'lucide-react'
import { learningLevels, uiStrings } from '../data/educationData'
import AccordionModule from '../components/AccordionModule'

// ─── Backend API config ──────────────────────────────────────
const API_BASE = 'http://localhost:5000/api'

// Maps frontend region IDs to backend state names
const regionToState = {
  mumbai: 'Maharashtra',
  goa: 'Gujarat',
  kerala: 'Kerala',
  chennai: 'Tamil Nadu',
  ratnagiri: 'Maharashtra',
}

// All backend states for dropdown
const backendStates = [
  { key: 'Maharashtra', label: { en: 'Maharashtra – Mumbai Coast', mr: 'महाराष्ट्र – मुंबई किनारा' } },
  { key: 'Gujarat', label: { en: 'Gujarat – Gujarat Coast', mr: 'गुजरात – गुजरात किनारा' } },
  { key: 'Kerala', label: { en: 'Kerala – Kerala Coast', mr: 'केरळ – केरळ किनारा' } },
  { key: 'Tamil Nadu', label: { en: 'Tamil Nadu – Chennai Coast', mr: 'तमिळनाडू – चेन्नई किनारा' } },
  { key: 'Andhra Pradesh', label: { en: 'Andhra Pradesh – AP Coast', mr: 'आंध्र प्रदेश – AP किनारा' } },
  { key: 'West Bengal', label: { en: 'West Bengal – Sundarbans Coast', mr: 'पश्चिम बंगाल – सुंदरबन किनारा' } },
]

// Tag config
const tagConfig = {
  urgent:        { icon: AlertTriangle, color: 'red',     label: { en: 'Urgent',        mr: 'तातडीचे' } },
  safety:        { icon: Shield,        color: 'amber',   label: { en: 'Safety',        mr: 'सुरक्षा' } },
  seasonal:      { icon: Sun,           color: 'orange',  label: { en: 'Seasonal',      mr: 'हंगामी' } },
  informational: { icon: Info,          color: 'cyan',    label: { en: 'Informational', mr: 'माहितीपूर्ण' } },
}

export default function Learning({ lang, region, completedModules, onCompleteModule }) {
  const s = uiStrings[lang]
  const [activeLevel, setActiveLevel] = useState(null)

  // ─── AI Adaptive Learning State ─────────────────────────────
  const [selectedState, setSelectedState] = useState(regionToState[region] || 'Maharashtra')
  const [marineData, setMarineData] = useState(null)
  const [aiModules, setAiModules] = useState(null)
  const [aiLoading, setAiLoading] = useState(false)
  const [aiError, setAiError] = useState(null)
  const [expandedAiModule, setExpandedAiModule] = useState(null)
  const [showMarathi, setShowMarathi] = useState(lang === 'mr')

  // Sync Marathi toggle with parent lang
  useEffect(() => { setShowMarathi(lang === 'mr') }, [lang])

  // Sync with parent region
  useEffect(() => {
    const mapped = regionToState[region]
    if (mapped && mapped !== selectedState) setSelectedState(mapped)
  }, [region])

  // ─── Fetch marine data for selected state ───────────────────
  const fetchMarineData = useCallback(async (state) => {
    try {
      const res = await fetch(`${API_BASE}/marine-data?state=${encodeURIComponent(state)}`)
      if (!res.ok) throw new Error('Failed to fetch marine data')
      const json = await res.json()
      if (json.success && json.data) {
        setMarineData(json.data)
        return json.data
      }
    } catch (err) {
      console.error('[Learning] Marine data fetch error:', err.message)
    }
    return null
  }, [])

  // ─── Generate adaptive learning ─────────────────────────────
  const generateAdaptiveLearning = useCallback(async (state, marine) => {
    setAiLoading(true)
    setAiError(null)
    try {
      const body = {
        state,
        sst: marine?.marine?.sea_surface_temperature ?? null,
        waveHeight: marine?.marine?.wave_height ?? null,
        windSpeed: marine?.marine?.wind_speed ?? null,
        riskLevel: marine?.risk?.level ?? 'Safe',
      }

      const res = await fetch(`${API_BASE}/generate-learning`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })

      if (!res.ok) {
        const errBody = await res.json().catch(() => ({}))
        throw new Error(errBody.error || `Server error (${res.status})`)
      }

      const json = await res.json()
      if (json.success && json.modules) {
        setAiModules(json)
      } else {
        throw new Error('Invalid response format')
      }
    } catch (err) {
      console.error('[Learning] AI generation error:', err.message)
      setAiError(err.message)
    } finally {
      setAiLoading(false)
    }
  }, [])

  // ─── Trigger: when selectedState changes ────────────────────
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      const marine = await fetchMarineData(selectedState)
      if (!cancelled) {
        generateAdaptiveLearning(selectedState, marine)
      }
    })()
    return () => { cancelled = true }
  }, [selectedState, fetchMarineData, generateAdaptiveLearning])

  // ─── Static learning levels (filtered) ──────────────────────
  const filtered = activeLevel
    ? learningLevels.filter(l => l.level === activeLevel)
    : learningLevels

  // ─── Helpers ────────────────────────────────────────────────
  const ctx = aiModules?.context
  const TagBadge = ({ tag }) => {
    const cfg = tagConfig[tag] || tagConfig.informational
    const TagIcon = cfg.icon
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-${cfg.color}-500/15 text-${cfg.color}-400 border border-${cfg.color}-500/25`}>
        <TagIcon className="w-2.5 h-2.5" />
        {cfg.label[lang]}
      </span>
    )
  }

  return (
    <div className="space-y-6 animate-fade-in-up">

      {/* ═══ AI ADAPTIVE LEARNING SECTION ═══════════════════════ */}
      <div className="glass-panel rounded-2xl p-5 space-y-4">
        {/* Header + Region Selector */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-500/15 flex items-center justify-center">
              <Brain className="w-5 h-5 text-purple-400" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-white flex items-center gap-2">
                {lang === 'en' ? 'AI Adaptive Learning' : 'AI अनुकूली शिक्षण'}
                <Zap className="w-4 h-4 text-amber-400" />
              </h1>
              <p className="text-xs text-slate-400">
                {lang === 'en'
                  ? 'Personalized modules based on live sea conditions'
                  : 'थेट सागरी परिस्थितीवर आधारित वैयक्तिक मॉड्यूल'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <select
              value={selectedState}
              onChange={e => setSelectedState(e.target.value)}
              className="region-select glass-light rounded-lg px-3 py-1.5 text-xs text-white font-medium pr-8 cursor-pointer focus:outline-none focus:ring-1 focus:ring-purple-500/50"
            >
              {backendStates.map(s => (
                <option key={s.key} value={s.key} className="bg-slate-800 text-slate-200">
                  {s.label[lang]}
                </option>
              ))}
            </select>

            <button
              onClick={() => generateAdaptiveLearning(selectedState, marineData)}
              disabled={aiLoading}
              className="glass-light rounded-lg p-2 text-purple-400 hover:text-purple-300 hover:bg-purple-500/10 transition-colors disabled:opacity-50"
              title={lang === 'en' ? 'Regenerate' : 'पुन्हा तयार करा'}
            >
              <RefreshCw className={`w-3.5 h-3.5 ${aiLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        {/* Context bar */}
        {ctx && (
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-[10px] text-slate-500 bg-slate-800/40 rounded-lg px-3 py-2">
            <span><Satellite className="w-3 h-3 inline mr-1 text-cyan-500" />{ctx.sea} — {ctx.coast}</span>
            <span>SST: <span className="text-cyan-400 font-semibold">{ctx.sst ?? '—'}°C</span></span>
            <span>Wave: <span className="text-cyan-400 font-semibold">{ctx.waveHeight ?? '—'}m</span></span>
            <span>Wind: <span className="text-cyan-400 font-semibold">{ctx.windSpeed ?? '—'}km/h</span></span>
            <span>Risk: <span className={`font-semibold ${
              ctx.riskLevel === 'Safe' ? 'text-emerald-400' : ctx.riskLevel === 'Moderate' ? 'text-amber-400' : 'text-red-400'
            }`}>{ctx.riskLevel}</span></span>
            {aiModules && !aiModules.aiAvailable && (
              <span className="text-amber-400">(Fallback — Ollama offline)</span>
            )}
          </div>
        )}

        {/* Loading */}
        {aiLoading && (
          <div className="flex items-center justify-center gap-3 py-8">
            <Loader2 className="w-6 h-6 text-purple-400 animate-spin" />
            <span className="text-sm text-slate-400">
              {lang === 'en' ? 'Generating personalized modules...' : 'वैयक्तिक मॉड्यूल तयार करत आहे...'}
            </span>
          </div>
        )}

        {/* Error */}
        {aiError && !aiLoading && (
          <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/20 rounded-lg px-3 py-2 text-xs text-red-300">
            <WifiOff className="w-3.5 h-3.5 flex-shrink-0" />
            {aiError}
            <span className="text-slate-500 ml-1">
              ({lang === 'en' ? 'Showing static modules below' : 'खाली स्थिर मॉड्यूल दाखवत आहे'})
            </span>
          </div>
        )}

        {/* AI Generated Modules */}
        {!aiLoading && aiModules?.modules && (
          <div className="space-y-3">
            {aiModules.modules.map((mod, idx) => {
              const isExpanded = expandedAiModule === mod.id
              const displayLang = showMarathi ? 'mr' : 'en'

              return (
                <div key={mod.id} className={`glass-card rounded-xl overflow-hidden transition-all duration-300 ${isExpanded ? 'ring-1 ring-purple-500/30' : ''}`}>
                  {/* Module Header */}
                  <button
                    onClick={() => setExpandedAiModule(isExpanded ? null : mod.id)}
                    className="w-full flex items-center gap-3 p-4 text-left hover:bg-slate-700/20 transition-colors"
                  >
                    <div className="w-9 h-9 rounded-lg bg-purple-500/15 flex items-center justify-center shrink-0">
                      <span className="text-sm font-bold text-purple-400">{idx + 1}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <h4 className="text-sm font-semibold text-slate-200">{mod.title[displayLang]}</h4>
                        <TagBadge tag={mod.tag} />
                      </div>
                    </div>
                    <ChevronDown className={`w-4 h-4 text-slate-500 transition-transform duration-300 shrink-0 ${isExpanded ? 'rotate-180' : ''}`} />
                  </button>

                  {/* Expanded Content */}
                  {isExpanded && (
                    <div className="px-4 pb-4 animate-slide-down space-y-4">
                      {/* Language toggle */}
                      <div className="flex justify-end">
                        <button
                          onClick={(e) => { e.stopPropagation(); setShowMarathi(!showMarathi) }}
                          className="text-[10px] font-medium px-2 py-1 rounded glass-light text-purple-300 hover:bg-purple-500/10 transition-colors"
                        >
                          {showMarathi ? '🇬🇧 English' : '🇮🇳 मराठी'}
                        </button>
                      </div>

                      {/* Explanation */}
                      <div className="glass-light rounded-lg p-3">
                        <p className="text-xs text-slate-300 leading-relaxed">{mod.explanation[displayLang]}</p>
                      </div>

                      {/* Action Steps */}
                      <div>
                        <h5 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                          <Lightbulb className="w-3 h-3 text-amber-400" />
                          {lang === 'en' ? 'Action Steps' : 'कृती पावले'}
                        </h5>
                        <ul className="space-y-1.5">
                          {(mod.actionSteps[displayLang] || []).map((step, i) => (
                            <li key={i} className="flex items-start gap-2 text-xs text-slate-300">
                              <ArrowRight className="w-3 h-3 text-purple-400 mt-0.5 shrink-0" />
                              <span>{step}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  )}
                </div>
              )
            })}

            {/* Generated timestamp */}
            {aiModules.generatedAt && (
              <p className="text-[10px] text-slate-600 text-right">
                {lang === 'en' ? 'Generated' : 'तयार केले'}: {new Date(aiModules.generatedAt).toLocaleString('en-IN')}
              </p>
            )}
          </div>
        )}
      </div>

      {/* ═══ STATIC LEARNING LEVELS (ORIGINAL) ═════════════════ */}
      <div className="glass-panel rounded-2xl p-5">
        <div className="flex items-center gap-3 mb-3">
          <div className="w-10 h-10 rounded-xl bg-cyan-500/10 flex items-center justify-center">
            <BookOpen className="w-5 h-5 text-cyan-400" />
          </div>
          <div>
            <h1 className="text-lg font-bold text-white">{s.learningCenter}</h1>
            <p className="text-xs text-slate-400">
              {lang === 'en'
                ? '5-Level progressive system: Foundations → Data → AI/ML → Architecture → Impact'
                : '5-स्तर प्रगतिशील प्रणाली: मूलभूत → डेटा → AI/ML → आर्किटेक्चर → प्रभाव'}
            </p>
          </div>
        </div>

        {/* Level filter chips */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setActiveLevel(null)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
              activeLevel === null
                ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30'
                : 'glass-light text-slate-400 hover:text-slate-200'
            }`}
          >
            <Filter className="w-3 h-3 inline mr-1" />
            {lang === 'en' ? 'All Levels' : 'सर्व स्तर'}
          </button>
          {learningLevels.map(lev => (
            <button
              key={lev.level}
              onClick={() => setActiveLevel(lev.level === activeLevel ? null : lev.level)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all level-badge-${lev.color} ${
                activeLevel === lev.level ? 'ring-1 ring-current' : 'opacity-70 hover:opacity-100'
              }`}
            >
              L{lev.level}
            </button>
          ))}
        </div>
      </div>

      {/* Learning levels and modules */}
      {filtered.map(level => {
        const completedInLevel = level.modules.filter(m => completedModules.includes(m.id)).length
        const totalInLevel = level.modules.length

        return (
          <div key={level.id} className="space-y-3 animate-fade-in-up">
            {/* Level header */}
            <div className={`glass-panel rounded-xl p-4 border-l-3 border-${level.color}-500/40`}>
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className={`level-badge-${level.color} px-2 py-0.5 rounded text-[10px] font-bold`}>
                      L{level.level}
                    </span>
                    <h2 className="text-sm font-bold text-slate-200">{level.title[lang]}</h2>
                  </div>
                  <p className="text-xs text-slate-500">{level.subtitle[lang]}</p>
                </div>
                <div className="text-xs text-slate-500">
                  <span className="text-cyan-400 font-semibold">{completedInLevel}</span>/{totalInLevel}
                </div>
              </div>
              {/* Progress bar for level */}
              <div className="mt-3 h-1.5 rounded-full bg-slate-700/60 overflow-hidden">
                <div
                  className={`h-full rounded-full bg-${level.color}-500 transition-all duration-700`}
                  style={{ width: `${totalInLevel === 0 ? 0 : (completedInLevel / totalInLevel) * 100}%` }}
                />
              </div>
            </div>

            {/* Modules */}
            <div className="space-y-2 pl-2">
              {level.modules.map(mod => (
                <AccordionModule
                  key={mod.id}
                  module={mod}
                  lang={lang}
                  isCompleted={completedModules.includes(mod.id)}
                  onComplete={onCompleteModule}
                />
              ))}
            </div>
          </div>
        )
      })}

      {/* Bottom hint */}
      <div className="glass-light rounded-xl p-4 text-center">
        <p className="text-xs text-slate-400">
          {lang === 'en'
            ? 'AI modules update with live data. Static modules track your progress. Click to expand and learn.'
            : 'AI मॉड्यूल थेट डेटासह अद्यतनित होतात. स्थिर मॉड्यूल तुमची प्रगती ट्रॅक करतात. विस्तारित करण्यासाठी क्लिक करा.'}
          <ChevronRight className="w-3 h-3 inline ml-1" />
        </p>
      </div>
    </div>
  )
}
