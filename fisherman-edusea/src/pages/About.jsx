import {
  Anchor, Waves, Database, Brain, Plug, Monitor, BookOpen, Target,
  Satellite, Radio, Globe, ShieldCheck, ArrowRight, ChevronRight
} from 'lucide-react'
import { uiStrings } from '../data/educationData'
import { useNavigate } from 'react-router-dom'

export default function About({ lang }) {
  const s = uiStrings[lang]
  const navigate = useNavigate()

  const pipeline = [
    { icon: Satellite, label: lang === 'en' ? 'Satellite + Buoy Data' : 'उपग्रह + बॉय डेटा', desc: lang === 'en' ? 'NOAA, Copernicus, INCOIS' : 'NOAA, Copernicus, INCOIS', color: 'cyan' },
    { icon: Database, label: lang === 'en' ? 'Data Aggregation' : 'डेटा एकत्रीकरण', desc: lang === 'en' ? 'SST, Chlorophyll, Wave, Wind' : 'SST, क्लोरोफिल, लहर, वारा', color: 'blue' },
    { icon: Brain, label: lang === 'en' ? 'AI Processing' : 'AI प्रक्रिया', desc: lang === 'en' ? 'Regression, Classification, Anomaly' : 'रिग्रेशन, वर्गीकरण, विसंगती', color: 'purple' },
    { icon: Plug, label: lang === 'en' ? 'API Output' : 'API आउटपुट', desc: lang === 'en' ? 'REST JSON endpoints' : 'REST JSON एंडपॉइंट', color: 'amber' },
    { icon: Monitor, label: lang === 'en' ? 'Dashboard' : 'डॅशबोर्ड', desc: lang === 'en' ? 'Location-based metrics' : 'स्थान-आधारित मेट्रिक्स', color: 'emerald' },
    { icon: BookOpen, label: lang === 'en' ? 'Education + Simulator' : 'शिक्षण + सिम्युलेटर', desc: lang === 'en' ? '5-level learning system' : '5-स्तर शिक्षण प्रणाली', color: 'rose' },
  ]

  const colorBg = {
    cyan: 'bg-cyan-500/10', blue: 'bg-blue-500/10', purple: 'bg-purple-500/10',
    amber: 'bg-amber-500/10', emerald: 'bg-emerald-500/10', rose: 'bg-rose-500/10'
  }
  const colorText = {
    cyan: 'text-cyan-400', blue: 'text-blue-400', purple: 'text-purple-400',
    amber: 'text-amber-400', emerald: 'text-emerald-400', rose: 'text-rose-400'
  }

  return (
    <div className="space-y-6 animate-fade-in-up">
      {/* Hero */}
      <div className="glass-panel rounded-2xl p-6 text-center">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-cyan-500/20 to-blue-600/20 flex items-center justify-center mx-auto mb-4">
          <Anchor className="w-8 h-8 text-cyan-400" />
        </div>
        <h1 className="text-xl font-bold text-white mb-2">{s.aboutTitle}</h1>
        <p className="text-sm text-slate-400 max-w-2xl mx-auto leading-relaxed">{s.aboutMissionText}</p>
      </div>

      {/* System Architecture */}
      <div className="glass-panel rounded-2xl p-6">
        <h2 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
          <Globe className="w-4 h-4 text-cyan-400" />
          {s.systemArchitecture}
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {pipeline.map((step, i) => (
            <div key={i} className="glass-card rounded-xl p-4 relative">
              <div className="flex items-center gap-3 mb-2">
                <div className={`w-10 h-10 rounded-xl ${colorBg[step.color]} flex items-center justify-center`}>
                  <step.icon className={`w-5 h-5 ${colorText[step.color]}`} />
                </div>
                <div>
                  <div className="text-[10px] text-slate-500">Step {i + 1}</div>
                  <h3 className="text-sm font-semibold text-slate-200">{step.label}</h3>
                </div>
              </div>
              <p className="text-xs text-slate-400">{step.desc}</p>
              {i < pipeline.length - 1 && (
                <div className="hidden lg:flex absolute -right-2 top-1/2 -translate-y-1/2 z-10">
                  <ChevronRight className="w-4 h-4 text-slate-600" />
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Pipeline flow arrow */}
        <div className="mt-4 flex items-center justify-center gap-2 text-xs text-slate-500">
          <span>Data Layer</span>
          <ArrowRight className="w-3 h-3" />
          <span>AI Processing</span>
          <ArrowRight className="w-3 h-3" />
          <span>API</span>
          <ArrowRight className="w-3 h-3" />
          <span>Dashboard</span>
          <ArrowRight className="w-3 h-3" />
          <span>Education</span>
        </div>
      </div>

      {/* Data integration info */}
      <div className="glass-panel rounded-2xl p-6">
        <h2 className="text-sm font-bold text-white mb-2 flex items-center gap-2">
          <Database className="w-4 h-4 text-blue-400" />
          {s.aboutIntegration}
        </h2>
        <p className="text-sm text-slate-400 leading-relaxed mb-4">{s.aboutIntegrationText}</p>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {[
            { icon: Satellite, label: 'NOAA / Copernicus', desc: lang === 'en' ? 'SST, Chlorophyll, Ocean Color satellite imagery' : 'SST, क्लोरोफिल, सागर रंग उपग्रह प्रतिमा' },
            { icon: Radio, label: 'INCOIS Buoys', desc: lang === 'en' ? 'Real-time wave height, salinity, temperature from ocean buoys' : 'बॉय वरून रिअल-टाइम लहर उंची, क्षारता, तापमान' },
            { icon: Globe, label: 'OpenWeather Marine', desc: lang === 'en' ? 'Wind speed, visibility, atmospheric pressure forecasts' : 'वाऱ्याचा वेग, दृश्यमानता, वातावरणीय दाब अंदाज' },
            { icon: Target, label: 'CMFRI Historical', desc: lang === 'en' ? 'CPUE records, species distribution, seasonal migration data' : 'CPUE नोंदी, प्रजाती वितरण, हंगामी स्थलांतर डेटा' },
          ].map((src, i) => (
            <div key={i} className="glass-card rounded-xl p-3 flex items-start gap-3">
              <div className="w-8 h-8 rounded-lg bg-blue-500/10 flex items-center justify-center shrink-0 mt-0.5">
                <src.icon className="w-4 h-4 text-blue-400" />
              </div>
              <div>
                <h4 className="text-xs font-semibold text-slate-200">{src.label}</h4>
                <p className="text-[11px] text-slate-500 mt-0.5">{src.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Features */}
      <div className="glass-panel rounded-2xl p-6">
        <h2 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-emerald-400" />
          {s.aboutFeatures}
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {s.aboutFeaturesList.map((feat, i) => (
            <div key={i} className="flex items-start gap-2 text-xs text-slate-300">
              <div className="w-1.5 h-1.5 rounded-full bg-cyan-500 mt-1.5 shrink-0" />
              <span>{feat}</span>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="glass-accent rounded-2xl p-6 text-center space-y-4">
        <h3 className="text-sm font-bold text-white">
          {lang === 'en' ? 'Ready to explore?' : 'शोधण्यासाठी तयार?'}
        </h3>
        <div className="flex flex-wrap justify-center gap-3">
          <button
            onClick={() => navigate('/')}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-cyan-500/15 hover:bg-cyan-500/25 border border-cyan-500/25 text-cyan-300 text-xs font-medium transition-colors"
          >
            <Monitor className="w-3.5 h-3.5" /> {s.viewDashboard}
          </button>
          <button
            onClick={() => navigate('/learning')}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-blue-500/15 hover:bg-blue-500/25 border border-blue-500/25 text-blue-300 text-xs font-medium transition-colors"
          >
            <BookOpen className="w-3.5 h-3.5" /> {s.startLearning}
          </button>
          <button
            onClick={() => navigate('/simulator')}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-500/15 hover:bg-emerald-500/25 border border-emerald-500/25 text-emerald-300 text-xs font-medium transition-colors"
          >
            <Target className="w-3.5 h-3.5" /> {s.startSimulator}
          </button>
        </div>
      </div>

      {/* Footer */}
      <div className="text-center py-4">
        <p className="text-xs text-slate-600">{s.footer}</p>
      </div>
    </div>
  )
}
