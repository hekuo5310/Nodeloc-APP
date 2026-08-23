import 'package:flutter/material.dart';

import 'webview_login_stub.dart'
    if (dart.library.io) 'webview_login_io.dart' as impl;

/// 在内置浏览器窗口中打开 Discourse 授权页。
/// 用户完成登录（任意方式：密码/2FA/第三方 OAuth/邮箱链接）并点击授权后，
/// 站点会跳转 discourse://auth_redirect?payload=...，本函数拦截该跳转并
/// 返回完整回调 URL；用户关闭窗口/取消则返回 null。
Future<String?> openAuthorizeWindow(BuildContext context, String authUrl) =>
    impl.openAuthorizeWindow(context, authUrl);
