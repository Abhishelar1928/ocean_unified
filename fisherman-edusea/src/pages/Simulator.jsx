import { useState } from 'react'
import { Crosshair, AlertTriangle, CheckCircle2, XCircle, RotateCcw, ChevronRight, ShieldCheck } from 'lucide-react'
import { simulatorScenarios, uiStrings } from '../data/educationData'

export default function Simulator({ lang, onScoreUpdate }) {
  const s = uiStrings[lang]
  const [current, setCurrent] = useState(0)
  const [selected, setSelected] = useState(null)
  const [answered, setAnswered] = useState(false)
  const [score, setScore] = useState(0)
  const [completed, setCompleted] = useState(false)

  const scenario = simulatorScenarios[current]
  const total = simulatorScenarios.length

  const handleCheck = () => {
    if (!selected) return
    setAnswered(true)
    if (selected === scenario.correct) {
      const newScore = score + 1
      setScore(newScore)
      onScoreUpdate?.(newScore)
    }
  }

  const handleNext = () => {
    if (current < total - 1) {
      setCurrent(current + 1)
      setSelected(null)
      setAnswered(false)
    } else {
      setCompleted(true)
    }
  }

  const handleRestart = () => {
    setCurrent(0)
    setSelected(null)
    setAnswered(false)
    setScore(0)
    setCompleted(false)
    onScoreUpdate?.(0)
  }

  if (completed) {
    const pct = Math.round((score / total) * 100)
    return (
      <div className="max-w-xl mx-auto animate-fade-in-scale">
        <div className="glass-panel rounded-2xl p-8 text-center space-y-6">
          <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-cyan-500/20 to-emerald-500/20 flex items-center justify-center mx-auto">
            <ShieldCheck className="w-10 h-10 text-emerald-400" />
          </div>
          <h2 className="text-xl font-bold text-white">{s.simulatorComplete}</h2>
          <div className="text-4xl font-bold text-cyan-400">{score}/{total}</div>
          <p className="text-sm text-slate-400">{s.yourScore}: {pct}%</p>

          {/* Score bar */}
          <div className="h-3 rounded-full bg-slate-700/60 overflow-hidden max-w-xs mx-auto">
            <div
              className={`h-full rounded-full transition-all duration-1000 ${pct >= 80 ? 'bg-emerald-500' : pct >= 50 ? 'bg-amber-500' : 'bg-red-500'}`}
              style={{ width: `${pct}%` }}
            />
          </div>

          <p className="text-xs text-slate-500">
            {pct >= 80
              ? (lang === 'en' ? 'Excellent! You\'re a data-driven fisherman.' : 'उत्कृष्ट! तुम्ही डेटा-चालित मच्छीमार आहात.')
              : pct >= 50
              ? (lang === 'en' ? 'Good effort! Review the learning modules for better scores.' : 'चांगला प्रयत्न! चांगल्या गुणांसाठी शिक्षण मॉड्यूल पुन्हा पहा.')
              : (lang === 'en' ? 'Keep learning! The education center has all the answers.' : 'शिकत रहा! शिक्षण केंद्रात सर्व उत्तरे आहेत.')}
          </p>

          <button
            onClick={handleRestart}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-cyan-500/15 hover:bg-cyan-500/25 border border-cyan-500/25 text-cyan-300 text-sm font-medium transition-colors"
          >
            <RotateCcw className="w-4 h-4" />
            {s.restartSimulator}
          </button>
        </div>
      </div>
    )
  }

  const isCorrect = selected === scenario.correct

  return (
    <div className="max-w-2xl mx-auto space-y-5 animate-fade-in-up">
      {/* Header */}
      <div className="glass-panel rounded-2xl p-5">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center">
              <Crosshair className="w-5 h-5 text-emerald-400" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-white">{s.decisionSimulator}</h1>
              <p className="text-xs text-slate-400">
                {s.scenario} {current + 1} {s.of} {total}
              </p>
            </div>
          </div>
          <div className="text-sm font-bold text-cyan-400">{s.score}: {score}/{total}</div>
        </div>
        {/* Progress bar */}
        <div className="h-1.5 rounded-full bg-slate-700/60 overflow-hidden">
          <div
            className="h-full rounded-full bg-gradient-to-r from-cyan-500 to-emerald-500 transition-all duration-500"
            style={{ width: `${((current + 1) / total) * 100}%` }}
          />
        </div>
      </div>

      {/* Situation */}
      <div className="glass-accent rounded-xl p-4">
        <h3 className="text-xs font-semibold text-cyan-400 uppercase tracking-wider mb-2">
          {lang === 'en' ? 'Situation' : 'परिस्थिती'}
        </h3>
        <p className="text-sm text-slate-200 leading-relaxed">{scenario.situation[lang]}</p>
      </div>

      {/* Question */}
      <div className="glass-panel rounded-xl p-4">
        <p className="text-sm font-semibold text-white mb-4">{scenario.question[lang]}</p>

        {/* Options */}
        <div className="space-y-2">
          {scenario.options.map(opt => {
            let optClass = 'glass-card rounded-lg px-4 py-3 cursor-pointer transition-all border'
            if (answered) {
              if (opt.id === scenario.correct) {
                optClass += ' border-emerald-500/40 bg-emerald-500/10'
              } else if (opt.id === selected && opt.id !== scenario.correct) {
                optClass += ' border-red-500/40 bg-red-500/10'
              } else {
                optClass += ' border-slate-700/30 opacity-50'
              }
            } else {
              optClass += selected === opt.id
                ? ' border-cyan-500/40 bg-cyan-500/10'
                : ' border-slate-700/20 hover:border-cyan-500/20 hover:bg-slate-700/30'
            }

            return (
              <button
                key={opt.id}
                onClick={() => !answered && setSelected(opt.id)}
                disabled={answered}
                className={`${optClass} w-full text-left flex items-center gap-3`}
              >
                <span className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold shrink-0 ${
                  answered && opt.id === scenario.correct
                    ? 'bg-emerald-500 text-white'
                    : answered && opt.id === selected
                    ? 'bg-red-500 text-white'
                    : selected === opt.id
                    ? 'bg-cyan-500/30 text-cyan-300 border border-cyan-500/40'
                    : 'bg-slate-700/50 text-slate-400'
                }`}>
                  {opt.id.toUpperCase()}
                </span>
                <span className="text-sm text-slate-200">{opt.text[lang]}</span>
                {answered && opt.id === scenario.correct && <CheckCircle2 className="w-4 h-4 text-emerald-400 ml-auto shrink-0" />}
                {answered && opt.id === selected && opt.id !== scenario.correct && <XCircle className="w-4 h-4 text-red-400 ml-auto shrink-0" />}
              </button>
            )
          })}
        </div>
      </div>

      {/* Answer feedback */}
      {answered && (
        <div className={`rounded-xl p-4 animate-fade-in-scale ${isCorrect ? 'glass-card border border-emerald-500/20' : 'glass-card border border-amber-500/20'}`}>
          <div className="flex items-center gap-2 mb-2">
            {isCorrect ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            ) : (
              <AlertTriangle className="w-4 h-4 text-amber-400" />
            )}
            <span className={`text-sm font-bold ${isCorrect ? 'text-emerald-400' : 'text-amber-400'}`}>
              {isCorrect ? s.correct : s.incorrect}
            </span>
          </div>
          <p className="text-xs text-slate-300 leading-relaxed mb-3">{scenario.explanation[lang]}</p>
          <div className="glass-light rounded-lg px-3 py-2">
            <p className="text-xs text-cyan-300 font-medium">{scenario.safetyMessage[lang]}</p>
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="flex justify-end gap-3">
        {!answered ? (
          <button
            onClick={handleCheck}
            disabled={!selected}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-medium transition-all ${
              selected
                ? 'bg-cyan-500/15 hover:bg-cyan-500/25 border border-cyan-500/25 text-cyan-300'
                : 'bg-slate-700/30 border border-slate-700/20 text-slate-600 cursor-not-allowed'
            }`}
          >
            {s.checkAnswer}
          </button>
        ) : (
          <button
            onClick={handleNext}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-emerald-500/15 hover:bg-emerald-500/25 border border-emerald-500/25 text-emerald-300 text-sm font-medium transition-colors"
          >
            {current < total - 1 ? s.nextScenario : s.simulatorComplete}
            <ChevronRight className="w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  )
}
