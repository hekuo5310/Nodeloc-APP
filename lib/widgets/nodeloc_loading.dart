import 'package:flutter/material.dart';

/// Nodeloc 品牌加载动画 —— "nodeloc" 字标被逐笔写出，循环播放。
///
/// 动画源文件: assets/animations/nodeloc_loading.webp
/// （1920x560, 30fps, 3.5s 循环: 逐字描边 -> 悬停 -> 淡出 -> 重来）
///
/// 用法（整页加载占位，取代旧的"加载中"菊花）:
///   _loading ? const LoadingView() : ...
///
/// 或直接使用:
///   const NodelocLoading(width: 220)
///
/// 注意 gaplessPlayback: 父级 rebuild 时动画不会从头 restarting。
class NodelocLoading extends StatelessWidget {
  /// 显示宽度（逻辑像素）。高度按 960:280 比例自动计算。
  final double width;

  const NodelocLoading({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/animations/nodeloc_loading.webp',
      width: width,
      height: width * 280 / 960,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }
}

/// 居中包装版本 —— 常见的"整页加载中"占位。
class NodelocLoadingCenter extends StatelessWidget {
  final double width;
  const NodelocLoadingCenter({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NodelocLoading(width: width),
    );
  }
}

/// 列表底部"加载更多"的窄版 —— 只显示字标，宽度较小。
class NodelocLoadingFooter extends StatelessWidget {
  const NodelocLoadingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: NodelocLoadingCenter(width: 120),
    );
  }
}
