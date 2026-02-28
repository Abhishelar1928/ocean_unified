import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { Waves, BarChart3, BookOpen, Crosshair, Info, Globe, Menu, X } from 'lucide-react'
import { regions, uiStrings } from '../data/educationData'

export default function Navbar({ lang, setLang, region, setRegion }) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const s = uiStrings[lang]

  const links = [
    { to: '/', icon: BarChart3, label: s.dashboard },
    { to: '/learning', icon: BookOpen, label: s.learning },
    { to: '/simulator', icon: Crosshair, label: s.simulator },
    { to: '/about', icon: Info, label: s.about },
  ]

  return (
    <nav className="glass sticky top-0 z-50 border-b border-slate-700/40">
      <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between gap-4">
        {/* Logo */}
        <NavLink to="/" className="flex items-center gap-2 shrink-0">
          <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center">
            <Waves className="w-5 h-5 text-white" />
          </div>
          <div className="hidden sm:block">
            <div className="text-sm font-bold text-white leading-tight">{s.platformName}</div>
            <div className="text-[10px] text-cyan-400/80 leading-tight">{s.tagline}</div>
          </div>
        </NavLink>

        {/* Desktop nav */}
        <div className="hidden md:flex items-center gap-1">
          {links.map(l => (
            <NavLink
              key={l.to}
              to={l.to}
              end={l.to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium transition-all duration-200 ${
                  isActive
                    ? 'bg-cyan-500/15 text-cyan-300 border border-cyan-500/25'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-700/40'
                }`
              }
            >
              <l.icon className="w-3.5 h-3.5" />
              {l.label}
            </NavLink>
          ))}
        </div>

        {/* Region + Lang controls */}
        <div className="flex items-center gap-2">
          {/* Region selector */}
          <select
            value={region}
            onChange={e => setRegion(e.target.value)}
            className="region-select glass-light rounded-lg px-3 py-1.5 text-xs text-slate-200 pr-8 cursor-pointer focus:outline-none focus:ring-1 focus:ring-cyan-500/50 max-w-[180px]"
          >
            {regions.map(r => (
              <option key={r.id} value={r.id} className="bg-slate-800 text-slate-200">
                {r.label[lang]}
              </option>
            ))}
          </select>

          {/* Language toggle */}
          <button
            onClick={() => setLang(prev => (prev === 'en' ? 'mr' : 'en'))}
            className="glass-light rounded-lg px-2.5 py-1.5 text-xs font-medium text-cyan-300 hover:bg-slate-600/40 transition-colors flex items-center gap-1"
            title={lang === 'en' ? 'मराठी' : 'English'}
          >
            <Globe className="w-3.5 h-3.5" />
            {lang === 'en' ? 'MR' : 'EN'}
          </button>

          {/* Mobile menu button */}
          <button
            onClick={() => setMobileOpen(!mobileOpen)}
            className="md:hidden glass-light rounded-lg p-1.5 text-slate-400 hover:text-white transition-colors"
          >
            {mobileOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Mobile nav */}
      {mobileOpen && (
        <div className="md:hidden border-t border-slate-700/40 px-4 py-2 animate-slide-down">
          {links.map(l => (
            <NavLink
              key={l.to}
              to={l.to}
              end={l.to === '/'}
              onClick={() => setMobileOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-cyan-500/15 text-cyan-300'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-700/30'
                }`
              }
            >
              <l.icon className="w-4 h-4" />
              {l.label}
            </NavLink>
          ))}
        </div>
      )}
    </nav>
  )
}
