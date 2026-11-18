import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalkin/models.dart';
import 'package:vitalkin/screens/onboarding_screen.dart';
import 'package:vitalkin/widgets/widgets.dart';

void main() {
  testWidgets('onboarding shows the four explainer pages and finishes',
      (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(onDone: () => done = true),
      ),
    );

    expect(find.text('Your family\'s health, in one place'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(
        find.textContaining('not a medical device'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('LevelBadge shows Normal for a healthy BP reading',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LevelBadge.forBp(115, 75)),
      ),
    );
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('LevelBadge shows High for a high sugar reading',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LevelBadge.forSugar(180)),
      ),
    );
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('MemberCard shows name, relation, age and latest summary',
      (tester) async {
    const member =
        Member(id: 1, name: 'Asha', age: 62, relation: 'Parent');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberCard(
            member: member,
            latestSummary: 'BP 120/80 mmHg',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Asha'), findsOneWidget);
    expect(find.textContaining('Parent'), findsOneWidget);
    expect(find.textContaining('BP 120/80'), findsOneWidget);
  });
}
