import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TopicGenre { ai, startup, webDev, mobile, security, science }

class TopicPreferencesState {
  const TopicPreferencesState({
    required this.hasCompletedOnboarding,
    required this.selectedGenres,
  });

  final bool hasCompletedOnboarding;
  final Set<TopicGenre> selectedGenres;

  TopicPreferencesState copyWith({
    bool? hasCompletedOnboarding,
    Set<TopicGenre>? selectedGenres,
  }) {
    return TopicPreferencesState(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      selectedGenres: selectedGenres ?? this.selectedGenres,
    );
  }
}

final topicPreferencesProvider =
    AsyncNotifierProvider<TopicPreferencesNotifier, TopicPreferencesState>(
      TopicPreferencesNotifier.new,
    );

class TopicPreferencesNotifier extends AsyncNotifier<TopicPreferencesState> {
  static const _keyCompleted = 'topic_onboarding_completed';
  static const _keyGenres = 'topic_selected_genres';

  @override
  Future<TopicPreferencesState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_keyCompleted) ?? false;
    final names = prefs.getStringList(_keyGenres) ?? const <String>[];
    return TopicPreferencesState(
      hasCompletedOnboarding: completed,
      selectedGenres: names.map(_genreFromName).whereType<TopicGenre>().toSet(),
    );
  }

  Future<void> saveGenres(
    Set<TopicGenre> genres, {
    bool completed = true,
  }) async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyGenres, genres.map((g) => g.name).toList());
    await prefs.setBool(_keyCompleted, completed);
    state = AsyncData(
      current.copyWith(
        hasCompletedOnboarding: completed,
        selectedGenres: genres,
      ),
    );
  }

  Future<void> completeLater() async {
    final current = await future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompleted, true);
    state = AsyncData(current.copyWith(hasCompletedOnboarding: true));
  }

  Future<void> updateGenres(Set<TopicGenre> genres) async {
    await saveGenres(genres, completed: true);
  }

  TopicGenre? _genreFromName(String name) {
    for (final genre in TopicGenre.values) {
      if (genre.name == name) return genre;
    }
    return null;
  }
}

const Map<TopicGenre, String> topicGenreLabels = {
  TopicGenre.ai: 'AI',
  TopicGenre.startup: 'スタートアップ',
  TopicGenre.webDev: 'Web開発',
  TopicGenre.mobile: 'モバイル',
  TopicGenre.security: 'セキュリティ',
  TopicGenre.science: '科学',
};

const Map<TopicGenre, List<String>> topicGenreKeywords = {
  TopicGenre.ai: [
    'ai',
    'llm',
    'gpt',
    'openai',
    'machine learning',
    'ml',
    'neural',
    'deep learning',
    '人工知能',
    '生成ai',
    '言語モデル',
    '機械学習',
  ],
  TopicGenre.startup: [
    'startup',
    'funding',
    'vc',
    'founder',
    'saas',
    'スタートアップ',
    '資金調達',
    '起業',
    'ベンチャー',
  ],
  TopicGenre.webDev: [
    'javascript',
    'typescript',
    'react',
    'node',
    'web',
    'frontend',
    'backend',
    'フロント',
    'バックエンド',
    'ウェブ',
  ],
  TopicGenre.mobile: [
    'flutter',
    'android',
    'ios',
    'swift',
    'kotlin',
    'モバイル',
    'アプリ',
    'iphone',
  ],
  TopicGenre.security: [
    'security',
    'vulnerability',
    'cve',
    'auth',
    'encryption',
    'セキュリティ',
    '脆弱性',
    '暗号',
    '認証',
  ],
  TopicGenre.science: [
    'science',
    'research',
    'biology',
    'physics',
    'space',
    '科学',
    '研究',
    '宇宙',
    '物理',
    '生物学',
  ],
};
