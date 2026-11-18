import 'package:flutter/material.dart';

/// First-run walkthrough. Explains what VitalKin does before any data
/// is entered; the app starts completely empty afterwards.
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    const pages = [
      (
        icon: Icons.family_restroom,
        title: 'Your family\'s health, in one place',
        body: 'Add the people you care for — parents, grandparents, '
            'kids, yourself — and keep their health readings together.',
      ),
      (
        icon: Icons.monitor_heart,
        title: 'Log readings in seconds',
        body: 'Blood pressure, blood sugar and weight. Each entry is '
            'dated, and VitalKin flags values outside the healthy range.',
      ),
      (
        icon: Icons.show_chart,
        title: 'See the trend, share the facts',
        body: 'Charts show how readings move over time. Export a PDF '
            'report for the doctor or a CSV to share with family.',
      ),
      (
        icon: Icons.medication,
        title: 'Never miss a dose',
        body: 'Add medicines with their daily times and VitalKin reminds '
            'you on this device. Everything is stored only on your phone.',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: pages.length,
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(page.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onDone,
                      child: const Text('Get started'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VitalKin is a personal health log, not a medical '
                    'device or diagnosis tool.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
