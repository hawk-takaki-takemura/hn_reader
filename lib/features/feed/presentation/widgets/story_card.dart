import 'package:flutter/material.dart';

import '../../../../core/utils/locale_utils.dart';
import '../../domain/entities/story.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  final bool isRead;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
            if (story.domain != null)
              Text(
                story.domain!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    story.displayTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isRead
                              ? Theme.of(context).colorScheme.onSurface.withValues(
                                    alpha: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? 0.52
                                        : 0.38,
                                  )
                              : null,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (story.translatedTitle != null ||
                    (story.hasEnrichment &&
                        story.enrichment!.titleJa != null &&
                        story.enrichment!.titleJa!.trim().isNotEmpty)) ...[
                  const SizedBox(width: 6),
                  _LanguageBadge(
                    languageCode: LocaleUtils.languageLabel,
                  ),
                ],
              ],
            ),
            if (story.hasEnrichment) ...[
              const SizedBox(height: 6),
              if (story.enrichment!.summaryShort != null &&
                  story.enrichment!.summaryShort!.trim().isNotEmpty)
                Text(
                  story.enrichment!.summaryShort!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (story.enrichment!.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: story.enrichment!.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.arrow_upward,
                  label: '${story.score}',
                ),
                const SizedBox(width: 12),
                _MetaChip(
                  icon: Icons.chat_bubble_outline,
                  label: '${story.descendants}',
                ),
                const Spacer(),
                Text(
                  _timeAgo(story.postedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime postedAt) {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

class _LanguageBadge extends StatelessWidget {
  final String languageCode;

  const _LanguageBadge({required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        languageCode,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}
