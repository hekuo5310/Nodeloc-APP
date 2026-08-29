import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 全屏图片查看器：
/// - 双指缩放 / 拖拽平移（InteractiveViewer）
/// - 双击在 1x / 2.5x 之间切换
/// - 多图左右滑动切换（缩放状态下锁定翻页）
/// - 底部页码指示，右上角关闭按钮
///
/// 用法: ImageViewer.show(context, urls: urls, initialIndex: 0);
class ImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  /// 便捷入口：全屏打开图片列表
  static void show(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) =>
            ImageViewer(urls: urls, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late final PageController _controller;
  late int _index;

  /// 当前页是否处于放大状态 —— 放大时禁止 PageView 滑动，交由 InteractiveViewer 平移
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片翻页 + 缩放
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            // 放大时锁定翻页，避免手势冲突
            physics:
                _zoomed ? const NeverScrollableScrollPhysics() : null,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _ZoomableImage(
              url: widget.urls[i],
              onZoomChanged: (z) => setState(() => _zoomed = z),
            ),
          ),

          // 顶部渐隐遮罩 + 关闭按钮
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // 底部页码
          if (widget.urls.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单张可缩放图片：双指缩放 + 双击 1x/2.5x
class _ZoomableImage extends StatefulWidget {
  final String url;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableImage({required this.url, required this.onZoomChanged});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _tc = TransformationController();
  late final AnimationController _anim;
  Animation<Matrix4>? _matrixAnim;
  TapDownDetails? _lastDoubleTap;

  static const _doubleTapScale = 2.5;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _anim.addListener(() {
      if (_matrixAnim != null) _tc.value = _matrixAnim!.value;
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final current = _tc.value.getMaxScaleOnAxis();
    Matrix4 target;
    if (current > 1.05) {
      target = Matrix4.identity();
    } else {
      // 以双击位置为中心放大
      final pos = _lastDoubleTap?.localPosition ?? Offset.zero;
      final dx = -pos.dx * (_doubleTapScale - 1);
      final dy = -pos.dy * (_doubleTapScale - 1);
      target = Matrix4.identity()
        ..scale(_doubleTapScale)
        ..translate(dx, dy);
    }
    _matrixAnim = Matrix4Tween(begin: _tc.value, end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward(from: 0);
    widget.onZoomChanged(target.getMaxScaleOnAxis() > 1.05);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _tc,
      minScale: 1.0,
      maxScale: 4.0,
      onInteractionEnd: (_) =>
          widget.onZoomChanged(_tc.value.getMaxScaleOnAxis() > 1.05),
      child: GestureDetector(
        onDoubleTapDown: (d) => _lastDoubleTap = d,
        onDoubleTap: _onDoubleTap,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
