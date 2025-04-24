import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snapsign/main.dart'; // ชื่อโปรเจกต์ของคุณ

void main() {
  testWidgets('SnapSign app loads successfully', (WidgetTester tester) async {
    // สร้างแอปขึ้นมาทดสอบ
    await tester.pumpWidget(SnapSignApp());

    // ตรวจสอบว่าเจอคำว่า SNAP SIGN (จาก WelcomeScreen)
    expect(find.text('SNAP SIGN'), findsOneWidget);
    expect(find.text("Let's Start"), findsOneWidget);
  });
}
