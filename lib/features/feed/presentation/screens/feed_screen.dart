import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../preferences/presentation/providers/topic_preferences_provider.dart';
import '../../../preferences/presentation/screens/topic_settings_screen.dart';
import '../../../ads/presentation/widgets/banner_ad_widget.dart';
import '../../../ads/presentation/widgets/native_ad_widget.dart';
import '../../../translation/presentation/providers/translation_provider.dart';
import '../../domain/entities/story.dart';
import '../providers/feed_provider.dart';
import '../providers/read_history_provider.dart';
import 'story_detail_screen.dart';
import '../widgets/story_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  bool _showScrollButton = false;
  bool _didCheckOnboarding = false;

  void _openStoryDetail(Story story) {
    ref.read(readHistoryProvider.notifier).markAsRead(story.id);
    context.push('/story', extra: StoryDetailArgs(story: story));
  }

  int _safeInterval(int interval) {
    // Remote Configの設定ミス対策（0以下はデフォルト値へフォールバック）
    return interval > 0 ? interval : 10;
  }

  /// ストーリーリストにネイティブ広告を差し込んだ仮想インデックスを計算する
  /// interval=10 のとき: 0-9→記事、10→広告、11-20→記事、21→広告...
  int _itemCount(int storyCount, int interval) {
    final safeInterval = _safeInterval(interval);
    final adCount = storyCount ~/ safeInterval;
    return storyCount + adCount;
  }

  Widget _itemBuilder(
    BuildContext context,
    int index,
    List<Story> stories,
    int interval,
  ) {
    final safeInterval = _safeInterval(interval);
    // 広告を挿入する仮想インデックス: interval+1 ごとに1つ広告
    final cycle = safeInterval + 1;
    if ((index + 1) % cycle == 0) {
      // スクロールで再利用されると広告ロード完了が dispose 後に届くため、行ごとに Key を分ける
      return NativeAdWidget(key: ValueKey('native_ad_$index'));
    }
    // 広告分のオフセットを引いた実際の記事インデックス
    final adsBefore = (index + 1) ~/ cycle;
    final storyIndex = index - adsBefore;
    if (storyIndex >= stories.length) return const SizedBox.shrink();

    final story = stories[storyIndex];
    final isRead = ref.watch(readHistoryProvider).contains(story.id);
    return StoryCard(
      story: story,
      isRead: isRead,
      onTap: () => _openStoryDetail(story),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTopicOnboarding();
    });
  }

  Future<void> _maybeShowTopicOnboarding() async {
    if (_didCheckOnboarding || !mounted) return;
    _didCheckOnboarding = true;
    final prefs = await ref.read(topicPreferencesProvider.future);
    if (!mounted || prefs.hasCompletedOnboarding) return;
    await showTopicOnboardingDialog(context, ref);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final max = position.maxScrollExtent;
    if (max <= 0) {
      if (_showScrollButton) setState(() => _showScrollButton = false);
      return;
    }
    // 長いリストは 200px、短いリストは中間付近までスクロールで表示（max<200 だと従来条件では永遠に出ない）
    final threshold = math.min(200.0, max * 0.5);
    final show = position.pixels > threshold;
    if (show != _showScrollButton) {
      setState(() => _showScrollButton = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedType = ref.watch(feedTypeProvider);
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yomi'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings/topics'),
            icon: const Icon(Icons.tune),
            tooltip: '興味ジャンル設定',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _FeedTypeTab(
            selected: feedType,
            onChanged: (type) {
              ref.read(feedTypeProvider.notifier).state = type;
            },
          ),
        ),
      ),
      floatingActionButton:
          _showScrollButton
              ? FloatingActionButton.small(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              )
              : null,
      bottomNavigationBar: const SafeArea(top: false, child: BannerAdWidget()),
      body: feedAsync.when(
        loading: () => _LoadingList(controller: _scrollController),
        error:
            (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.read(feedProvider.notifier).refresh(),
            ),
        data: (stories) {
          final translatedAsync = ref.watch(translatedStoriesProvider(stories));
          return translatedAsync.when(
            loading: () => _LoadingList(controller: _scrollController),
            error:
                (e, _) => RefreshIndicator(
                  onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: () {
                      final interval = ref.watch(nativeAdIntervalProvider);
                      final adsEnabled = ref.watch(adsEnabledProvider);
                      return adsEnabled
                          ? _itemCount(stories.length, interval)
                          : stories.length;
                    }(),
                    itemBuilder: (context, index) {
                      final interval = ref.watch(nativeAdIntervalProvider);
                      final adsEnabled = ref.watch(adsEnabledProvider);
                      if (!adsEnabled) {
                        final story = stories[index];
                        final isRead = ref
                            .watch(readHistoryProvider)
                            .contains(story.id);
                        return StoryCard(
                          story: story,
                          isRead: isRead,
                          onTap: () => _openStoryDetail(story),
                        );
                      }
                      return _itemBuilder(context, index, stories, interval);
                    },
                  ),
                ),
            data:
                (translatedStories) => RefreshIndicator(
                  onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: () {
                      final interval = ref.watch(nativeAdIntervalProvider);
                      final adsEnabled = ref.watch(adsEnabledProvider);
                      return adsEnabled
                          ? _itemCount(translatedStories.length, interval)
                          : translatedStories.length;
                    }(),
                    itemBuilder: (context, index) {
                      final interval = ref.watch(nativeAdIntervalProvider);
                      final adsEnabled = ref.watch(adsEnabledProvider);
                      if (!adsEnabled) {
                        final story = translatedStories[index];
                        final isRead = ref
                            .watch(readHistoryProvider)
                            .contains(story.id);
                        return StoryCard(
                          story: story,
                          isRead: isRead,
                          onTap: () => _openStoryDetail(story),
                        );
                      }
                      return _itemBuilder(
                        context,
                        index,
                        translatedStories,
                        interval,
                      );
                    },
                  ),
                ),
          );
        },
      ),
    );
  }
}

// タブ切り替え
class _FeedTypeTab extends StatelessWidget {
  final FeedType selected;
  final ValueChanged<FeedType> onChanged;

  const _FeedTypeTab({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
          label: 'あなた向け',
          isSelected: selected == FeedType.top,
          onTap: () => onChanged(FeedType.top),
        ),
        _Tab(
          label: '新着',
          isSelected: selected == FeedType.new_,
          onTap: () => onChanged(FeedType.new_),
        ),
        _Tab(
          label: '注目',
          isSelected: selected == FeedType.best,
          onTap: () => onChanged(FeedType.best),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOrangeBar =
        Theme.of(context).appBarTheme.backgroundColor ==
        const Color(0xFFFF6600);

    final Color selectedBorderColor =
        isOrangeBar ? Colors.white : Theme.of(context).colorScheme.primary;
    final Color selectedTextColor =
        isOrangeBar ? Colors.white : Theme.of(context).colorScheme.primary;
    final Color unselectedTextColor =
        isOrangeBar
            ? Colors.white.withValues(alpha: 0.6)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? selectedBorderColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ローディング（スケルトン）
class _LoadingList extends StatelessWidget {
  const _LoadingList({this.controller});

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics:
          controller != null ? const AlwaysScrollableScrollPhysics() : null,
      itemCount: 10,
      itemBuilder: (context, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 80, height: 10),
          const SizedBox(height: 6),
          _SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          _SkeletonBox(width: 200, height: 14),
          const SizedBox(height: 8),
          _SkeletonBox(width: 120, height: 10),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// エラー表示
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('読み込みに失敗しました'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ),
    );
  }
}
