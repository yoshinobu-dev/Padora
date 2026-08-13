import 'package:flutter_test/flutter_test.dart';
import 'package:padora_client/app_settings.dart';
import 'package:padora_client/main.dart';

void main() {
  testWidgets('Padora app loads', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(PadoraApp(settings: settings));
    expect(find.text('Padora'), findsOneWidget);
  });
}
