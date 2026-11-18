import 'package:flutter_test/flutter_test.dart';
import 'package:vitalkin/health_logic.dart';

void main() {
  group('classifyBloodPressure', () {
    test('normal below 120/80', () {
      expect(classifyBloodPressure(110, 70), BpLevel.normal);
      expect(classifyBloodPressure(119, 79), BpLevel.normal);
    });

    test('elevated is 120-129 with diastolic below 80', () {
      expect(classifyBloodPressure(120, 75), BpLevel.elevated);
      expect(classifyBloodPressure(129, 79), BpLevel.elevated);
    });

    test('high at 130 systolic or 80 diastolic', () {
      expect(classifyBloodPressure(130, 75), BpLevel.high);
      expect(classifyBloodPressure(118, 80), BpLevel.high);
      expect(classifyBloodPressure(145, 95), BpLevel.high);
    });

    test('labels read Normal / Elevated / High', () {
      expect(bpLevelLabel(BpLevel.normal), 'Normal');
      expect(bpLevelLabel(BpLevel.elevated), 'Elevated');
      expect(bpLevelLabel(BpLevel.high), 'High');
    });
  });

  group('classifyBloodSugar', () {
    test('fasting normal 70-99', () {
      expect(classifyBloodSugar(85), SugarLevel.normal);
      expect(classifyBloodSugar(99), SugarLevel.normal);
    });

    test('fasting borderline 100-125, high at 126+', () {
      expect(classifyBloodSugar(110), SugarLevel.borderline);
      expect(classifyBloodSugar(126), SugarLevel.high);
      expect(classifyBloodSugar(180), SugarLevel.high);
    });

    test('post-meal normal under 140, high at 200+', () {
      expect(classifyBloodSugar(130, fasting: false), SugarLevel.normal);
      expect(classifyBloodSugar(160, fasting: false), SugarLevel.borderline);
      expect(classifyBloodSugar(210, fasting: false), SugarLevel.high);
    });

    test('labels read Normal / Borderline / High', () {
      expect(sugarLevelLabel(SugarLevel.normal), 'Normal');
      expect(sugarLevelLabel(SugarLevel.borderline), 'Borderline');
      expect(sugarLevelLabel(SugarLevel.high), 'High');
    });
  });

  group('reminder scheduling helper', () {
    test('default times spread across the day', () {
      expect(defaultReminderTimes(1), ['08:00']);
      expect(defaultReminderTimes(2), ['08:00', '20:00']);
      expect(defaultReminderTimes(3), ['08:00', '14:00', '20:00']);
      expect(defaultReminderTimes(4).length, 4);
      expect(defaultReminderTimes(0), isEmpty);
    });

    test('nextOccurrence is today when the time is ahead', () {
      final now = DateTime(2026, 11, 18, 7, 0);
      expect(nextOccurrence('08:00', now), DateTime(2026, 11, 18, 8, 0));
    });

    test('nextOccurrence rolls to tomorrow when the time has passed', () {
      final now = DateTime(2026, 11, 18, 21, 30);
      expect(nextOccurrence('08:00', now), DateTime(2026, 11, 19, 8, 0));
    });

    test('parse/format round-trips HH:mm', () {
      expect(formatTimeOfDay(8, 5), '08:05');
      final parsed = parseTimeOfDay('20:30');
      expect((parsed.hour, parsed.minute), (20, 30));
      expect(() => parseTimeOfDay('25:00'), throwsFormatException);
      expect(() => parseTimeOfDay('nope'), throwsFormatException);
    });
  });
}
