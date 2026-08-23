import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'composer_screen.dart';

/// 话题详情：楼层列表 + 点赞 + 回复
class TopicDetailScreen extends StatefulWidget {
  final int topicId;
  const TopicDetailScreen({super.key, required this.topicId});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  TopicDetail? _detail;
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _likingBusy = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      final d = _detail;
      if (d == null) return;
      if (_scroll.position.extentAfter < 600 &&
          !_loadingMore &&
          !_loading &&
          _detail!.posts.length < _detail!.stream.length) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await context.read<AppState>().api.topic(widget.topicId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final d = _detail;
    if (d == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final loaded = d.posts.map((p) => p.id).toSet();
      final nextIds =
          d.stream.where((id) => !loaded.contains(id)).take(20).toList();
      if (nextIds.isEmpty) {
        setState(() => _loadingMore = false);
        return;
      }
      final more =
          await context.read<AppState>().api.topicPosts(widget.topicId, nextIds);
      if (!mounted) return;
      final merged = [...d.posts, ...more]
        ..sort((a, b) => a.postNumber.compareTo(b.postNumber));
      setState(() => _detail = _copyWithPosts(d, merged));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  TopicDetail _copyWithPosts(TopicDetail d, List<Post> posts) => TopicDetail(
        id: d.id,
        title: d.title,
        slug: d.slug,
        postsCount: d.postsCount,
        categoryId: d.categoryId,
        views: d.views,
        likeCount: d.likeCount,
        closed: d.closed,
        archived: d.archived,
        createdAt: d.createdAt,
        posts: posts,
        stream: d.stream,
      );

  Future<void> _toggleLike(Post post) async {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      _hint('请先登录');
      return;
    }
    if (_likingBusy) return;
    setState(() => _likingBusy = true);
    try {
      if (post.likedByMe) {
        await app.api.unlikePost(post.id);
      } else {
        await app.api.likePost(post.id);
      }
      final d = _detail;
      if (d == null || !mounted) return;
      final idx = d.posts.indexWhere((p) => p.id == post.id);
      if (idx >= 0) {
        final updated = d.posts[idx].copyWith(
          likedByMe: !post.likedByMe,
          likeCount:
              post.likeCount + (post.likedByMe ? -1 : 1),
        );
        final posts = [...d.posts];
        posts[idx] = updated;
        setState(() => _detail = _copyWithPosts(d, posts));
      }
    } catch (e) {
      _hint(e.toString());
    } finally {
      if (mounted) setState(() => _likingBusy = false);
    }
  }

  void _hint(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _reply({int? replyToPostNumber, String? hint}) async {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      _hint('请先登录');
      return;
    }
    if (_detail?.closed == true || _detail?.archived == true) {
      _hint('该话题已关闭，无法回复');
      return;
    }
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposerScreen(
          isNewTopic: false,
          topicId: widget.topicId,
          replyToPostNumber: replyToPostNumber,
          hint: hint,
        ),
      ),
    );
    if (ok == true && mounted) {
      _load();
    }
  }

  void _copyLink(int postNumber) {
    final d = _detail;
    if (d == null) return;
    final url =
        '${context.read<AppState>().baseUrl}/t/${d.slug ?? d.id}/${d.id}/${postNumber}';
    Clipboard.setData(ClipboardData(text: url));
    _hint('链接已复制');
  }

  Future<void> _openInBrowser() async {
    final d = _detail;
    if (d == null) return;
    final url =
        '${context.read<AppState>().baseUrl}/t/${d.slug ?? 'topic'}/${d.id}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          d?.title.replaceAll(RegExp(r'<[^>]*>'), '') ?? '话题',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16.5),
        ),
        actions: [
          IconButton(
            tooltip: '在浏览器中打开',
            icon: const Icon(Icons.open_in_new),
            onPressed: d == null ? null : _openInBrowser,
          ),
          PopupMenuButton<String>(
            enabled: d != null,
            onSelected: (v) {
              if (v == 'copy') _copyLink(1);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('复制话题链接')),
            ],
          ),
        ],
      ),
      floatingActionButton: d == null || d.closed || d.archived
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _reply(),
              icon: const Icon(Icons.reply),
              label: const Text('回复'),
            ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : d == null
                  ? const EmptyView(text: '内容不存在')
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 10, bottom: 96),
                      itemCount: d.posts.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Column(
                            children: [
                              _TopicHeader(detail: d),
                              const SizedBox(height: 8),
                              _PostCard(
                                post: d.posts.first,
                                detail: d,
                                onLike: () => _toggleLike(d.posts.first),
                                onReply: () => _reply(
                                    replyToPostNumber: 1,
                                    hint: '回复 #1 ${d.posts.first.username}'),
                                onCopyLink: () => _copyLink(d.posts.first.postNumber),
                                onChanged: _load,
                              ),
                            ],
                          );
                        }
                        if (i == d.posts.length) {
                          if (d.posts.length < d.stream.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loadingMore
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.2))
                                    : TextButton.icon(
                                        onPressed: _loadMore,
                                        icon: const Icon(Icons.expand_more,
                                            size: 20),
                                        label: Text(
                                            '加载更多（${d.posts.length}/${d.stream.length}）'),                                      ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                '已经到底了 · 共 ${d.postsCount} 楼',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                          );
                        }
                        final post = d.posts[i];
                        return _PostCard(
                          post: post,
                          detail: d,
                          onLike: () => _toggleLike(post),
                          onReply: () => _reply(
                              replyToPostNumber: post.postNumber,
                              hint: '回复 #${post.postNumber} ${post.username}'),
                          onCopyLink: () => _copyLink(post.postNumber),
                          onChanged: _load,
                        );
                      },
                    ),
    );
  }
}

