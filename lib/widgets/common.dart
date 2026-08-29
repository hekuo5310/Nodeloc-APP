import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import 'nekoloc_loading.dart';

export 'nekoloc_loading.dart';

/// 用户头像（带首字母回退）
class UserAvatar extends StatelessWidget {
  final String? avatarTemplate;
  final String username;
  final double size;

  const UserAvatar({
    super.key,
    required this.avatarTemplate,
    required this.username,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final url = app.avatarUrl(avatarTemplate, size: (size * 2.2).round());
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: NL.greenDark.withOpacity(0.22),
      child: url == null
          ? Text(initial,
              style: TextStyle(
                color: const Color(0xFF35C481),
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
              ))
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Text(initial,
                    style: TextStyle(
                      color: const Color(0xFF35C481),
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w700,
                    )),
                errorWidget: (_, __, ___) => Text(initial,
                    style: TextStyle(
                      color: const Color(0xFF35C481),
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
    );
  }
}

/// Discourse 风格分类徽章（色块 + 名称）
class CategoryBadge extends StatelessWidget {
  final Category category;
  final double fontSize;

  const CategoryBadge({super.key, required this.category, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          color: category.textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 话题列表卡片
class TopicTile extends StatelessWidget {
  final Topic topic;
  final Map<int, UserBrief> users;
  final Map<int, Category>? categories;
  final VoidCallback? onTap;

  const TopicTile({
    super.key,
    required this.topic,
    required this.users,
    this.categories,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final cat = categories?[topic.categoryId];

    final posterAvatars = <Widget>[];
    for (final p in topic.posters.take(4)) {
      final u = users[p.userId];
      if (u == null) continue;
      posterAvatars.add(Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Container(
          decoration: p.isLatest
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 1.6),
                )
              : null,
          child: UserAvatar(
            avatarTemplate: u.avatarTemplate,
            username: u.username,
            size: 24,
          ),
        ),
      ));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      topic.title.replaceAll(RegExp(r'<[^>]*>'), ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.35,
                        fontWeight:
                            topic.unseen ? FontWeight.w700 : FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (topic.pinned)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 2),
                      child: Icon(Icons.push_pin,
                          size: 14, color: scheme.secondary),
                    )
                  else if (topic.closed || topic.archived)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 2),
                      child: Icon(Icons.lock,
                          size: 14, color: muted.withOpacity(0.7)),
                    ),
                ],
              ),
              if (topic.excerpt != null && topic.excerpt!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  topic.excerpt!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, height: 1.4, color: muted),
                ),
              ],
              const SizedBox(height: 9),
              Row(
                children: [
                  if (cat != null) ...[
                    CategoryBadge(category: cat),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.chat_bubble_outline,
                      size: 13, color: muted.withOpacity(0.85)),
                  const SizedBox(width: 3),
                  Text('${topic.postsCount - 1 > 0 ? topic.postsCount - 1 : 0}',
                      style: TextStyle(fontSize: 12, color: muted)),
                  const SizedBox(width: 10),
                  Icon(Icons.visibility,
                      size: 13, color: muted.withOpacity(0.85)),
                  const SizedBox(width: 3),
                  Text(compactNumber(topic.views),
                      style: TextStyle(fontSize: 12, color: muted)),
                  if (topic.likeCount > 0) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.favorite_outline,
                        size: 13, color: NL.love.withOpacity(0.9)),
                    const SizedBox(width: 3),
                    Text(compactNumber(topic.likeCount),
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                  const Spacer(),
                  Text(
                    timeAgo(topic.bumpedAt ?? topic.lastPostedAt ?? topic.createdAt),
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                ],
              ),
              if (posterAvatars.isNotEmpty) ...[
                const SizedBox(height: 9),
                Row(children: [
                  ...posterAvatars.take(3),
                  if (topic.posters.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, top: 2),
                      child: Text('+${topic.posters.length - 3}',
                          style: TextStyle(fontSize: 11, color: muted)),
                    ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 错误视图
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空态视图（默认猫爪图标 —— Nekoloc 猫咪元素）
class EmptyView extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyView({super.key, required this.text, this.icon = Icons.pets});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// 加载指示器 —— Nekoloc 品牌动画（猫耳 + "nekoloc" 字标逐笔写出 + 甩尾）
class LoadingView extends StatelessWidget {
  /// 动画显示宽度；默认 220
  final double width;

  const LoadingView({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return NekolocLoadingCenter(width: width);
  }
}
