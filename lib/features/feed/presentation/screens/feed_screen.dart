import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../translation/presentation/providers/translation_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/read_history_provider.dart';
import '../widgets/story_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      floatingActionButton: _showScrollButton
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
      body: feedAsync.when(
        loading: () => _LoadingList(controller: _scrollController),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(feedProvider.notifier).refresh(),
        ),
        data: (stories) {
          final translatedAsync =
              ref.watch(translatedStoriesProvider(stories));
          return translatedAsync.when(
            loading: () => _LoadingList(controller: _scrollController),
            error: (e, _) => RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  final isRead = ref.watch(readHistoryProvider).contains(story.id);
                  return StoryCard(
                    story: story,
                    isRead: isRead,
                    onTap: () {
                      ref
                          .read(readHistoryProvider.notifier)
                          .markAsRead(story.id);
                      // TODO: 記事詳細へ遷移
                    },
                  );
                },
              ),
            ),
            data: (translatedStories) => RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: translatedStories.length,
                itemBuilder: (context, index) {
                  final story = translatedStories[index];
                  final isRead =
                      ref.watch(readHistoryProvider).contains(story.id);
                  return StoryCard(
                    story: story,
                    isRead: isRead,
                    onTap: () {
                      ref
                          .read(readHistoryProvider.notifier)
                          .markAsRead(story.id);
                      // TODO: 記事詳細へ遷移
                    },
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

  const _FeedTypeTab({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tab(
          label: 'トップ',
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
    final isOrangeBar = Theme.of(context).appBarTheme.backgroundColor ==
        const Color(0xFFFF6600);

    final Color selectedBorderColor =
        isOrangeBar ? Colors.white : Theme.of(context).colorScheme.primary;
    final Color selectedTextColor =
        isOrangeBar ? Colors.white : Theme.of(context).colorScheme.primary;
    final Color unselectedTextColor = isOrangeBar
        ? Colors.white.withValues(alpha: 0.6)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
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
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
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
      physics: controller != null
          ? const AlwaysScrollableScrollPhysics()
          : null,
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
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
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
        color:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
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
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}
