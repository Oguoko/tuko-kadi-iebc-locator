import 'package:flutter_test/flutter_test.dart';
import 'package:tuko_kadi_iebc_locator/app/app.dart';

void main() {
  testWidgets('App shell boots to home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TukoKadiApp());
    await tester.pumpAndSettle();

    expect(find.text('Tuko Kadi IEBC Locator'), findsNWidgets(2));
    expect(find.text('Search Offices'), findsOneWidget);
  });
}
