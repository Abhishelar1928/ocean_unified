// ═══════════════════════════════════════════════════════════════════
// Fisherman EduSea – i18n string tables
// Ported from fisherman-edusea/src/data/educationData.js (uiStrings)
// ═══════════════════════════════════════════════════════════════════

enum AppLang { en, mr }

class AppStrings {
  final String platformName;
  final String tagline;
  final String dashboard;
  final String learning;
  final String simulator;
  final String about;
  final String selectRegion;
  final String seaStatus;
  final String riskLevel;
  final String fishActivity;
  final String learningCenter;
  final String decisionSimulator;
  final String progress;
  final String lessonsCompleted;
  final String safetyKnowledge;
  final String badge;
  final String safeFisherman;
  final String startLearning;
  final String startSimulator;
  final String viewDashboard;
  final String whatThisMeans;
  final String actionSteps;
  final String nextScenario;
  final String tryAgain;
  final String checkAnswer;
  final String correct;
  final String incorrect;
  final String selectOption;
  final String scenario;
  final String scenarioOf; // "of" as in "Scenario 2 of 5"
  final String score;
  final String simulatorComplete;
  final String yourScore;
  final String restartSimulator;
  final String liveConditions;
  final String quickActions;
  final String oceanData;
  final String riskFormula;
  final String fishFormula;
  final String dataSource;
  final String coordinates;
  final String parameters;
  final String systemArchitecture;
  final String language;

  const AppStrings._({
    required this.platformName,
    required this.tagline,
    required this.dashboard,
    required this.learning,
    required this.simulator,
    required this.about,
    required this.selectRegion,
    required this.seaStatus,
    required this.riskLevel,
    required this.fishActivity,
    required this.learningCenter,
    required this.decisionSimulator,
    required this.progress,
    required this.lessonsCompleted,
    required this.safetyKnowledge,
    required this.badge,
    required this.safeFisherman,
    required this.startLearning,
    required this.startSimulator,
    required this.viewDashboard,
    required this.whatThisMeans,
    required this.actionSteps,
    required this.nextScenario,
    required this.tryAgain,
    required this.checkAnswer,
    required this.correct,
    required this.incorrect,
    required this.selectOption,
    required this.scenario,
    required this.scenarioOf,
    required this.score,
    required this.simulatorComplete,
    required this.yourScore,
    required this.restartSimulator,
    required this.liveConditions,
    required this.quickActions,
    required this.oceanData,
    required this.riskFormula,
    required this.fishFormula,
    required this.dataSource,
    required this.coordinates,
    required this.parameters,
    required this.systemArchitecture,
    required this.language,
  });

  static AppStrings of(AppLang lang) => lang == AppLang.en ? en : mr;

  static const AppStrings en = AppStrings._(
    platformName: 'Fisherman EduSea',
    tagline: 'AI-Driven Marine Intelligence',
    dashboard: 'Marine Dashboard',
    learning: 'Learning',
    simulator: 'Simulator',
    about: 'About',
    selectRegion: 'Select Fishing Region',
    seaStatus: 'Sea Status',
    riskLevel: 'Safety Risk',
    fishActivity: 'Fish Activity',
    learningCenter: 'Learning Center',
    decisionSimulator: 'Decision Simulator',
    progress: 'Your Progress',
    lessonsCompleted: 'Modules Explored',
    safetyKnowledge: 'Safety Knowledge',
    badge: 'Badge',
    safeFisherman: 'Smart Fisherman',
    startLearning: 'Open Learning Center',
    startSimulator: 'Start Simulator',
    viewDashboard: 'View Dashboard',
    whatThisMeans: 'What This Means For You',
    actionSteps: 'Action Steps',
    nextScenario: 'Next Scenario',
    tryAgain: 'Try Again',
    checkAnswer: 'Check Answer',
    correct: 'Correct!',
    incorrect: 'Not quite right.',
    selectOption: 'Select an option',
    scenario: 'Scenario',
    scenarioOf: 'of',
    score: 'Score',
    simulatorComplete: 'Simulator Complete!',
    yourScore: 'Your Score',
    restartSimulator: 'Restart Simulator',
    liveConditions: 'Live Oceanographic Conditions',
    quickActions: 'Quick Actions',
    oceanData: 'Oceanographic Data',
    riskFormula: 'Risk Formula',
    fishFormula: 'Fish Activity Formula',
    dataSource: 'Data Sources',
    coordinates: 'Coordinates',
    parameters: 'Parameters',
    systemArchitecture: 'System Architecture',
    language: 'Language',
  );

  static const AppStrings mr = AppStrings._(
    platformName: 'फिशरमन एडुसी',
    tagline: 'AI-चालित सागरी बुद्धिमत्ता',
    dashboard: 'सागरी डॅशबोर्ड',
    learning: 'शिक्षण',
    simulator: 'सिम्युलेटर',
    about: 'माहिती',
    selectRegion: 'मासेमारी प्रदेश निवडा',
    seaStatus: 'समुद्र स्थिती',
    riskLevel: 'सुरक्षा धोका',
    fishActivity: 'मासे सक्रियता',
    learningCenter: 'शिक्षण केंद्र',
    decisionSimulator: 'निर्णय सिम्युलेटर',
    progress: 'तुमची प्रगती',
    lessonsCompleted: 'मॉड्यूल शोधले',
    safetyKnowledge: 'सुरक्षा ज्ञान',
    badge: 'बॅज',
    safeFisherman: 'स्मार्ट मच्छीमार',
    startLearning: 'शिक्षण केंद्र उघडा',
    startSimulator: 'सिम्युलेटर सुरू करा',
    viewDashboard: 'डॅशबोर्ड पहा',
    whatThisMeans: 'तुमच्यासाठी याचा अर्थ',
    actionSteps: 'कृती पावले',
    nextScenario: 'पुढचा प्रसंग',
    tryAgain: 'पुन्हा प्रयत्न करा',
    checkAnswer: 'उत्तर तपासा',
    correct: 'बरोबर!',
    incorrect: 'अगदी बरोबर नाही.',
    selectOption: 'पर्याय निवडा',
    scenario: 'प्रसंग',
    scenarioOf: 'पैकी',
    score: 'गुण',
    simulatorComplete: 'सिम्युलेटर पूर्ण!',
    yourScore: 'तुमचे गुण',
    restartSimulator: 'सिम्युलेटर पुन्हा सुरू करा',
    liveConditions: 'थेट समुद्रशास्त्रीय परिस्थिती',
    quickActions: 'त्वरित कृती',
    oceanData: 'समुद्रशास्त्रीय डेटा',
    riskFormula: 'धोका सूत्र',
    fishFormula: 'मासे सक्रियता सूत्र',
    dataSource: 'डेटा स्रोत',
    coordinates: 'निर्देशांक',
    parameters: 'मापदंड',
    systemArchitecture: 'प्रणाली आर्किटेक्चर',
    language: 'भाषा',
  );
}
