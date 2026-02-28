import { useState, useCallback } from 'react'
import { Routes, Route } from 'react-router-dom'
import Navbar from './components/Navbar'
import Dashboard from './pages/Dashboard'
import Learning from './pages/Learning'
import Simulator from './pages/Simulator'
import About from './pages/About'
import { uiStrings } from './data/educationData'

export default function App() {
  const [lang, setLang] = useState('en')
  const [region, setRegion] = useState('mumbai')
  const [completedModules, setCompletedModules] = useState([])
  const [simulatorScore, setSimulatorScore] = useState(0)

  const s = uiStrings[lang]

  const handleCompleteModule = useCallback((moduleId) => {
    setCompletedModules(prev =>
      prev.includes(moduleId) ? prev : [...prev, moduleId]
    )
  }, [])

  const handleSimulatorScore = useCallback((score) => {
    setSimulatorScore(score)
  }, [])

  return (
    <div className="min-h-screen flex flex-col relative">
      {/* Background wave */}
      <div className="bg-wave-container">
        <div className="bg-wave-shape" />
      </div>

      {/* Navbar */}
      <Navbar
        lang={lang}
        setLang={setLang}
        region={region}
        setRegion={setRegion}
      />

      {/* Main content */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 py-6 relative z-10">
        <Routes>
          <Route
            path="/"
            element={
              <Dashboard
                lang={lang}
                region={region}
                completedModules={completedModules}
                simulatorScore={simulatorScore}
              />
            }
          />
          <Route
            path="/learning"
            element={
              <Learning
                lang={lang}
                region={region}
                completedModules={completedModules}
                onCompleteModule={handleCompleteModule}
              />
            }
          />
          <Route
            path="/simulator"
            element={
              <Simulator
                lang={lang}
                onScoreUpdate={handleSimulatorScore}
              />
            }
          />
          <Route
            path="/about"
            element={<About lang={lang} />}
          />
        </Routes>
      </main>

      {/* Footer */}
      <footer className="text-center py-4 relative z-10">
        <p className="text-xs text-slate-700">{s.footer}</p>
      </footer>
    </div>
  )
}
