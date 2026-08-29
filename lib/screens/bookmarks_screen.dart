import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'topic_detail_screen.dart';

/// 我的收藏列表
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkItem>? _items;
  String? _error;
  bool _loading = true;

  Future<void> _load() async {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await app.api.bookmarks(app.user!.username);
      if (!mounted) return;
      setState(() {
        _items = list;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: !app.isLoggedIn
          ? const EmptyView(text: '登录后可查看收藏', icon: Icons.bookmark_border)
          : _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items == null || _items!.isEmpty
                      ? const EmptyView(text: '暂无收藏', icon: Icons.bookmark_border)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _items!.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, i) {
                              final b = _items![i];
                              return ListTile(
                                leading: Icon(Icons.bookmark,
                                    color: scheme.secondary),
                                title: Text(
                                  b.title.replaceAll(RegExp(r'<[^>]*>'), ''),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: b.excerpt.isNotEmpty
                                    ? Text(
                                        b.excerpt,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12.5),
                                      )
                                    : null,
                                trailing: Text(
                                  timeAgo(b.createdAt),
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant),
                                ),
                                onTap: b.topicId != null
                                    ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TopicDetailScreen(
                                                topicId: b.topicId!),
                                          ),
                                        )
                                    : null,
                              );
                            },
                          ),
                        ),
    );
  }
}
