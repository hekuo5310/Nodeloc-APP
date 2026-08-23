import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../theme.dart';

/// 设置页
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: context.read<AppState>().baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    setState(() => _busy = true);
    await context.read<AppState>().setBaseUrl(_urlCtrl.text);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _resetUrl() async {
    setState(() => _busy = true);
    await context.read<AppState>().setBaseUrl(AppState.defaultBaseUrl);
    _urlCtrl.text = AppState.defaultBaseUrl;
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('站点地址',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '支持任意标准 Discourse 站点，修改后将以新站点重新加载会话',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlCtrl,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      hintText: 'https://www.nodeloc.com',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.replay, size: 20),
                        tooltip: '恢复默认',
                        onPressed: _busy ? null : _resetUrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _saveUrl,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text('保存并重新连接'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('外观',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.dark_mode_outlined, size: 18),
                          label: Text('深色')),
                      ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.light_mode_outlined, size: 18),
                          label: Text('浅色')),
                      ButtonSegment(
                          value: 2,
                          icon: Icon(Icons.brightness_auto_outlined, size: 18),
                          label: Text('跟随系统')),
                    ],
                    selected: {
                      switch (app.themeMode) {
                        ThemeMode.dark => 0,
                        ThemeMode.light => 1,
                        _ => 2,
                      }
                    },
                    onSelectionChanged: (v) {
                      app.setThemeMode(switch (v.first) {
                        0 => ThemeMode.dark,
                        1 => ThemeMode.light,
                        _ => ThemeMode.system,
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '默认深色主题遵循 NodeLoc 官方配色（暖黑 + 松石绿 + 橘橙）',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('源代码（GitHub）'),
                  subtitle: const Text('hekuo5310/Nodeloc-APP',
                      style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/hekuo5310/Nodeloc-APP'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('NodeLoc 网站'),
                  subtitle: Text(app.baseUrl, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse(app.baseUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: NL.greenDark,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: NL.orangeDark,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('关于',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NodeLoc 社区非官方开源客户端 v1.0.0\n'
                    '基于 Flutter 构建，覆盖 Android / iOS / Windows / macOS / Linux\n'
                    '登录使用与网页版一致的账号密码 + 2FA 动态口令，凭据仅保存在本机',
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.7,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
