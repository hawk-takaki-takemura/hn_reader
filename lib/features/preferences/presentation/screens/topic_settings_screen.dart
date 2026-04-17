import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/topic_preferences_provider.dart';

class TopicSettingsScreen extends ConsumerWidget {
  const TopicSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefAsync = ref.watch(topicPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('興味ジャンル設定')),
      body: prefAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data:
            (state) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('あなた向けタブに反映するジャンルを選択してください。'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      TopicGenre.values.map((genre) {
                        final selected = state.selectedGenres.contains(genre);
                        return FilterChip(
                          selected: selected,
                          label: Text(topicGenreLabels[genre] ?? genre.name),
                          onSelected: (on) {
                            final next = {...state.selectedGenres};
                            if (on) {
                              next.add(genre);
                            } else {
                              next.remove(genre);
                            }
                            ref
                                .read(topicPreferencesProvider.notifier)
                                .updateGenres(next);
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  state.selectedGenres.isEmpty
                      ? '未選択の場合は一般のTOP順で表示されます。'
                      : '選択中: ${state.selectedGenres.map((g) => topicGenreLabels[g]).join(' / ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
      ),
    );
  }
}

Future<void> showTopicOnboardingDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final current = await ref.read(topicPreferencesProvider.future);
  final selected = {...current.selectedGenres};

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final temp = {...selected};
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'まずは興味ジャンルを選びましょう',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('あなた向けタブを最適化します（後から変更できます）'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        TopicGenre.values.map((genre) {
                          final isSelected = temp.contains(genre);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(topicGenreLabels[genre] ?? genre.name),
                            onSelected: (on) {
                              setModalState(() {
                                if (on) {
                                  temp.add(genre);
                                } else {
                                  temp.remove(genre);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(topicPreferencesProvider.notifier)
                              .completeLater();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('スキップ'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          await ref
                              .read(topicPreferencesProvider.notifier)
                              .saveGenres(temp);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('はじめる'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
