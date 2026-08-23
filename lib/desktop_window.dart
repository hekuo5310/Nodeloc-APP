import 'desktop_window_stub.dart'
    if (dart.library.io) 'desktop_window_io.dart' as impl;

import 'package:flutter/widgets.dart';

/// 初始化桌面窗口（标题 / 尺寸 / 居中，Windows 与 macOS 使用自定义标题栏）
Future<void> initDesktopWindow() => impl.initDesktopWindow();

/// 自定义标题栏；非桌面端或不支持时返回 null（使用系统标题栏）
Widget? desktopTitleBar() => impl.desktopTitleBar();
