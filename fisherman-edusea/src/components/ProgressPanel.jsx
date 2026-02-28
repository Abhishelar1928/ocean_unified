import { Award, BookOpen, ShieldCheck, TrendingUp } from 'lucide-react'
import { allLearningModules, simulatorScenarios, uiStrings } from '../data/educationData'

export default function ProgressPanel({ lang = 'en', completedModules = [], simulatorScore = 0 }) {
  const s = uiStrings[lang]
  const total = allLearningModules.length
  const done = completedModules.length
  const pct = total === 0 ? 0 : Math.round((done / total) * 100)

  const simTotal = simulatorScenarios.length
  const simPct = simTotal === 0 ? 0 : Math.round((simulatorScore / simTotal) * 100)

  // Badge logic
  const badges = []
  if (done >= 3) badges.push({ icon: BookOpen, label: lang === 'en' ? 'Explorer' : 'संशोधक', color: 'text-cyan-400 bg-cyan-500/10' })
  if (done >= 8) badges.push({ icon: TrendingUp, label: lang === 'en' ? 'Data Scientist' : 'डेटा शास्त्रज्ञ', color: 'text-blue-400 bg-blue-500/10' })
  if (simulatorScore >= 3) badges.push({ icon: ShieldCheck, label: lang === 'en' ? 'Safety Pro' : 'सुरक्षा तज्ञ', color: 'text-emerald-400 bg-emerald-500/10' })
  if (done >= total && simulatorScore >= simTotal) badges.push({ icon: Award, label: s.safeFisherman, color: 'text-amber-400 bg-amber-500/10' })

  return (
    <div className="glass-panel rounded-xl p-5 space-y-5">
      <h3 className="text-sm font-bold text-slate-200 flex items-center gap-2">
        <Award className="w-4 h-4 text-cyan-400" />
        {s.progress}
      </h3>

      {/* Learning progress */}
      <div>
        <div className="flex justify-between text-xs mb-1.5">
          <span className="text-slate-400">{s.lessonsCompleted}</span>
          <span className="text-cyan-400 font-semibold">{done}/{total}</span>
        </div>
        <div className="h-2.5 rounded-full bg-slate-700/60 overflow-hidden">
          <div
            className="h-full rounded-full bg-gradient-to-r from-cyan-500 to-blue-500 transition-all duration-700 ease-out"
            style={{ width: `${pct}%` }}
          />
        </div>
      </div>

      {/* Simulator progress */}
      <div>
        <div className="flex justify-between text-xs mb-1.5">
          <span className="text-slate-400">{s.safetyKnowledge}</span>
          <span className="text-emerald-400 font-semibold">{simulatorScore}/{simTotal}</span>
        </div>
        <div className="h-2.5 rounded-full bg-slate-700/60 overflow-hidden">
          <div
            className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-teal-500 transition-all duration-700 ease-out"
            style={{ width: `${simPct}%` }}
          />
        </div>
      </div>

      {/* Badges */}
      {badges.length > 0 && (
        <div>
          <div className="text-xs text-slate-500 mb-2">{s.badge}</div>
          <div className="flex flex-wrap gap-2">
            {badges.map((b, i) => (
              <div key={i} className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium ${b.color}`}>
                <b.icon className="w-3.5 h-3.5" />
                {b.label}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
