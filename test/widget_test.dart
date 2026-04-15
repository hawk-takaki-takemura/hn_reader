import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hn_reader/core/config/app_config.dart';
import 'package:hn_reader/features/feed/domain/entities/story.dart';
import 'package:hn_reader/features/feed/presentation/providers/feed_provider.dart';
import 'package:hn_reader/features/translation/presentation/providers/translation_provider.dart';
import 'package:hn_reader/main.dart';

/// ネットワークに依存せずフィードを即時表示する（Widget テスト用）
class FakeFeedNotifier extends FeedNotifier {
  @override
  Future<List<Story>> build() async {
    return const [
      Story(
        id: 1,
        title: 'Smoke test story',
        by: 'tester',
        score: 42,
        descendants: 7,
        time: 1700000000,
        type: 'story',
      ),
    ];
  }
}

void main() {
  testWidgets('トップ画面のスモークテスト', (WidgetTester tester) async {
    AppConfig.initialize(
      const AppConfig(
        flavor: Flavor.dev,
        appName: 'HN Reader Test',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedProvider.overrideWith(FakeFeedNotifier.new),
          translationEnabledProvider.overrideWith((ref) => false),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('HN Reader'), findsOneWidget);
    expect(find.text('Smoke test story'), findsOneWidget);
  });
}
