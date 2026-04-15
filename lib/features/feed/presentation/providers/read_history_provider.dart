import 'package:flutter_riverpod/flutter_riverpod.dart';

final readHistoryProvider =
    NotifierProvider<ReadHistoryNotifier, Set<int>>(ReadHistoryNotifier.new);

class ReadHistoryNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void markAsRead(int storyId) {
    state = {...state, storyId};
  }

  bool isRead(int storyId) => state.contains(storyId);
}
