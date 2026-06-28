import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components/text_field.dart';

void main() {
  testWidgets('MyTextField shows provided hint text', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyTextField(
            controller: controller,
            hintText: 'EMAIL',
            obscureText: false,
          ),
        ),
      ),
    );

    expect(find.text('EMAIL'), findsOneWidget);
  });
}
