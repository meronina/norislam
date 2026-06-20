import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:religious_qa_app/main.dart'; // أو اسم مشروعك

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // إذا كان main.dart يعرّف MyApp
    await tester.pumpWidget(const MyApp());

    // تحقق من وجود MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
