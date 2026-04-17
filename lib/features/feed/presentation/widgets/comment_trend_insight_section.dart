import 'package:flutter/material.dart';

import '../../domain/entities/comment_trend_insight.dart';

/// 詳細画面の要約・タグ直下に置く、コメント傾向（センチメント＋キーワード）カード。
class CommentTrendInsightSection extends StatelessWidget {
  final AsyncSnapshot<CommentTrendUiResult> snapshot;
  final VoidCallback onRetry;

  const CommentTrendInsightSection({
    super.key,
    required this.snapshot,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'コメント傾向を分析しています…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = snapshot.data;
    if (data is CommentTrendUiSkipped) {
      return const SizedBox.shrink();
    }
    if (data is CommentTrendUiFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'コメントの傾向',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '傾向データを取得できませんでした（サーバー未対応の可能性があります）。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('再試行'),
            ),
          ),
        ],
      );
    }
    if (data is! CommentTrendUiSuccess) {
      return const SizedBox.shrink();
    }
    final insight = data.insight;

    final posColor = const Color(0xFF2E7D32);
    final neuColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);
    final negColor = theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'コメントの傾向',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '上位20件を分析',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '再分析',
                    onPressed: onRetry,
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PctTile(
                      label: '肯定的',
                      percent: insight.positivePercent,
                      color: posColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PctTile(
                      label: '中性的',
                      percent: insight.neutralPercent,
                      color: neuColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PctTile(
                      label: '批判的',
                      percent: insight.criticalPercent,
                      color: negColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SentimentBar(
                positive: insight.positivePercent,
                neutral: insight.neutralPercent,
                critical: insight.criticalPercent,
                positiveColor: posColor,
                neutralColor: neuColor,
                criticalColor: negColor,
              ),
              const SizedBox(height: 18),
              Text(
                '主な意見',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _OpinionRow(
                label: '肯定',
                text: insight.positiveOpinion,
                color: posColor,
                theme: theme,
              ),
              const SizedBox(height: 10),
              _OpinionRow(
                label: '中性',
                text: insight.neutralOpinion,
                color: neuColor,
                theme: theme,
              ),
              const SizedBox(height: 10),
              _OpinionRow(
                label: '批判',
                text: insight.criticalOpinion,
                color: negColor,
                theme: theme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TrendCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'よく出たキーワード',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (insight.keywords.isEmpty)
                Text(
                  'キーワードはありませんでした',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < insight.keywords.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? theme.colorScheme.primary.withValues(alpha: 0.14)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          insight.keywords[i],
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: i.isEven
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  final Widget child;

  const _TrendCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );
  }
}

class _PctTile extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const _PctTile({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$percent%',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final int positive;
  final int neutral;
  final int critical;
  final Color positiveColor;
  final Color neutralColor;
  final Color criticalColor;

  const _SentimentBar({
    required this.positive,
    required this.neutral,
    required this.critical,
    required this.positiveColor,
    required this.neutralColor,
    required this.criticalColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = positive + neutral + critical;
    if (total <= 0) {
      return const SizedBox(height: 6);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (positive > 0)
              Expanded(
                flex: positive,
                child: ColoredBox(color: positiveColor),
              ),
            if (neutral > 0)
              Expanded(
                flex: neutral,
                child: ColoredBox(color: neutralColor),
              ),
            if (critical > 0)
              Expanded(
                flex: critical,
                child: ColoredBox(color: criticalColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpinionRow extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final ThemeData theme;

  const _OpinionRow({
    required this.label,
    required this.text,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final body = text.isEmpty ? '（要約なし）' : text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}
