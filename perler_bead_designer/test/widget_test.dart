import 'package:flutter_test/flutter_test.dart';

import 'package:perler_bead_designer/main.dart';
import 'package:perler_bead_designer/services/settings_service.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    final settingsService = SettingsService();
    await settingsService.initialize();
    
    await tester.pumpWidget(PerlerBeadDesignerApp(settingsService: settingsService));

    expect(find.text('拼豆设计器'), findsOneWidget);
  });
}
