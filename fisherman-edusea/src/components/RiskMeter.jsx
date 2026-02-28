import { useEffect, useState } from 'react'

const colorMap = {
  emerald: { bar: 'bg-emerald-500', glow: 'shadow-emerald-500/30', text: 'text-emerald-400', bg: 'bg-emerald-500/10' },
  cyan:    { bar: 'bg-cyan-500',    glow: 'shadow-cyan-500/30',    text: 'text-cyan-400',    bg: 'bg-cyan-500/10' },
  amber:   { bar: 'bg-amber-500',   glow: 'shadow-amber-500/30',   text: 'text-amber-400',   bg: 'bg-amber-500/10' },
  red:     { bar: 'bg-red-500',     glow: 'shadow-red-500/30',     text: 'text-red-400',     bg: 'bg-red-500/10' },
  slate:   { bar: 'bg-slate-400',   glow: 'shadow-slate-400/30',   text: 'text-slate-400',   bg: 'bg-slate-400/10' },
  blue:    { bar: 'bg-blue-500',    glow: 'shadow-blue-500/30',    text: 'text-blue-400',    bg: 'bg-blue-500/10' },
  purple:  { bar: 'bg-purple-500',  glow: 'shadow-purple-500/30',  text: 'text-purple-400',  bg: 'bg-purple-500/10' },
}

export default function RiskMeter({ label, value, maxValue = 100, color = 'cyan', description, icon: Icon }) {
  const [animated, setAnimated] = useState(0)
  const pct = Math.round((value / maxValue) * 100)
  const c = colorMap[color] || colorMap.cyan

  useEffect(() => {
    const timer = setTimeout(() => setAnimated(pct), 100)
    return () => clearTimeout(timer)
  }, [pct])

  return (
    <div className="glass-card rounded-xl p-4 space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          {Icon && (
            <div className={`w-8 h-8 rounded-lg ${c.bg} flex items-center justify-center`}>
              <Icon className={`w-4 h-4 ${c.text}`} />
            </div>
          )}
          <span className="text-sm font-semibold text-slate-200">{label}</span>
        </div>
        <span className={`text-lg font-bold ${c.text}`}>{value}<span className="text-xs text-slate-500">/{maxValue}</span></span>
      </div>

      {/* Bar */}
      <div className="relative h-3 rounded-full bg-slate-700/60 overflow-hidden">
        <div
          className={`absolute h-full rounded-full ${c.bar} ${c.glow} shadow-lg transition-all duration-1000 ease-out`}
          style={{ width: `${animated}%` }}
        />
        <div className="absolute inset-0 animate-shimmer rounded-full" />
      </div>

      {/* Description */}
      {description && (
        <p className="text-xs text-slate-400 leading-relaxed">{description}</p>
      )}
    </div>
  )
}
