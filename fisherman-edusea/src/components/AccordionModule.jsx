import { useState } from 'react'
import { ChevronDown, CheckCircle2, Lightbulb, ArrowRight } from 'lucide-react'
import * as LucideIcons from 'lucide-react'

export default function AccordionModule({ module, lang = 'en', isCompleted, onComplete }) {
  const [open, setOpen] = useState(false)
  const IconComponent = LucideIcons[module.icon] || LucideIcons.BookOpen

  const handleToggle = () => {
    setOpen(!open)
    if (!open && !isCompleted) {
      onComplete?.(module.id)
    }
  }

  return (
    <div className={`glass-card rounded-xl overflow-hidden transition-all duration-300 ${open ? 'ring-1 ring-cyan-500/20' : ''}`}>
      {/* Header */}
      <button
        onClick={handleToggle}
        className="w-full flex items-center gap-3 p-4 text-left hover:bg-slate-700/20 transition-colors"
      >
        <div className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${isCompleted ? 'bg-emerald-500/15' : 'bg-cyan-500/10'}`}>
          {isCompleted ? (
            <CheckCircle2 className="w-4.5 h-4.5 text-emerald-400" />
          ) : (
            <IconComponent className="w-4.5 h-4.5 text-cyan-400" />
          )}
        </div>
        <div className="flex-1 min-w-0">
          <h4 className="text-sm font-semibold text-slate-200 truncate">{module.title[lang]}</h4>
        </div>
        <ChevronDown className={`w-4 h-4 text-slate-500 transition-transform duration-300 shrink-0 ${open ? 'rotate-180' : ''}`} />
      </button>

      {/* Expanded content */}
      {open && (
        <div className="px-4 pb-4 animate-slide-down space-y-4">
          {/* Explanation */}
          <div className="glass-light rounded-lg p-3">
            <p className="text-xs text-slate-300 leading-relaxed">{module.explanation[lang]}</p>
          </div>

          {/* What This Means */}
          <div className="glass-accent rounded-lg p-3">
            <div className="flex items-center gap-2 mb-2">
              <Lightbulb className="w-3.5 h-3.5 text-cyan-400" />
              <span className="text-xs font-semibold text-cyan-300">
                {lang === 'en' ? 'What This Means For You' : 'तुमच्यासाठी याचा अर्थ'}
              </span>
            </div>
            <p className="text-xs text-slate-300 leading-relaxed">{module.meaning[lang]}</p>
          </div>

          {/* Action Steps */}
          <div>
            <h5 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
              {lang === 'en' ? 'Action Steps' : 'कृती पावले'}
            </h5>
            <ul className="space-y-1.5">
              {module.actions[lang].map((action, i) => (
                <li key={i} className="flex items-start gap-2 text-xs text-slate-300">
                  <ArrowRight className="w-3 h-3 text-cyan-500 mt-0.5 shrink-0" />
                  <span>{action}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  )
}