class _TopicHeader extends StatelessWidget {
  final TopicDetail detail;
  const _TopicHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.title.replaceAll(RegExp(r'<[^>]*>'), ''),
              style: const TextStyle(
                  fontSize: 17.5, fontWeight: FontWeight.w800, height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.visibility, size: 13, color: muted),
                const SizedBox(width: 3),
                Text(compactNumber(detail.views),
                    style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline, size: 13, color: muted),
                const SizedBox(width: 3),
                Text('${detail.postsCount} 楼',
                    style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(width: 12),
                Icon(Icons.favorite_outline, size: 13, color: muted),
                const SizedBox(width: 3),
                Text(compactNumber(detail.likeCount),
                    style: TextStyle(fontSize: 12, color: muted)),
                const Spacer(),
                Text(timeAgo(detail.createdAt),
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个楼层
class _PostCard extends StatelessWidget {
  final Post post;
  final TopicDetail detail;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onCopyLink;
  final VoidCallback onChanged;

  const _PostCard({
    required this.post,
    required this.detail,
    required this.onLike,
    required this.onReply,
    required this.onCopyLink,
    required this.onChanged,
  });

  Future<void> _openAvatarLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    final body = post.hidden
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('该帖已被社区隐藏', style: TextStyle(color: muted)),
          )
        : HtmlWidget(
            post.cooked,
            onTapUrl: (url) async {
              if (url.startsWith('http')) {
                await _openAvatarLink(url);
              }
              return true;
            },
            customStylesBuilder: (element) {
              switch (element.localName) {
                case 'blockquote':
                  return {
                    'border-left': '3px solid ${cssHex(scheme.primary)}',
                    'background': cssHex(scheme.surfaceContainerHighest),
                    'padding': '8px 12px',
                    'margin': '8px 0',
                    'border-radius': '6px',
                  };
                case 'pre':
                  return {
                    'background': cssHex(scheme.surfaceContainerHighest),
                    'padding': '12px',
                    'border-radius': '8px',
                  };
                case 'code':
                  return {'font-family': 'monospace', 'font-size': '13px'};
                case 'a':
                  return {'color': cssHex(scheme.primary)};
                case 'img':
                  return {'max-width': '100%', 'border-radius': '8px'};
              }
              return null;
            },
          );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  avatarTemplate: post.avatarTemplate,
                  username: post.username,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('#${post.postNumber}',
                              style: TextStyle(fontSize: 11.5, color: muted)),
                        ],
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                    ],
                  ),
                ),
                if (post.replyToPostNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '回复 #${post.replyToPostNumber}',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: '更多',
                  onSelected: (v) {
                    if (v == 'copy') onCopyLink();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'copy', child: Text('复制楼层链接')),
                  ],
                  icon: Icon(Icons.more_horiz, size: 20, color: muted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            body,
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onLike,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor:
                        post.likedByMe ? NL.love : muted,
                  ),
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_outline,
                    size: 17,
                    color: post.likedByMe ? NL.love : muted,
                  ),
                  label: Text(
                    post.likeCount > 0 ? '${post.likeCount}' : '赞',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: post.likedByMe ? NL.love : muted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: onReply,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: Icon(Icons.reply, size: 17, color: muted),
                  label: Text('回复', style: TextStyle(fontSize: 12.5, color: muted)),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
