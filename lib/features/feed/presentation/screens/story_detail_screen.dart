import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/story.dart';

class StoryDetailArgs {
  final Story story;

  const StoryDetailArgs({required this.story});
}

enum _DetailLanguage { ja, original }

/// 本文タブの WebView で読み込む URL（サイト原文 vs Google 翻訳ラッパー）。
enum _ArticleWebMode { originalSite, googleTranslate }

class StoryDetailScreen extends StatefulWidget {
  final StoryDetailArgs args;

  const StoryDetailScreen({super.key, required this.args});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _overviewScrollController;
  final GlobalKey _commentsSectionKey = GlobalKey();
  _DetailLanguage _language = _DetailLanguage.ja;
  _ArticleWebMode _articleWebMode = _ArticleWebMode.googleTranslate;
  Future<List<_TranslatedComment>>? _commentsFuture;
  WebViewController? _webViewController;

  Story get story => widget.args.story;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _overviewScrollController = ScrollController();
    _commentsFuture = _fetchTranslatedComments();
    _setupWebViewController();
  }

  @override
  void dispose() {
    _overviewScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasTranslatedTitle {
    final translated = story.translatedTitle?.trim();
    return translated != null &&
        translated.isNotEmpty &&
        translated != story.title.trim();
  }

  bool get _hasSummaryShort =>
      story.hasEnrichment &&
      story.enrichment!.summaryShort != null &&
      story.enrichment!.summaryShort!.trim().isNotEmpty;

  bool get _hasSummaryPoints =>
      story.hasEnrichment && story.enrichment!.summaryPoints.isNotEmpty;

  FirebaseFunctions _functions() {
    return FirebaseFunctions.instanceFor(
      app: Firebase.app(AppConfig.instance.flavor.name),
      region: 'asia-northeast1',
    );
  }

  Future<void> _launchStoryUrl(BuildContext context) async {
    final rawUrl = story.url?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      _showSnackBar(context, 'この記事はURLがありません');
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      _showSnackBar(context, 'URL形式が不正です');
      return;
    }

    try {
      var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!opened) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!context.mounted) return;
      if (!opened) {
        _showSnackBar(context, '記事を開けませんでした');
      }
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(context, '記事を開けませんでした');
    }
  }

  Future<List<_TranslatedComment>> _fetchTranslatedComments() async {
    try {
      final callable = _functions().httpsCallable(
        'translateHnComments',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 40)),
      );
      final response = await callable.call<Map<String, dynamic>>({
        'storyId': story.id,
        'lang': 'ja',
        'limit': 20,
      });
      final data = response.data;
      final commentsRaw = data['comments'];
      if (commentsRaw is! List) {
        throw StateError('translateHnComments: invalid response format');
      }
      final translated = commentsRaw
          .whereType<Map>()
          .map((raw) {
            final commentId = raw['commentId'];
            final originalText = raw['originalText'];
            final translatedText = raw['translatedText'];
            if (commentId is! int ||
                originalText is! String ||
                translatedText is! String) {
              return null;
            }
            if (translatedText.trim().isEmpty) return null;
            return _TranslatedComment(
              commentId: commentId,
              originalText: originalText,
              translatedText: translatedText,
              showOriginal: false,
            );
          })
          .whereType<_TranslatedComment>()
          .toList();
      if (translated.isNotEmpty) {
        return translated;
      }
    } catch (_) {
      // fallback below
    }
    return _fetchCommentsFallback();
  }

  Future<List<_TranslatedComment>> _fetchCommentsFallback() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.hnBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );
    final storyRes = await dio.get('${ApiConstants.itemEndpoint}/${story.id}.json');
    final storyJson = storyRes.data;
    if (storyJson is! Map) return const [];
    final kidsRaw = storyJson['kids'];
    if (kidsRaw is! List) return const [];

    final commentIds = await _collectCommentIdsBreadthFirst(
      dio: dio,
      rootIds: _toIntList(kidsRaw),
      limit: 20,
    );
    final comments = <_TranslatedComment>[];
    for (final id in commentIds) {
      try {
        final res = await dio.get('${ApiConstants.itemEndpoint}/$id.json');
        final json = res.data;
        if (json is! Map) continue;
        if (json['deleted'] == true || json['dead'] == true) continue;
        final text = _stripHtml((json['text'] as String?) ?? '').trim();
        if (text.isEmpty) continue;
        comments.add(
          _TranslatedComment(
            commentId: id,
            originalText: text,
            translatedText: text,
            showOriginal: false,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return comments;
  }

  String _stripHtml(String input) {
    final noBlocks = input
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<noscript[\s\S]*?<\/noscript>', caseSensitive: false), ' ');
    final removedTags = noBlocks.replaceAll(RegExp(r'<[^>]+>'), ' ');
    final decoded = _decodeHtmlEntities(removedTags);
    return decoded.replaceAll(RegExp(r'\s+'), ' ');
  }

  List<int> _toIntList(List<dynamic> raw) {
    final out = <int>[];
    for (final v in raw) {
      if (v is int) {
        out.add(v);
      } else if (v is num) {
        out.add(v.toInt());
      } else {
        final parsed = int.tryParse(v.toString());
        if (parsed != null) out.add(parsed);
      }
    }
    return out;
  }

  Future<List<int>> _collectCommentIdsBreadthFirst({
    required Dio dio,
    required List<int> rootIds,
    required int limit,
  }) async {
    final queue = List<int>.from(rootIds);
    final visited = <int>{};
    final collected = <int>[];
    while (queue.isNotEmpty && collected.length < limit) {
      final id = queue.removeAt(0);
      if (visited.contains(id)) continue;
      visited.add(id);
      try {
        final res = await dio.get('${ApiConstants.itemEndpoint}/$id.json');
        final json = res.data;
        if (json is! Map) continue;
        if (json['deleted'] == true || json['dead'] == true) continue;
        if (json['type'] == 'comment') {
          collected.add(id);
        }
        final kids = json['kids'];
        if (kids is List) {
          for (final kid in _toIntList(kids)) {
            if (!visited.contains(kid)) queue.add(kid);
          }
        }
      } catch (_) {
        continue;
      }
    }
    return collected;
  }

  String _decodeHtmlEntities(String input) {
    var out = input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '', radix: 16);
      if (code == null) return m.group(0) ?? '';
      return String.fromCharCode(code);
    });
    out = out.replaceAllMapped(RegExp(r'&#([0-9]+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      if (code == null) return m.group(0) ?? '';
      return String.fromCharCode(code);
    });
    return out;
  }

  String get _titleForSelectedLanguage {
    if (_language == _DetailLanguage.original) {
      return story.title;
    }
    return story.displayTitle;
  }

  Uri? get _originalArticleUri {
    final rawUrl = story.url?.trim();
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null) return null;
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return null;
    return uri;
  }

  Uri? get _translatedArticleUri {
    final original = _originalArticleUri;
    if (original == null) return null;
    return Uri.https(
      'translate.google.com',
      '/translate',
      {
        'hl': 'ja',
        'sl': 'auto',
        'tl': 'ja',
        'u': original.toString(),
      },
    );
  }

  void _setupWebViewController() {
    if (_originalArticleUri == null) {
      _webViewController = null;
      return;
    }
    final initial = _articleWebUriForMode(_articleWebMode) ?? _originalArticleUri!;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(initial);
    _webViewController = controller;
  }

  Uri? _articleWebUriForMode(_ArticleWebMode mode) {
    return mode == _ArticleWebMode.originalSite
        ? _originalArticleUri
        : _translatedArticleUri;
  }

  Future<void> _applyArticleWebMode(_ArticleWebMode mode) async {
    final controller = _webViewController;
    if (controller == null) return;
    final uri = _articleWebUriForMode(mode);
    if (uri == null) return;
    await controller.loadRequest(uri);
  }

  Future<void> _copyStoryUrl() async {
    final url = _originalArticleUri?.toString();
    if (url == null) {
      _showSnackBar(context, 'URLがないため共有できません');
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _showSnackBar(context, 'URLをコピーしました');
  }

  Future<void> _scrollToCommentsSection() async {
    final context = _commentsSectionKey.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Widget _buildLanguageToggle() {
    return SegmentedButton<_DetailLanguage>(
      segments: const [
        ButtonSegment<_DetailLanguage>(
          value: _DetailLanguage.ja,
          label: Text('日本語'),
          icon: Icon(Icons.translate, size: 16),
        ),
        ButtonSegment<_DetailLanguage>(
          value: _DetailLanguage.original,
          label: Text('原文'),
          icon: Icon(Icons.language, size: 16),
        ),
      ],
      selected: {_language},
      onSelectionChanged: (selection) {
        setState(() {
          _language = selection.first;
        });
      },
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final showOriginalSubTitle =
        _language == _DetailLanguage.ja && _hasTranslatedTitle;

    return SingleChildScrollView(
      controller: _overviewScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguageToggle(),
          const SizedBox(height: 14),
          if (story.domain != null)
            Text(
              story.domain!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _titleForSelectedLanguage,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          if (showOriginalSubTitle) ...[
            const SizedBox(height: 10),
            Text(
              story.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.arrow_upward, label: '${story.score}'),
              _MetaChip(icon: Icons.chat_bubble_outline, label: '${story.descendants}'),
              _MetaChip(icon: Icons.person_outline, label: story.by),
            ],
          ),
          const SizedBox(height: 20),
          if (_language == _DetailLanguage.original) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '要約は日本語向けです。「原文」では英語タイトルを表示します。',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_hasSummaryShort || _hasSummaryPoints) ...[
            Text(
              '要約',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (_hasSummaryShort)
              Text(
                story.enrichment!.summaryShort!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
            if (_hasSummaryPoints) ...[
              const SizedBox(height: 12),
              ...story.enrichment!.summaryPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('・'),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _scrollToCommentsSection,
                icon: const Icon(Icons.forum_outlined, size: 18),
                label: const Text('コメントを読む'),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (story.hasEnrichment && story.enrichment!.tags.isNotEmpty) ...[
            Text(
              'タグ',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: story.enrichment!.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 24),
          Text(
            key: _commentsSectionKey,
            'コメント',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildCommentsSection(theme),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return FutureBuilder<List<_TranslatedComment>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('コメント翻訳の取得に失敗しました'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _commentsFuture = _fetchTranslatedComments();
                      });
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        }

        final comments = snapshot.data ?? const <_TranslatedComment>[];
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('翻訳コメントはまだありません'),
            ),
          );
        }

        return Column(
          children: [
            for (final item in comments) ...[
              Builder(
                builder: (_) {
            final text = _language == _DetailLanguage.ja
                ? item.translatedText
                : item.originalText;
            final subText = _language == _DetailLanguage.ja
                ? item.originalText
                : item.translatedText;
            final sameBody =
                item.translatedText.trim() == item.originalText.trim();
            final showOriginalToggle =
                _language == _DetailLanguage.ja && !sameBody;
            return _TranslatedCommentCard(
              item: item,
              primaryText: text,
              secondaryText: subText,
              secondaryLabel: _language == _DetailLanguage.ja ? '原文' : '翻訳',
              showSecondary: _language == _DetailLanguage.original && !sameBody,
              showOriginalToggle: showOriginalToggle,
              showOriginal: item.showOriginal,
              onToggleOriginal: showOriginalToggle
                  ? () {
                      setState(() {
                        item.showOriginal = !item.showOriginal;
                      });
                    }
                  : null,
              fallbackCaption: sameBody && _language == _DetailLanguage.ja
                  ? 'サーバー翻訳未取得（App Check 等）。原文表示中'
                  : null,
            );
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildArticleTab(ThemeData theme) {
    if (_webViewController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('本文URLが見つからないため表示できません'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _launchStoryUrl(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('元記事を開く'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _articleWebMode == _ArticleWebMode.googleTranslate
                    ? 'Google 翻訳経由で表示しています。サイトによっては表示が崩れることがあります。'
                    : '記事サイトの原文です。',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_ArticleWebMode>(
                segments: const [
                  ButtonSegment<_ArticleWebMode>(
                    value: _ArticleWebMode.googleTranslate,
                    label: Text('翻訳'),
                    icon: Icon(Icons.translate, size: 18),
                  ),
                  ButtonSegment<_ArticleWebMode>(
                    value: _ArticleWebMode.originalSite,
                    label: Text('原文'),
                    icon: Icon(Icons.language, size: 18),
                  ),
                ],
                selected: {_articleWebMode},
                onSelectionChanged: (selection) async {
                  final next = selection.first;
                  if (next == _articleWebMode) return;
                  final previous = _articleWebMode;
                  setState(() => _articleWebMode = next);
                  try {
                    await _applyArticleWebMode(next);
                  } catch (_) {
                    if (!mounted) return;
                    setState(() => _articleWebMode = previous);
                    try {
                      await _applyArticleWebMode(previous);
                    } catch (_) {}
                    if (!mounted) return;
                    _showSnackBar(context, 'ページの読み込みに失敗しました');
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: WebViewWidget(controller: _webViewController!),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('記事詳細'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '要約＋コメント'),
            Tab(text: '本文'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabKeepAlive(child: _buildOverviewTab(theme)),
          _TabKeepAlive(child: _buildArticleTab(theme)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showSnackBar(context, '保存機能は次のリリースで追加予定です');
                },
                icon: const Icon(Icons.bookmark_border),
                label: const Text('保存'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyStoryUrl,
                icon: const Icon(Icons.share_outlined),
                label: const Text('共有'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TabBarView（PageView）が非表示タブを破棄しないよう保持し、スクロール位置や WebView の状態を維持する。
class _TabKeepAlive extends StatefulWidget {
  final Widget child;

  const _TabKeepAlive({required this.child});

  @override
  State<_TabKeepAlive> createState() => _TabKeepAliveState();
}

class _TabKeepAliveState extends State<_TabKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _TranslatedComment {
  final int commentId;
  final String originalText;
  final String translatedText;
  bool showOriginal;

  _TranslatedComment({
    required this.commentId,
    required this.originalText,
    required this.translatedText,
    this.showOriginal = false,
  });
}

class _TranslatedCommentCard extends StatelessWidget {
  final _TranslatedComment item;
  final String primaryText;
  final String secondaryText;
  final String secondaryLabel;
  final bool showSecondary;
  final bool showOriginalToggle;
  final bool showOriginal;
  final VoidCallback? onToggleOriginal;
  final String? fallbackCaption;

  const _TranslatedCommentCard({
    required this.item,
    required this.primaryText,
    required this.secondaryText,
    required this.secondaryLabel,
    this.showSecondary = true,
    this.showOriginalToggle = false,
    this.showOriginal = false,
    this.onToggleOriginal,
    this.fallbackCaption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${item.commentId}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            primaryText,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (fallbackCaption != null) ...[
            const SizedBox(height: 8),
            Text(
              fallbackCaption!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
          if (showSecondary) ...[
            const SizedBox(height: 10),
            Text(
              secondaryLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              secondaryText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
          if (showOriginalToggle) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onToggleOriginal,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(showOriginal ? '原文を隠す▴' : '原文を見る▾'),
            ),
            if (showOriginal) ...[
              const SizedBox(height: 6),
              Text(
                '原文',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.originalText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.45,
                ),
              ),
            ],
          ],
        ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
