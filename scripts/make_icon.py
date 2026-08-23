#!/usr/bin/env python3
"""生成 Nodeloc App 图标：绿→橙对角渐变底 + 白色 nodeloc 字标（与官方触摸图标风格一致）。
依赖: pip install cairosvg pillow
"""
import os

try:
    import cairosvg
    from PIL import Image
except ImportError as e:
    raise SystemExit(f'缺少依赖: {e}，请先 pip install cairosvg pillow')

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SVG_PATH = os.path.join(ROOT, 'assets', 'icon', 'logo.svg')
OUT_PATH = os.path.join(ROOT, 'assets', 'icon', 'app_icon.png')

GREEN = (0x00, 0x99, 0x66)
ORANGE = (0xFF, 0x99, 0x33)
SIZE = 1024


def gradient(size, c1, c2):
    """左上→右下线性渐变"""
    im = Image.new('RGB', (size, size))
    px = im.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))
    return im


def main():
    with open(SVG_PATH, 'r', encoding='utf-8') as f:
        svg = f.read()
    # 所有描边改为白色
    svg = svg.replace('stroke="#009966"', 'stroke="#FFFFFF"')
    svg = svg.replace('stroke="#FF9933"', 'stroke="#FFFFFF"')

    wordmark_w = 3600
    cairosvg.svg2png(bytestring=svg.encode('utf-8'),
                     write_to='/tmp/nl_wordmark.png',
                     output_width=wordmark_w)
    wm = Image.open('/tmp/nl_wordmark.png').convert('RGBA')

    bg = gradient(SIZE, GREEN, ORANGE).convert('RGBA')

    # 字标宽度约 72%
    target_w = int(SIZE * 0.72)
    target_h = int(wm.height * target_w / wm.width)
    wm = wm.resize((target_w, target_h), Image.LANCZOS)

    # 垂直居中稍偏下（视觉修正）
    pos = ((SIZE - target_w) // 2, (SIZE - target_h) // 2 + 10)
    bg.alpha_composite(wm, pos)

    bg.convert('RGB').save(OUT_PATH, 'PNG')
    print(f'图标已生成: {OUT_PATH} ({SIZE}x{SIZE})')


if __name__ == '__main__':
    main()
