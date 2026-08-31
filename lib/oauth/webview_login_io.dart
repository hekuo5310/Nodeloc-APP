import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../update_checker.dart';

/// 移动端：应用内全屏 WebView 路由
class _WebViewLoginPage extends StatefulWidget {
  final String url;
  const _WebViewLoginPage({required this.url});

  @override
  State<_WebViewLoginPage> createState() => _WebViewLoginPageState();
}

class _WebViewLoginPageState extends State<_WebViewLoginPage> {
  late final WebViewController _controller;
  bool _done = false;

  void _maybeFinish(String url) {
    if (_done) return;
    _done = true;
    Navigator.of(context).pop(url);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.startsWith('discourse://')) {
            _maybeFinish(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录并授权', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

Future<String?> openAuthorizeWindow(BuildContext context, String authUrl) async {
  // ---------------------------------------------------------------- 桌面端
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final completer = Completer<String?>();
    var settled = false;

    final webview = await WebviewWindow.create(
      configuration: const CreateConfiguration(
        windowHeight: 720,
        windowWidth: 500,
        title: 'Nekoloc 登录授权',
        titleBarHeight: 40,
      ),
    );
    webview.setApplicationNameForUserAgent('Nekoloc/$kAppVersion');
    webview.setOnUrlRequestCallback((url) {
      if (url.startsWith('discourse://')) {
        if (!settled) {
          settled = true;
          completer.complete(url);
        }
        return true; // 阻止跳转
      }
      return false;
    });
    unawaited(webview.onClose.then((_) {
      if (!settled) {
        settled = true;
        completer.complete(null);
      }
    }));
    webview.launch(authUrl);

    final result = await completer.future;
    try {
      webview.close();
    } catch (_) {}
    return result;
  }

  // ---------------------------------------------------------------- 移动端
  if (Platform.isAndroid || Platform.isIOS) {
    if (!context.mounted) return null;
    return Navigator.of(context, rootNavigator: true).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _WebViewLoginPage(url: authUrl),
      ),
    );
  }

  return null;
}
