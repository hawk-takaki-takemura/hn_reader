import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hn_reader/core/config/app_config.dart';
import 'package:hn_reader/main.dart';

void main() {
  testWidgets('トップ画面のスモークテスト', (WidgetTester tester) async {
    AppConfig.initialize(
      const AppConfig(
        flavor: Flavor.dev,
        appName: 'HN Reader Test',
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    expect(find.text('HN Reader 🚀'), findsOneWidget);
  });
}
