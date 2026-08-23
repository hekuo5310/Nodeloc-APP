import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'desktop_window.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDesktopWindow();
  final prefs = await SharedPreferences.getInstance();
  runApp(NodelocApp(prefs: prefs));
}

class NodelocApp extends StatelessWidget {
  final SharedPreferences prefs;
  const NodelocApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'NodeLoc',
            debugShowCheckedModeBanner: false,
            themeMode: app.themeMode,
            theme: NL.light(),
            darkTheme: NL.dark(),
            builder: (context, child) {
              final bar = desktopTitleBar();
              if (bar == null || child == null) {
                return child ?? const SizedBox.shrink();
              }
              return Column(
                children: [
                  bar,
                  Expanded(child: child),
                ],
              );
            },
            home: const _Gate(),
          );
        },
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.initialized) {
      return const _Splash();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: app.isLoggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
