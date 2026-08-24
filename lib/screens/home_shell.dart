import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../update_checker.dart';
import 'categories_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'topic_list_screen.dart';

/// 主框架：移动端底部导航 / 桌面端侧边导航栏
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _notificationsKey = GlobalKey<NotificationsScreenState>();
  final _messagesKey = GlobalKey<MessagesScreenState>();

  void _onSelect(int i) {
    setState(() => _index = i);
    if (i == 3) {
      // 打开通知页时刷新未读
      _notificationsKey.currentState?.reload();
      context.read<AppState>().refreshUser();
    } else if (i == 2) {
      _messagesKey.currentState?.reload();
      context.read<AppState>().refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final unread = app.user?.totalUnread ?? 0;
    final unreadPm = app.user?.unreadPrivateMessages ?? 0;
    final wide = MediaQuery.of(context).size.width >= 820;

    final pages = [
      const TopicListScreen(),
      const CategoriesScreen(),
      MessagesScreen(key: _messagesKey),
      NotificationsScreen(key: _notificationsKey),
      const ProfileScreen(),
    ];

    final updateBanner = app.updateInfo != null
        ? Material(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.16),
            child: InkWell(
              onTap: () => _showUpdateDialog(context, app),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.system_update,
                        size: 18, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '发现新版本 v${app.updateInfo!.version}，点击查看',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context).colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => app.dismissUpdate(),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(36, 28),
                      ),
                      child: const Text('以后再说', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          )
        : null;

    Widget body = IndexedStack(index: _index, children: pages);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/icon/app_icon.png',
                      width: 42, height: 42),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: Text('首页'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: Text('分类'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: unreadPm > 0,
                    label: Text(unreadPm > 99 ? '99+' : '$unreadPm'),
                    child: const Icon(Icons.mail_outline),
                  ),
                  selectedIcon: const Icon(Icons.mail),
                  label: const Text('私信'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  selectedIcon: const Icon(Icons.notifications),
                  label: const Text('通知'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('我的'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  if (updateBanner != null) updateBanner,
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          if (updateBanner != null) updateBanner,
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '首页',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: '分类',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadPm > 0,
              label: Text(unreadPm > 99 ? '99+' : '$unreadPm'),
              child: const Icon(Icons.mail_outline),
            ),
            selectedIcon: const Icon(Icons.mail),
            label: '私信',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: '通知',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, AppState app) {
    final info = app.updateInfo!;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('发现新版本 v${info.version}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('当前版本：v$kAppVersion',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info.releaseNotes.isEmpty ? '（暂无更新说明）' : info.releaseNotes,
                    style: const TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              app.dismissUpdate();
              Navigator.pop(ctx);
            },
            child: const Text('以后再说'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              app.openUpdateDownload();
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('立即下载'),
          ),
        ],
      ),
    );
  }
}
