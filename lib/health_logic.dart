// Pure health-logic helpers: reading classification and reminder timing.
// Kept free of Flutter/Android dependencies so they are unit-testable.

enum BpLevel { normal, elevated, high }

/// Blood pressure classification (ACC/AHA thresholds).
/// Normal: <120 and <80. Elevated: 120-129 and <80.
/// High: >=130 systolic or >=80 diastolic.
BpLevel classifyBloodPressure(int systolic, int diastolic) {
  if (systolic >= 130 || diastolic >= 80) return BpLevel.high;
  if (systolic >= 120) return BpLevel.elevated;
  return BpLevel.normal;
}

String bpLevelLabel(BpLevel level) {
  switch (level) {
    case BpLevel.normal:
      return 'Normal';
    case BpLevel.elevated:
      return 'Elevated';
    case BpLevel.high:
      return 'High';
  }
}

enum SugarLevel { normal, borderline, high }

/// Blood sugar classification (mg/dL).
/// Fasting: normal 70-99, borderline 100-125, high >=126 (or <70, low).
/// Post-meal: normal <140, borderline 140-199, high >=200.
SugarLevel classifyBloodSugar(double valueMgDl, {bool fasting = true}) {
  if (fasting) {
    if (valueMgDl < 70) return SugarLevel.high; // low — needs attention
    if (valueMgDl < 100) return SugarLevel.normal;
    if (valueMgDl < 126) return SugarLevel.borderline;
    return SugarLevel.high;
  }
  if (valueMgDl < 140) return SugarLevel.normal;
  if (valueMgDl < 200) return SugarLevel.borderline;
  return SugarLevel.high;
}

String sugarLevelLabel(SugarLevel level) {
  switch (level) {
    case SugarLevel.normal:
      return 'Normal';
    case SugarLevel.borderline:
      return 'Borderline';
    case SugarLevel.high:
      return 'High';
  }
}

/// Suggested default reminder slots for a given number of doses per day.
/// Spreads doses across waking hours starting at 08:00.
List<String> defaultReminderTimes(int timesPerDay) {
  const slots = ['08:00', '13:00', '18:00', '21:00'];
  if (timesPerDay <= 0) return [];
  if (timesPerDay == 1) return ['08:00'];
  if (timesPerDay == 2) return ['08:00', '20:00'];
  if (timesPerDay == 3) return ['08:00', '14:00', '20:00'];
  return slots.sublist(0, timesPerDay.clamp(1, 4));
}

/// The next DateTime at which a daily "HH:mm" reminder should fire,
/// relative to [now]. If today's time has passed, returns tomorrow.
DateTime nextOccurrence(String hhmm, DateTime now) {
  final parts = hhmm.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

/// Parses a "HH:mm" string into (hour, minute). Throws [FormatException]
/// on malformed input.
({int hour, int minute}) parseTimeOfDay(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) throw const FormatException('Expected HH:mm');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    throw const FormatException('Hour/minute out of range');
  }
  return (hour: hour, minute: minute);
}

/// Formats hour/minute as a zero-padded "HH:mm" string.
String formatTimeOfDay(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
