// VitalKin data models: family members, health readings, medicines.
class Member {
  final int? id;
  final String name;
  final int age;
  final String relation;
  final double? heightCm;

  const Member({
    this.id,
    required this.name,
    required this.age,
    required this.relation,
    this.heightCm,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'relation': relation,
        'height_cm': heightCm,
      };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
        id: map['id'] as int?,
        name: map['name'] as String,
        age: map['age'] as int,
        relation: map['relation'] as String,
        heightCm: (map['height_cm'] as num?)?.toDouble(),
      );

  Member copyWith({int? id, String? name, int? age, String? relation, double? heightCm}) =>
      Member(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        relation: relation ?? this.relation,
        heightCm: heightCm ?? this.heightCm,
      );

  /// Body mass index, only when height is known and a weight is given.
  double? bmi(double weightKg) {
    if (heightCm == null || heightCm! <= 0) return null;
    final h = heightCm! / 100;
    return weightKg / (h * h);
  }
}

/// One logged reading. [type] is 'bp', 'sugar' or 'weight'.
/// BP: value1 = systolic, value2 = diastolic.
/// Sugar: value1 = mg/dL, [sugarType] = 'fasting' or 'post-meal'.
/// Weight: value1 = kg.
class Reading {
  final int? id;
  final int memberId;
  final String type;
  final double value1;
  final double? value2;
  final String? sugarType;
  final String? note;
  final DateTime timestamp;

  const Reading({
    this.id,
    required this.memberId,
    required this.type,
    required this.value1,
    this.value2,
    this.sugarType,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'member_id': memberId,
        'type': type,
        'value1': value1,
        'value2': value2,
        'sugar_type': sugarType,
        'note': note,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Reading.fromMap(Map<String, dynamic> map) => Reading(
        id: map['id'] as int?,
        memberId: map['member_id'] as int,
        type: map['type'] as String,
        value1: (map['value1'] as num).toDouble(),
        value2: (map['value2'] as num?)?.toDouble(),
        sugarType: map['sugar_type'] as String?,
        note: map['note'] as String?,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );

  String get displayValue {
    switch (type) {
      case 'bp':
        return '${value1.toInt()}/${value2?.toInt() ?? 0} mmHg';
      case 'sugar':
        return '${value1.toInt()} mg/dL (${sugarType ?? 'fasting'})';
      case 'weight':
        return '${value1.toStringAsFixed(1)} kg';
      default:
        return value1.toString();
    }
  }
}

class Medicine {
  final int? id;
  final int memberId;
  final String name;
  final String dose;
  /// Daily reminder times as "HH:mm" strings, e.g. ["08:00", "20:00"].
  final List<String> times;
  final String? note;

  const Medicine({
    this.id,
    required this.memberId,
    required this.name,
    required this.dose,
    required this.times,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'member_id': memberId,
        'name': name,
        'dose': dose,
        'times': times.join(','),
        'note': note,
      };

  factory Medicine.fromMap(Map<String, dynamic> map) => Medicine(
        id: map['id'] as int?,
        memberId: map['member_id'] as int,
        name: map['name'] as String,
        dose: map['dose'] as String,
        times: (map['times'] as String)
            .split(',')
            .where((t) => t.trim().isNotEmpty)
            .toList(),
        note: map['note'] as String?,
      );
}
