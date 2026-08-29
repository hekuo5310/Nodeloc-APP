import 'package:flutter/material.dart';

/// Nekoloc 品牌加载动画 —— 猫耳先立起，"nekoloc" 字标逐笔写出，猫尾甩出，循环播放。
///
/// 动画源文件: assets/animations/nekoloc_loading.webp
/// （2160x600, 30fps, 3.5s 循环: 猫耳 -> 逐字描边 -> 甩尾 -> 悬停 -> 淡出 -> 重来）
///
/// 用法（整页加载占位）:
///   _loading ? const LoadingView() : ...
///
/// 或直接使用:
///   const NekolocLoading(width: 220)
///
/// 注意 gaplessPlayback: 父级 rebuild 时动画不会从头 restarting。
class NekolocLoading extends StatelessWidget {
  /// 显示宽度（逻辑像素）。高度按 1080:300 比例自动计算。
  final double width;

  const NekolocLoading({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/animations/nekoloc_loading.webp',
      width: width,
      height: width * 300 / 1080,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }
}

/// 居中包装版本 —— 常见的"整页加载中"占位。
class NekolocLoadingCenter extends StatelessWidget {
  final double width;
  const NekolocLoadingCenter({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NekolocLoading(width: width),
    );
  }
}

/// 列表底部"加载更多"的窄版 —— 只显示字标，宽度较小。
class NekolocLoadingFooter extends StatelessWidget {
  const NekolocLoadingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: NekolocLoadingCenter(width: 120),
    );
  }
}
