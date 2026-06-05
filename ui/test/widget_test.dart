import 'package:flutter_test/flutter_test.dart';

import 'package:specmoa_zip_ui/main.dart';

void main() {
  testWidgets('SpecMoa app renders root shell', (WidgetTester tester) async {
    await tester.pumpWidget(SpecMoaApp());

    expect(find.byType(SpecMoaApp), findsOneWidget);
  });
}
