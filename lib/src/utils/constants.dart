/// Centralised configuration constants — no magic numbers in business logic.
class AppConstants {
  AppConstants._();

  // ── Resource reserve thresholds ──────────────────────────────────────
  static const int minBedReserve = 5;
  static const int minOxygenReserve = 10;
  static const int minIcuReserve = 2;
  static const int minVentilatorReserve = 1;

  // ── Default consumption rates (units / hour) ────────────────────────
  static const double defaultBedConsumptionRate = 2.0;
  static const double defaultOxygenConsumptionRate = 5.0;
  static const double defaultIcuConsumptionRate = 0.5;
  static const double defaultVentilatorConsumptionRate = 0.3;

  // ── Transfer logistics ───────────────────────────────────────────────
  static const int transferDelayMinutes = 25;
  static const double deteriorationRatePerHour = 2.0;

  // ── Capacity ceilings (for progress-bar normalisation) ──────────────
  static const int maxBedCapacity = 100;
  static const int maxOxygenCapacity = 500;
  static const int maxIcuCapacity = 20;
  static const int maxVentilatorCapacity = 30;

  // ── Buffer-time colour thresholds (hours) ───────────────────────────
  static const double bufferCriticalHours = 2.0;
  static const double bufferWarningHours = 6.0;

  // ── Ambulance rules ─────────────────────────────────────────────────
  static const int ambulanceEtaThresholdMinutes = 30;

  // ── Impact estimation ───────────────────────────────────────────────
  static const int estimatedLivesPerTransfer = 4;

  // ── Gemini AI ───────────────────────────────────────────────────────
  /// Replace with your own API key before running.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String geminiModel = 'gemini-2.0-flash';
}
