import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../widgets/story_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedType = ref.watch(feedTypeProvider);
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HN Reader'),
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
      body: feedAsync.when(
        loading: () => const _LoadingList(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(feedProvider.notifier).refresh(),
        ),
        data: (stories) => RefreshIndicator(
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return StoryCard(
                story: story,
                onTap: () {
                  // TODO: 記事詳細へ遷移
                },
              );
            },
          ),
        ),
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
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
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
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
