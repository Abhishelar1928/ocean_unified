const colorMap = {
  emerald: { dot: 'bg-emerald-500', ring: 'ring-emerald-500/40', bg: 'bg-emerald-500/10', text: 'text-emerald-400', border: 'border-emerald-500/20' },
  cyan:    { dot: 'bg-cyan-500',    ring: 'ring-cyan-500/40',    bg: 'bg-cyan-500/10',    text: 'text-cyan-400',    border: 'border-cyan-500/20' },
  amber:   { dot: 'bg-amber-500',   ring: 'ring-amber-500/40',   bg: 'bg-amber-500/10',   text: 'text-amber-400',   border: 'border-amber-500/20' },
  red:     { dot: 'bg-red-500',     ring: 'ring-red-500/40',     bg: 'bg-red-500/10',     text: 'text-red-400',     border: 'border-red-500/20' },
  slate:   { dot: 'bg-slate-400',   ring: 'ring-slate-400/40',   bg: 'bg-slate-400/10',   text: 'text-slate-400',   border: 'border-slate-400/20' },
  blue:    { dot: 'bg-blue-500',    ring: 'ring-blue-500/40',    bg: 'bg-blue-500/10',    text: 'text-blue-400',    border: 'border-blue-500/20' },
  purple:  { dot: 'bg-purple-500',  ring: 'ring-purple-500/40',  bg: 'bg-purple-500/10',  text: 'text-purple-400',  border: 'border-purple-500/20' },
}

export default function StatusIndicator({ label, value, color = 'cyan', subtitle, icon: Icon, items }) {
  const c = colorMap[color] || colorMap.cyan

  return (
    <div className={`glass-card rounded-xl p-5 border-l-2 ${c.border}`}>
      {/* Header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          {Icon && (
            <div className={`w-10 h-10 rounded-xl ${c.bg} flex items-center justify-center`}>
              <Icon className={`w-5 h-5 ${c.text}`} />
            </div>
          )}
          <div>
            <h3 className="text-sm font-semibold text-slate-200">{label}</h3>
            {subtitle && <p className="text-xs text-slate-500 mt-0.5">{subtitle}</p>}
          </div>
        </div>
        {/* Live dot */}
        <div className="flex items-center gap-1.5">
          <span className={`w-2 h-2 rounded-full ${c.dot} animate-pulse`} />
          <span className={`text-xs font-bold ${c.text}`}>{value}</span>
        </div>
      </div>

      {/* Optional data items */}
      {items && items.length > 0 && (
        <div className="grid grid-cols-2 gap-2 mt-3">
          {items.map((item, i) => (
            <div key={i} className="glass-light rounded-lg px-3 py-2">
              <div className="text-[10px] text-slate-500 uppercase tracking-wider">{item.label}</div>
              <div className="text-sm font-semibold text-slate-200 mt-0.5">{item.value}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
