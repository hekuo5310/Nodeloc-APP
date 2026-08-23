import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
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
            Expanded(child: IndexedStack(index: _index, children: pages)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
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
}
