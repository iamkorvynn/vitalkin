import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models.dart';
import '../widgets/widgets.dart';
import 'member_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Member> _members = [];
  final Map<int, String> _summaries = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final members = await AppDatabase.instance.getMembers();
    final summaries = <int, String>{};
    for (final m in members) {
      final bp = await AppDatabase.instance.latestReading(m.id!, 'bp');
      final sugar =
          await AppDatabase.instance.latestReading(m.id!, 'sugar');
      final parts = <String>[];
      if (bp != null) parts.add('BP ${bp.displayValue}');
      if (sugar != null) parts.add('Sugar ${sugar.displayValue}');
      if (parts.isNotEmpty) summaries[m.id!] = parts.join('  •  ');
    }
    if (!mounted) return;
    setState(() {
      _members = members;
      _summaries.clear();
      _summaries.addAll(summaries);
      _loading = false;
    });
  }

  Future<void> _showAddMember() async {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    String relation = 'Parent';
    const relations = [
      'Self', 'Parent', 'Grandparent', 'Spouse', 'Sibling', 'Child', 'Other'
    ];
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add family member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: relation,
                decoration: const InputDecoration(labelText: 'Relation'),
                items: relations
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => relation = v ?? relation,
              ),
              TextField(
                controller: heightCtrl,
                decoration: const InputDecoration(
                    labelText: 'Height (cm, optional)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              final name = nameCtrl.text.trim();
              final age = int.tryParse(ageCtrl.text.trim());
              if (name.isEmpty || age == null || age <= 0 || age > 120) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Enter a name and a valid age.')));
                return;
              }
              AppDatabase.instance.insertMember(Member(
                name: name,
                age: age,
                relation: relation,
                heightCm: double.tryParse(heightCtrl.text.trim()),
              ));
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VitalKin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        const Text('No family members yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + below to add the first person whose '
                          'health you want to track.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, i) {
                          final m = _members[i];
                          return MemberCard(
                            member: m,
                            latestSummary: _summaries[m.id],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MemberDetailScreen(member: m)),
                              );
                              _load();
                            },
                          );
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'VitalKin is a personal health log, not a medical '
                        'device or diagnosis tool.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMember,
        icon: const Icon(Icons.person_add),
        label: const Text('Add member'),
      ),
    );
  }
}
