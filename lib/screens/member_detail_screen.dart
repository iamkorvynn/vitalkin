import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../health_logic.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../widgets/widgets.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Reading> _readings = [];
  List<Medicine> _medicines = [];
  String _chartMetric = 'bp';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final readings =
        await AppDatabase.instance.getReadings(widget.member.id!);
    final medicines =
        await AppDatabase.instance.getMedicines(widget.member.id!);
    if (!mounted) return;
    setState(() {
      _readings = readings;
      _medicines = medicines;
    });
  }

  // ---------- add reading ----------
  Future<void> _showAddReading(String type) async {
    final v1Ctrl = TextEditingController();
    final v2Ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String sugarType = 'fasting';
    DateTime when = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(type == 'bp'
              ? 'Log blood pressure'
              : type == 'sugar'
                  ? 'Log blood sugar'
                  : 'Log weight'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'bp') ...[
                  TextField(
                      controller: v1Ctrl,
                      decoration: const InputDecoration(
                          labelText: 'Systolic (e.g. 120)'),
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: v2Ctrl,
                      decoration: const InputDecoration(
                          labelText: 'Diastolic (e.g. 80)'),
                      keyboardType: TextInputType.number),
                ] else if (type == 'sugar') ...[
                  TextField(
                      controller: v1Ctrl,
                      decoration: const InputDecoration(
                          labelText: 'Blood sugar (mg/dL)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                  DropdownButtonFormField<String>(
                    initialValue: sugarType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'fasting', child: Text('Fasting')),
                      DropdownMenuItem(
                          value: 'post-meal', child: Text('Post-meal')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => sugarType = v ?? 'fasting'),
                  ),
                ] else ...[
                  TextField(
                      controller: v1Ctrl,
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                ],
                TextField(
                    controller: noteCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Note (optional)')),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      '${when.day}/${when.month}/${when.year} '
                      '${when.hour.toString().padLeft(2, '0')}:'
                      '${when.minute.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: when,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date == null) return;
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(when));
                    if (time == null) return;
                    setDialogState(() {
                      when = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final v1 = double.tryParse(v1Ctrl.text.trim());
                if (v1 == null || v1 <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Enter a valid value.')));
                  return;
                }
                double? v2;
                if (type == 'bp') {
                  v2 = double.tryParse(v2Ctrl.text.trim());
                  if (v2 == null || v2 <= 0 || v2 >= v1) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Enter a valid diastolic value (below systolic).')));
                    return;
                  }
                }
                AppDatabase.instance.insertReading(Reading(
                  memberId: widget.member.id!,
                  type: type,
                  value1: v1,
                  value2: v2,
                  sugarType: type == 'sugar' ? sugarType : null,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                  timestamp: when,
                ));
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _load();
  }

  // ---------- add medicine ----------
  Future<void> _showAddMedicine() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    int timesPerDay = 1;
    List<String> times = defaultReminderTimes(1);

    Future<void> pickTime(int index, StateSetter setDialogState) async {
      final current = parseTimeOfDay(times[index]);
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      );
      if (picked != null) {
        setDialogState(() {
          times[index] = formatTimeOfDay(picked.hour, picked.minute);
        });
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Medicine name'),
                    textCapitalization: TextCapitalization.words),
                TextField(
                    controller: doseCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Dose (e.g. 500 mg, 1 tablet)')),
                DropdownButtonFormField<int>(
                  initialValue: timesPerDay,
                  decoration:
                      const InputDecoration(labelText: 'Times per day'),
                  items: [1, 2, 3, 4]
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    timesPerDay = v ?? 1;
                    times = defaultReminderTimes(timesPerDay);
                  }),
                ),
                const SizedBox(height: 8),
                ...List.generate(times.length, (i) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm),
                    title: Text('Dose ${i + 1} — ${times[i]}'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => pickTime(i, setDialogState),
                  );
                }),
                const Text(
                  'A daily reminder is scheduled on this device for '
                  'each time above.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final dose = doseCtrl.text.trim();
                if (name.isEmpty || dose.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Enter the medicine name and dose.')));
                  return;
                }
                final id = await AppDatabase.instance.insertMedicine(
                  Medicine(
                    memberId: widget.member.id!,
                    name: name,
                    dose: dose,
                    times: times,
                  ),
                );
                await NotificationService.instance.scheduleMedicineReminders(
                  Medicine(
                      id: id,
                      memberId: widget.member.id!,
                      name: name,
                      dose: dose,
                      times: times),
                );
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteMedicine(Medicine med) async {
    await NotificationService.instance.cancelMedicineReminders(med);
    await AppDatabase.instance.deleteMedicine(med.id!);
    _load();
  }

  Future<void> _deleteMember() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
            'This deletes ${widget.member.name} and all their readings '
            'and medicines. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      for (final med in _medicines) {
        await NotificationService.instance.cancelMedicineReminders(med);
      }
      await AppDatabase.instance.deleteMember(widget.member.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  // ---------- charts ----------
  Widget _buildChart() {
    final data = _readings
        .where((r) => r.type == _chartMetric)
        .toList()
        .reversed
        .take(14)
        .toList()
        .reversed
        .toList();
    if (data.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: Text('No readings for this metric yet.\nLog one to see the chart.',
            textAlign: TextAlign.center),
      ));
    }
    final spots = <FlSpot>[];
    final spots2 = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value1));
      if (_chartMetric == 'bp' && data[i].value2 != null) {
        spots2.add(FlSpot(i.toDouble(), data[i].value2!));
      }
    }
    final allValues = [
      ...spots.map((s) => s.y),
      ...spots2.map((s) => s.y),
    ];
    var minY = allValues.reduce((a, b) => a < b ? a : b);
    var maxY = allValues.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.2 + 5;
    minY -= pad;
    maxY += pad;

    List<HorizontalLine> refLines() {
      if (_chartMetric == 'bp') {
        return [
          HorizontalLine(
              y: 120, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
          HorizontalLine(
              y: 80, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
        ];
      }
      if (_chartMetric == 'sugar') {
        final fasting = data.any((r) => r.sugarType == 'fasting');
        return fasting
            ? [
                HorizontalLine(
                    y: 70, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
                HorizontalLine(
                    y: 100, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
              ]
            : [
                HorizontalLine(
                    y: 140, color: Colors.green, strokeWidth: 1, dashArray: [5, 5]),
              ];
      }
      return [];
    }

    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: Theme.of(context).colorScheme.primary,
        barWidth: 3,
        dotData: const FlDotData(show: true),
      ),
    ];
    if (spots2.isNotEmpty) {
      bars.add(LineChartBarData(
        spots: spots2,
        isCurved: true,
        color: Colors.orange,
        barWidth: 3,
        dotData: const FlDotData(show: true),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                  label: const Text('Blood pressure'),
                  selected: _chartMetric == 'bp',
                  onSelected: (_) =>
                      setState(() => _chartMetric = 'bp')),
              ChoiceChip(
                  label: const Text('Blood sugar'),
                  selected: _chartMetric == 'sugar',
                  onSelected: (_) =>
                      setState(() => _chartMetric = 'sugar')),
              ChoiceChip(
                  label: const Text('Weight'),
                  selected: _chartMetric == 'weight',
                  onSelected: (_) =>
                      setState(() => _chartMetric = 'weight')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _chartMetric == 'bp'
                ? 'Blue: systolic • Orange: diastolic • Dashed: healthy 120 / 80'
                : _chartMetric == 'sugar'
                    ? 'Dashed: healthy range (fasting 70–100, post-meal under 140)'
                    : 'Last 14 weight readings',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                extraLinesData: ExtraLinesData(horizontalLines: refLines()),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final d = data[i].timestamp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${d.day}/${d.month}',
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeFor(Reading r) {
    if (r.type == 'bp') {
      return LevelBadge.forBp(r.value1.toInt(), r.value2?.toInt() ?? 0);
    }
    if (r.type == 'sugar') {
      return LevelBadge.forSugar(r.value1,
          fasting: (r.sugarType ?? 'fasting') == 'fasting');
    }
    return const SizedBox.shrink();
  }

  String _readingTitle(Reading r) {
    switch (r.type) {
      case 'bp':
        return 'Blood pressure';
      case 'sugar':
        return 'Blood sugar';
      case 'weight':
        return 'Weight';
      default:
        return r.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'pdf') {
                await ReportService.instance.sharePdf(m);
              } else if (value == 'csv') {
                await ReportService.instance.shareCsv(m);
              } else if (value == 'delete') {
                _deleteMember();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'pdf',
                  child: Text('Share PDF report for doctor')),
              PopupMenuItem(
                  value: 'csv', child: Text('Share readings as CSV')),
              PopupMenuItem(
                  value: 'delete', child: Text('Remove member')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Readings'),
            Tab(text: 'Charts'),
            Tab(text: 'Medicines'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Readings tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                        onPressed: () => _showAddReading('bp'),
                        icon: const Icon(Icons.monitor_heart),
                        label: const Text('Blood pressure')),
                    FilledButton.tonalIcon(
                        onPressed: () => _showAddReading('sugar'),
                        icon: const Icon(Icons.bloodtype),
                        label: const Text('Blood sugar')),
                    FilledButton.tonalIcon(
                        onPressed: () => _showAddReading('weight'),
                        icon: const Icon(Icons.monitor_weight),
                        label: const Text('Weight')),
                  ],
                ),
              ),
              Expanded(
                child: _readings.isEmpty
                    ? const Center(
                        child: Text('No readings yet.\nLog the first one above.',
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: _readings.length,
                        itemBuilder: (context, i) {
                          final r = _readings[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(
                                  '${_readingTitle(r)} — ${r.displayValue}'),
                              subtitle: Text(
                                '${r.timestamp.day}/${r.timestamp.month}/${r.timestamp.year} '
                                '${r.timestamp.hour.toString().padLeft(2, '0')}:'
                                '${r.timestamp.minute.toString().padLeft(2, '0')}'
                                '${r.note != null ? '\n${r.note}' : ''}',
                              ),
                              isThreeLine: r.note != null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _badgeFor(r),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await AppDatabase.instance
                                          .deleteReading(r.id!);
                                      _load();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // Charts tab
          SingleChildScrollView(child: _buildChart()),
          // Medicines tab
          Column(
            children: [
              Expanded(
                child: _medicines.isEmpty
                    ? const Center(
                        child: Text(
                            'No medicines yet.\nAdd one to set up reminders.',
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: _medicines.length,
                        itemBuilder: (context, i) {
                          final med = _medicines[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.medication),
                              title: Text('${med.name} — ${med.dose}'),
                              subtitle: Text(
                                  'Daily at ${med.times.join(', ')}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteMedicine(med),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showAddMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add medicine'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
