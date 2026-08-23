import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Windows / macOS：使用无边框窗口 + 自绘标题栏；Linux：保留系统标题栏
bool get _customTitleBar => Platform.isWindows || Platform.isMacOS;

Future<void> initDesktopWindow() async {
  if (kIsWebGuard) return;
  if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

  await windowManager.ensureInitialized();

  final options = WindowOptions(
    title: 'Nodeloc',
    size: const Size(1200, 800),
    minimumSize: const Size(440, 600),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle:
        Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (Platform.isWindows) {
      await windowManager.setAsFrameless();
      await windowManager.setSize(const Size(1200, 800));
      await windowManager.center();
    }
    await windowManager.show();
    await windowManager.focus();
  });
}

Widget? desktopTitleBar() {
  if (kIsWebGuard) return null;
  if (!_customTitleBar) return null;
  return const DesktopTitleBar();
}

/// kIsWeb 常量在 widgets 库中，此处通过 const eval 避免 web 平台调用
const bool kIsWebGuard = bool.fromEnvironment('dart.library.js_util');

/// 自定义标题栏：拖拽区 + 应用名 + (Windows) 窗口控制按钮
class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWin = Platform.isWindows;

    return SizedBox(
      height: 38,
      child: DragToMoveArea(
        child: Row(
          children: [
            // macOS 红绿灯按钮预留空间
            SizedBox(width: Platform.isMacOS ? 78 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset('assets/icon/app_icon.png',
                  width: 18, height: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Nodeloc',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isWin) ...[
              _WinButton(
                icon: Icons.horizontal_rule,
                onTap: () => windowManager.minimize(),
              ),
              _WinButton(
                icon: Icons.crop_square,
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _WinButton(
                icon: Icons.close,
                isClose: true,
                onTap: () => windowManager.close(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WinButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;
  const _WinButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 42,
          height: 38,
          color: _hover
              ? (widget.isClose
                  ? scheme.error
                  : scheme.onSurface.withOpacity(0.08))
              : Colors.transparent,
          child: Icon(widget.icon,
              size: 16, color: scheme.onSurface.withOpacity(0.8)),
        ),
      ),
    );
  }
}
