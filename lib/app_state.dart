import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'api/discourse_api.dart';
import 'models.dart';

/// 全局应用状态：站点设置 + 会话
class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  AppState(this.prefs) {
    _init();
  }

  static const defaultBaseUrl = 'https://www.nodeloc.com';

  late String baseUrl;
  ThemeMode themeMode = ThemeMode.dark;
  DiscourseApi? _api;
  PersistCookieJar? _jar;
  CurrentUser? user;
  SiteInfo? siteInfo;
  bool initialized = false;

  bool get isLoggedIn => user != null;
  DiscourseApi get api => _api ?? (throw StateError('API 未初始化'));

  Future<void> _init() async {
    baseUrl = prefs.getString('base_url') ?? defaultBaseUrl;
    final tm = prefs.getString('theme_mode') ?? 'dark';
    themeMode = switch (tm) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
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
    _api = DiscourseApi(base: baseUrl, jar: _jar!);
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

  Future<String?> login(String login, String password, String? totp) async {
    await api.login(login: login, password: password, totp: totp);
    await refreshUser();
    return user?.username;
  }

  Future<void> logout() async {
    await api.logout();
    await _jar?.deleteAll();
    user = null;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    var cleaned = url.trim();
    if (cleaned.isEmpty) cleaned = defaultBaseUrl;
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    baseUrl = cleaned;
    await prefs.setString('base_url', cleaned);
    await _createApi();
    siteInfo = null;
    try {
      siteInfo = await api.siteBasicInfo();
    } catch (_) {}
    await refreshUser();
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
