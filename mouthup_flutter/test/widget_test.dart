import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mouthup_flutter/main.dart';

void main() {
  testWidgets('MouthUp splash shows tagline', (WidgetTester tester) async {
    await tester.pumpWidget(const MouthUpApp());
    await tester.pump();

    expect(find.text('Share • Connect'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });
}
