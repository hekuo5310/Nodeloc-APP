import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/discourse_api.dart';
import '../app_state.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();
  bool _obscure = true;
  bool _showTotp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _pwdCtrl.dispose();
    _totpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final login = _loginCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    if (login.isEmpty || pwd.isEmpty) {
      setState(() => _error = '请输入用户名 / 邮箱和密码');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      await app.login(login, pwd, _showTotp ? _totpCtrl.text : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('欢迎回来，${app.user?.username ?? ''}')),
        );
      }
    } on SecondFactorRequiredException catch (e) {
      setState(() {
        _busy = false;
        _showTotp = true;
        _error = '${e.message}\n已为你展开动态口令（2FA）输入框';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _editBaseUrl() async {
    final app = context.read<AppState>();
    final ctrl = TextEditingController(text: app.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('站点地址'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://www.nodeloc.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('保存')),
        ],
      ),
    );
    if (url != null && url.trim().isNotEmpty && mounted) {
      setState(() => _busy = true);
      await app.setBaseUrl(url);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final siteTitle = app.siteInfo?.title ?? 'NodeLoc';
    final siteDesc =
        app.siteInfo?.description ?? '自由、平等、友好、开放、有趣的互联网交流社区';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/icon/app_icon.png',
                            width: 76, height: 76),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(siteTitle,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            siteDesc,
                            style: TextStyle(
                                fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _loginCtrl,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '用户名或邮箱',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pwdCtrl,
                    obscureText: _obscure,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      hintText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _showTotp
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: TextField(
                              controller: _totpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '动态口令（2FA 验证码）',
                                prefixIcon: Icon(Icons.password_outlined),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _showTotp = !_showTotp),
                      icon: const Icon(Icons.vpn_key_outlined, size: 16),
                      label: Text(
                        _showTotp ? '收起 2FA' : '使用动态口令（2FA）',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style:
                            TextStyle(fontSize: 13, color: scheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('服务器：${app.baseUrl}',
                          style: TextStyle(
                              fontSize: 11.5, color: scheme.onSurfaceVariant)),
                      TextButton(
                        onPressed: _editBaseUrl,
                        child: const Text('切换站点', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '登录使用与网页版相同的账号体系（账号密码 / 2FA 动态口令）\n第三方 OAuth 登录请先在网页版完成绑定',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant.withOpacity(0.8),
                        height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: NL.orangeDark.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '本客户端为社区开源项目，与 NodeLoc 官方无关',
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
