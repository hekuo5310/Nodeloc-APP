# NodeLoc APP

[![Build Apps](https://github.com/hekuo5310/Nodeloc-APP/actions/workflows/build.yml/badge.svg)](https://github.com/hekuo5310/Nodeloc-APP/actions/workflows/build.yml)

[NodeLoc](https://www.nodeloc.com)（自由、平等、友好、开放、有趣的互联网交流社区）的**全平台开源客户端**，基于 Flutter 构建，一套代码覆盖 **Android / iOS / Windows / macOS / Linux**。

界面遵循 NodeLoc 官方品牌风格：暖黑背景 + 松石绿 / 橘橙双色主色调（提取自官网主题配色方案）。

> 本项目为社区驱动的非官方客户端，站点地址固定为 `https://www.nodeloc.com`，与 NodeLoc 官方无关。

## 功能

- **登录**
  - 账号密码登录（用户名 / 邮箱 + 密码），自动识别并支持 2FA 动态口令
  - 浏览器授权登录：在内置浏览器中完成站点登录后授权，支持**第三方账号（LinuxDo Connect 等）、邮箱登录链接、2FA 等**站点提供的全部登录方式，授权后凭 RSA 加密的一次性凭据（User API Key）自动返回应用
  - 凭据仅保存在设备本地，不上传任何第三方服务器
- **话题流**：最新 / 热门 / 新帖 / 未读，下拉刷新 + 无限滚动
- **分类浏览**：分类与子分类，点击进入分类话题列表
- **话题详情**：Discourse 原生 HTML 富文本渲染（引用块、代码块、图片、链接等），楼层分页加载
- **互动**：点赞 / 取消点赞、回复楼层、发起新话题（Markdown）
- **图片上传**：编辑器中选择本地图片，上传后自动以 Markdown 语法插入正文
- **私信**：会话列表、新建私信（多收件人）、回复私信
- **收藏**：话题一键收藏 / 取消收藏，收藏列表统一管理
- **阅读进度同步**：自动上报阅读时间，与网页版共享已读 / 未读状态
- **通知中心**：回复、引用、提及、点赞等通知，点击跳转话题、一键全部已读
- **个人中心**：资料、发帖 / 徽章统计、我的主题、我的收藏、退出登录
- **搜索**：全文搜索
- **自适应布局**：手机端底部导航栏，桌面端侧边导航栏
- **桌面体验**：Windows / macOS 自定义标题栏（拖拽移动、最小化 / 最大化 / 关闭），默认窗口尺寸与居中

## 下载安装

### 方式一：Actions 构建产物（最新代码）

每次推送代码后，[Actions](https://github.com/hekuo5310/Nodeloc-APP/actions/workflows/build.yml) 会自动编译全部平台。进入最新的 `Build Apps` 运行记录，在页面底部 **Artifacts** 区域下载：

| 产物 | 平台 | 说明 |
|---|---|---|
| `nodeloc-android` | Android | 通用 APK、按 ABI 拆分的 APK、AAB |
| `nodeloc-linux` | Linux x64 | tar.gz（解压后运行 `bundle/Nodeloc`） |
| `nodeloc-windows` | Windows x64 | zip（解压后运行 `Nodeloc.exe`） |
| `nodeloc-macos` | macOS (Apple Silicon) | zip（含 .app） |
| `nodeloc-ios` | iOS | **未签名** IPA，需自签后安装 |

### 方式二：Releases（正式版本）

推送 `v*` 标签（如 `v1.1.0`）后，CI 会自动构建全部平台并发布到 [Releases](https://github.com/hekuo5310/Nodeloc-APP/releases)：

```bash
git tag v1.1.0
git push origin v1.1.0
```

### 各平台注意事项

- **Android**：直接安装 APK（universal 版兼容所有架构；arm64 版体积更小）。AAB 仅供上架 Google Play 使用
- **iOS**：CI 产出的 IPA 未签名（苹果要求付费开发者账号）。可通过 [AltStore](https://altstore.io)、[Sideloadly](https://sideloadly.io)、爱思助手等工具自签安装，或 fork 后用个人证书在 Xcode 中直接构建
- **macOS**：首次打开若被 Gatekeeper 拦截，在终端执行 `xattr -cr /Applications/Nodeloc.app`，或到「系统设置 - 隐私与安全性」点击「仍要打开」
- **Linux**：需要 GTK3 与 webkit2gtk 运行库（主流发行版自带；Arch 系执行 `sudo pacman -S gtk3 webkit2gtk-4.1`，Debian 系执行 `sudo apt install libgtk-3-0 libwebkit2gtk-4.1-0`）
- **Windows**：内置浏览器登录需要 WebView2 运行时（Windows 10 / 11 一般已预装，缺失时可在微软官网安装）

## 登录与 API 说明

本应用全部使用 **Discourse 普通用户端点**（与浏览器访问网页版一致的会话 / 授权机制），不涉及管理员 API Key：

- 账号密码登录：`GET /session/csrf.json` 获取令牌，`POST /session` 登录（自动携带 2FA 字段），Cookie 会话持久化在本机
- 浏览器授权登录：走 Discourse 官方 **User API Key** 流程——应用生成一次性 RSA-2048 密钥对，在内置浏览器中打开 `/user-api-key/new` 授权页（未登录时先跳转站点登录页，此时可使用任意登录方式），授权后站点把加密凭据重定向到 `discourse://` 协议，应用拦截并解密得到 API Key，之后以 `User-Api-Key` 请求头访问只读 / 写入端点
- 其余均为常规端点（`/latest.json`、`/t/{id}.json`、`/posts`、`/post_actions`、`/bookmarks`、`/uploads.json`、`/topics/timings`、`/notifications.json` 等）

## 本地开发

```bash
# 1. 克隆
git clone https://github.com/hekuo5310/Nodeloc-APP.git
cd Nodeloc-APP

# 2. 生成平台工程（平台目录不入库，按本地 Flutter 版本生成）
flutter create . --platforms=android,ios,linux,macos,windows \
  --org com.nodeloc --project-name nodeloc_app

# 3. 打补丁（Android 网络权限、应用名、图标、macOS 沙盒权限等）
python3 -m pip install pillow cairosvg   # 补丁与图标依赖
python3 scripts/patch_platforms.py       # 若修改了 logo.svg，先跑 python3 scripts/make_icon.py

# 4. 运行
flutter pub get
flutter run
```

Linux 构建另需：`sudo apt install cmake ninja-build libgtk-3-dev libwebkit2gtk-4.1-dev`

### 项目结构

```
├── .github/workflows/build.yml   # 五平台自动编译 + tag 自动发版
├── assets/icon/                  # 图标与原始 SVG 字标
├── scripts/
│   ├── patch_platforms.py        # 平台工程补丁（权限/名称/图标）
│   └── make_icon.py              # 图标生成（渐变底 + 白色字标）
├── lib/
│   ├── api/discourse_api.dart    # Discourse 用户级 API 客户端（Cookie / User-Api-Key 双模式）
│   ├── models.dart               # 数据模型
│   ├── app_state.dart            # 全局状态（会话/主题/浏览器授权登录）
│   ├── theme.dart                # NodeLoc 品牌主题
│   ├── oauth/                    # RSA 工具 + 内置浏览器授权登录
│   ├── desktop_window.dart       # 桌面窗口与自定义标题栏
│   └── screens/                  # 各界面
└── pubspec.yaml
```

## License

[MPL-2.0](./LICENSE)
