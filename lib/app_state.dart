import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'api/discourse_api.dart';
import 'models.dart';
import 'oauth/rsa.dart';
import 'oauth/webview_login.dart';

/// 全局应用状态：会话 + 外观
class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  AppState(this.prefs) {
    _init();
  }

  /// 站点固定为 NodeLoc 官方
  static const String baseUrl = 'https://www.nodeloc.com';

  ThemeMode themeMode = ThemeMode.dark;
  DiscourseApi? _api;
  PersistCookieJar? _jar;
  CurrentUser? user;
  SiteInfo? siteInfo;
  bool initialized = false;
  String? _userApiKey;

  bool get isLoggedIn => user != null;
  DiscourseApi get api => _api ?? (throw StateError('API 未初始化'));

  Future<void> _init() async {
    final tm = prefs.getString('theme_mode') ?? 'dark';
    themeMode = switch (tm) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    _userApiKey = prefs.getString('user_api_key');
    await _createApi();
    try {
      siteInfo = await api.siteBasicInfo();
    } catch (_) {}
    await refreshUser();
    initialized = true;
    notifyListeners();
  }

  Future<void> _createApi() async {
    final dir = await getApplicationSupportDirectory();
    final cookieDir = Directory('${dir.path}/cookies');
    if (!cookieDir.existsSync()) {
      cookieDir.createSync(recursive: true);
    }
    _jar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(cookieDir.path),
    );
    _api = DiscourseApi(
      base: baseUrl,
      jar: _jar!,
      userApiKey: _userApiKey,
    );
  }

  /// 静默刷新当前用户（不触发 UI loading）
  Future<void> refreshUser() async {
    try {
      user = await api.currentUser();
    } catch (_) {
      user = null;
    }
    notifyListeners();
  }

  Future<void> login(String login, String password, String? totp) async {
    // 若存在旧的 API Key 会话，先清理，避免混合
    if (_userApiKey != null) {
      _userApiKey = null;
      await prefs.remove('user_api_key');
      await _createApi();
    }
    await api.login(login: login, password: password, totp: totp);
    await refreshUser();
  }

  /// 浏览器授权登录（支持第三方 OAuth / 邮箱登录链接 / 2FA 等全部登录方式）。
  /// 流程：生成一次性 RSA 密钥对 -> 内置浏览器打开 Discourse 授权页 ->
  /// 用户以任意方式登录并授权 -> 拦截 discourse:// 回调 -> 解密得到 User-Api-Key。
  Future<void> loginViaBrowser(BuildContext context) async {
    if (_userApiKey != null) {
      _userApiKey = null;
      await prefs.remove('user_api_key');
      await _createApi();
    }

    final bundle = generateRsaKeyPair();
    final nonce = randomHex(32);
    final clientId = randomHex(24);
    final authUrl = Uri.parse('$baseUrl/user-api-key/new').replace(queryParameters: {
      'application_name': 'Nodeloc App',
      'client_id': clientId,
      'scopes': 'read,write,session_info,notifications',
      'auth_redirect': 'discourse://auth_redirect',
      'nonce': nonce,
      'public_key': bundle.publicKeyPem,
    }).toString();

    // ignore: use_build_context_synchronously
    final callbackUrl = await openAuthorizeWindow(context, authUrl);
    if (callbackUrl == null) {
      throw ApiException('已取消授权');
    }

    final uri = Uri.parse(callbackUrl);
    if (uri.queryParameters['denied'] == 'true') {
      throw ApiException('你拒绝了授权');
    }
    final payload = uri.queryParameters['payload'];
    if (payload == null || payload.isEmpty) {
      throw ApiException('授权回调缺少凭据');
    }

    final data = decryptUserApiKeyPayload(
      bundle: bundle,
      payloadB64: payload,
      expectedNonce: nonce,
    );
    final key = data?['key']?.toString();
    if (data == null || key == null || key.isEmpty) {
      throw ApiException('授权凭据解密失败，请重试');
    }

    _userApiKey = key;
    await prefs.setString('user_api_key', key);
    await _createApi();
    await refreshUser();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    _userApiKey = null;
    await prefs.remove('user_api_key');
    await _jar?.deleteAll();
    user = null;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    prefs.setString(
      'theme_mode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        _ => 'dark',
      },
    );
    notifyListeners();
  }

  String? avatarUrl(String? template, {int size = 96}) =>
      _api?.resolveAvatarUrl(template, size: size);
}
