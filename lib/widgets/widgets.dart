import 'package:flutter/material.dart';

import '../health_logic.dart';
import '../models.dart';

/// Small coloured badge showing a reading's classification.
class LevelBadge extends StatelessWidget {
  final String label;
  final bool isGood;
  final bool isWarning;

  const LevelBadge({
    super.key,
    required this.label,
    this.isGood = false,
    this.isWarning = false,
  });

  factory LevelBadge.forBp(int systolic, int diastolic) {
    final level = classifyBloodPressure(systolic, diastolic);
    return LevelBadge(
      label: bpLevelLabel(level),
      isGood: level == BpLevel.normal,
      isWarning: level == BpLevel.elevated,
    );
  }

  factory LevelBadge.forSugar(double value, {bool fasting = true}) {
    final level = classifyBloodSugar(value, fasting: fasting);
    return LevelBadge(
      label: sugarLevelLabel(level),
      isGood: level == SugarLevel.normal,
      isWarning: level == SugarLevel.borderline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isGood
        ? Colors.green
        : isWarning
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Card summarising one family member on the home screen.
class MemberCard extends StatelessWidget {
  final Member member;
  final String? latestSummary;
  final VoidCallback onTap;

  const MemberCard({
    super.key,
    required this.member,
    this.latestSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
        ),
        title: Text(member.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${member.relation} • ${member.age} yrs'
            '${latestSummary != null ? '\n$latestSummary' : ''}'),
        isThreeLine: latestSummary != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
