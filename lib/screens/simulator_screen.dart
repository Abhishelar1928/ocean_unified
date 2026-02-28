// ═══════════════════════════════════════════════════════════════════
// Fisherman EduSea – Decision Simulator Screen
// Ported from fisherman-edusea/src/pages/Simulator.jsx
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/simulator_scenario.dart';
import '../state/app_state.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  int _current = 0;
  String? _selected; // option id
  bool _answered = false;
  int _score = 0;
  bool _completed = false;

  SimulatorScenario get _scenario => simulatorScenarios[_current];
  int get _total => simulatorScenarios.length;

  void _handleCheck() {
    if (_selected == null) return;
    setState(() {
      _answered = true;
      if (_selected == _scenario.correct) {
        _score++;
        // Persist to AppState
        context.read<AppState>().updateSimulatorScore(_score);
      }
    });
  }

  void _handleNext() {
    if (_current < _total - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _completed = true);
      context.read<AppState>().updateSimulatorScore(_score);
    }
  }

  void _handleRestart() {
    setState(() {
      _current = 0;
      _selected = null;
      _answered = false;
      _score = 0;
      _completed = false;
    });
    context.read<AppState>().updateSimulatorScore(0);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().lang;
    final s = AppStrings.of(lang);

    return _completed ? _buildComplete(s, lang) : _buildScenario(s, lang);
  }

  // ─────────────────── Completion screen ──────────────────────────

  Widget _buildComplete(AppStrings s, AppLang lang) {
    final pct = (_score / _total * 100).round();
    Color barColor;
    String message;

    if (pct >= 80) {
      barColor = Colors.green;
      message = lang == AppLang.en
          ? 'Excellent! You\'re a data-driven fisherman.'
          : 'उत्कृष्ट! तुम्ही डेटा-चालित मच्छीमार आहात.';
    } else if (pct >= 50) {
      barColor = Colors.amber;
      message = lang == AppLang.en
          ? 'Good effort! Review the learning modules for better scores.'
          : 'चांगला प्रयत्न! चांगल्या गुणांसाठी शिक्षण मॉड्यूल पुन्हा पहा.';
    } else {
      barColor = Colors.red;
      message = lang == AppLang.en
          ? 'Keep learning! The education center has all the answers.'
          : 'शिकत रहा! शिक्षण केंद्रात सर्व उत्तरे आहेत.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      size: 44, color: Colors.teal),
                ),
                const SizedBox(height: 20),
                Text(
                  s.simulatorComplete,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_score/$_total',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Text('${s.yourScore}: $pct%',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                // Score bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 14,
                    backgroundColor: Colors.grey[200],
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _handleRestart,
                  icon: const Icon(Icons.refresh),
                  label: Text(s.restartSimulator),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Active scenario ────────────────────────────

  Widget _buildScenario(AppStrings s, AppLang lang) {
    final scenario = _scenario;
    final isCorrect = _selected == scenario.correct;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header card ──────────────────────────────────────────
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gps_fixed,
                          color: Colors.green, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.decisionSimulator,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${s.scenario} ${_current + 1} ${s.scenarioOf} $_total',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${s.score}: $_score/$_total',
                      style: const TextStyle(
                          color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_current + 1) / _total,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Situation card ───────────────────────────────────────
        Card(
          color: Colors.teal.withOpacity(0.06),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == AppLang.en ? 'SITUATION' : 'परिस्थिती',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang == AppLang.en
                      ? scenario.situation.en
                      : scenario.situation.mr,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Question + options ───────────────────────────────────
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == AppLang.en
                      ? scenario.question.en
                      : scenario.question.mr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...scenario.options.map((opt) {
                  return _buildOption(opt, lang, scenario.correct);
                }).toList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Answer feedback ──────────────────────────────────────
        if (_answered) _buildFeedback(scenario, lang, isCorrect),

        const SizedBox(height: 12),

        // ── Action buttons ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_answered)
              ElevatedButton(
                onPressed: _selected != null ? _handleCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(s.checkAnswer),
              )
            else
              ElevatedButton.icon(
                onPressed: _handleNext,
                icon: const Icon(Icons.chevron_right),
                label: Text(_current < _total - 1
                    ? s.nextScenario
                    : s.simulatorComplete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOption(SimulatorOption opt, AppLang lang, String correctId) {
    final bool selected = _selected == opt.id;
    final bool isCorrectOpt = opt.id == correctId;

    Color borderColor;
    Color? bgColor;

    if (_answered) {
      if (isCorrectOpt) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.08);
      } else if (selected && !isCorrectOpt) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.08);
      } else {
        borderColor = Colors.grey.withOpacity(0.2);
        bgColor = null;
      }
    } else {
      borderColor = selected ? Colors.teal : Colors.grey.withOpacity(0.3);
      bgColor = selected ? Colors.teal.withOpacity(0.06) : null;
    }

    return GestureDetector(
      onTap: _answered ? null : () => setState(() => _selected = opt.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Circle badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _badgeBg(opt.id, correctId),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _badgeBorderColor(opt.id, correctId), width: 1.5),
              ),
              child: Center(
                child: Text(
                  opt.id.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _badgeTextColor(opt.id, correctId)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lang == AppLang.en ? opt.text.en : opt.text.mr,
                style: TextStyle(
                  fontSize: 13,
                  color: _answered && !isCorrectOpt && !selected
                      ? Colors.grey[400]
                      : null,
                ),
              ),
            ),
            if (_answered && isCorrectOpt)
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 18),
            if (_answered && selected && !isCorrectOpt)
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
          ],
        ),
      ),
    );
  }

  Color _badgeBg(String optId, String correctId) {
    if (!_answered) {
      return _selected == optId
          ? Colors.teal.withOpacity(0.2)
          : Colors.grey.withOpacity(0.15);
    }
    if (optId == correctId) return Colors.green;
    if (optId == _selected) return Colors.red;
    return Colors.grey.withOpacity(0.15);
  }

  Color _badgeBorderColor(String optId, String correctId) {
    if (!_answered) {
      return _selected == optId ? Colors.teal : Colors.grey;
    }
    if (optId == correctId) return Colors.green;
    if (optId == _selected) return Colors.red;
    return Colors.grey;
  }

  Color _badgeTextColor(String optId, String correctId) {
    if (!_answered) {
      return _selected == optId ? Colors.teal : Colors.grey;
    }
    if (optId == correctId || optId == _selected) return Colors.white;
    return Colors.grey;
  }

  Widget _buildFeedback(
      SimulatorScenario scenario, AppLang lang, bool isCorrect) {
    return Card(
      color: isCorrect
          ? Colors.green.withOpacity(0.06)
          : Colors.amber.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isCorrect
                ? Colors.green.withOpacity(0.4)
                : Colors.amber.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_outline : Icons.warning_amber,
                  color: isCorrect ? Colors.green : Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isCorrect
                      ? AppStrings.of(lang).correct
                      : AppStrings.of(lang).incorrect,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lang == AppLang.en
                  ? scenario.explanation.en
                  : scenario.explanation.mr,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lang == AppLang.en
                    ? scenario.safetyMessage.en
                    : scenario.safetyMessage.mr,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.teal,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
