# MediLink AI

**AI-Powered Predictive Hospital Resource Orchestration Engine**

MediLink AI is a real-time resource orchestration platform that predicts hospital sustainability windows and autonomously executes cross-facility resource transfers before crises happen — turning reactive emergency response into proactive network intelligence.

---

## 🎯 Core Features

### 🧠 AI-Powered Recommendations (Gemini API)
- Real-time query analysis via Google Gemini 2.0 Flash
- Ranked hospital recommendations with per-hospital reasoning
- Specialty matching (ICU, trauma, pediatric, respiratory)
- Graceful offline fallback using weighted multi-criteria scoring

### ⏱ Buffer Time Prediction
- Calculates hours until each resource type depletes
- Per-hospital consumption rates (calibrated via hourly snapshots)
- "Earliest collapse" alert on dashboard when any hospital is < 2h from depletion
- Color-coded urgency: 🔴 < 2h, 🟠 < 6h, 🟢 > 6h

### 🚑 Ambulance Shadow Load
- Real-time tracking of en-route ambulances
- Predicted bed availability = current beds − incoming ambulances
- Transfer engine blocks draining hospitals with urgent incoming (ETA < 30 min)
- Live "🚑 X incoming" badge on hospital cards

### 🔄 Network-Level Resource Optimization
- Greedy multi-hospital transfer algorithm (not naive pairwise)
- Safety margins: minimum reserve thresholds per resource type
- Transit deterioration estimation (resource consumption during transfer delay)
- Before → after health score preview with percentage improvement

### 🔐 Authentication & Audit Trail
- Firebase Auth (anonymous guest + email/password admin)
- Every transfer recorded: who, when, from/to, before/after values
- Immutable audit log with timeline view
- "Lives impacted" counter: transfers × estimated patients served

### 🔬 Digital Twin Simulation
- Adjust patient arrival rate and consumption rate via sliders
- Watch buffer times and hospital status respond in real-time
- Network health score updates live
- "What-If" scenario: simulate any hospital going offline

### 📊 Network Health Score
- Single 0-100 gauge: weighted average of capacity + buffer time across all hospitals
- Live on dashboard with CRITICAL / MODERATE / HEALTHY labels
- Impact tracking: total transfers and estimated lives served

---

## 🏥 Resources Tracked

| Resource | Field | Default Consumption |
|---|---|---|
| General Beds | `beds` | 2.0 / hour |
| Oxygen | `oxygen` | 5.0 / hour |
| ICU Beds | `icuBeds` | 0.5 / hour |
| Ventilators | `ventilators` | 0.3 / hour |
| Pediatric Beds | `pediatricBeds` | — |
| Trauma Beds | `traumaBeds` | — |

---

## 🏗 Architecture

```
lib/
├── main.dart                          # App entry, Provider setup, auth gate
├── src/
│   ├── models/
│   │   ├── hospital.dart              # Hospital with buffer time, shadow load
│   │   ├── ambulance.dart             # Ambulance tracking model
│   │   ├── transfer_suggestion.dart   # Transfer plan with safety margins
│   │   ├── ai_recommendation.dart     # AI analysis result models
│   │   ├── audit_log.dart             # Immutable transfer record
│   │   └── bed_type.dart              # Resource type classification
│   ├── services/
│   │   ├── ai_service.dart            # Gemini API integration + fallback
│   │   ├── auth_service.dart          # Firebase Auth wrapper
│   │   ├── hospital_repository.dart   # Transactional Firestore access
│   │   ├── ambulance_repository.dart  # Ambulance real-time streaming
│   │   └── audit_repository.dart      # Audit log persistence
│   ├── providers/
│   │   └── app_providers.dart         # Central ChangeNotifier state
│   ├── utils/
│   │   ├── hospital_advisor.dart      # Network-level optimization engine
│   │   ├── constants.dart             # Centralized configuration
│   │   └── time_utils.dart            # Shared formatting utilities
│   ├── widgets/                       # Reusable UI components
│   ├── screens/                       # Feature screens
│   └── theme/                         # Design system
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.11.4
- Firebase project with Firestore, Auth enabled
- (Optional) Gemini API key for real AI recommendations

### Setup
```bash
# Install dependencies
flutter pub get

# Run with Gemini AI (optional)
flutter run --dart-define=GEMINI_API_KEY=your_key_here

# Run without AI (uses offline scoring)
flutter run
```

### Firestore Security Rules
Deploy the included `firestore.rules` to your Firebase project:
```bash
firebase deploy --only firestore:rules
```

---

## 📄 License

Built for hackathon demonstration. All rights reserved.
