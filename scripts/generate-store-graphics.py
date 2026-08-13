#!/usr/bin/env python3
"""Generate Google Play store icon (512) and feature graphic (1024x500)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ICON_SRC = ROOT / "assets" / "icons" / "wolfpad-icon-d3d.png"
OUT_DIR = ROOT / "docs" / "store" / "graphics"

BG = (0x2F, 0x38, 0x33)
ACCENT = (0x7A, 0xA8, 0x94)
WHITE = (0xF5, 0xF5, 0xF5)
MUTED = (0xA8, 0xB0, 0xAC)


def _font(size: int, *, japanese: bool = False, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    if japanese:
        candidates = [
            Path("C:/Windows/Fonts/meiryob.ttc") if bold else Path("C:/Windows/Fonts/meiryo.ttc"),
            Path("C:/Windows/Fonts/YuGothB.ttc") if bold else Path("C:/Windows/Fonts/YuGothM.ttc"),
            Path("/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc")
            if bold
            else Path("/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc"),
        ]
    else:
        candidates = [
            Path("C:/Windows/Fonts/segoeuib.ttf") if bold else Path("C:/Windows/Fonts/segoeui.ttf"),
            Path("C:/Windows/Fonts/arialbd.ttf") if bold else Path("C:/Windows/Fonts/arial.ttf"),
        ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def make_play_icon(source: Image.Image) -> Image.Image:
    return source.resize((512, 512), Image.Resampling.LANCZOS)


def make_feature_graphic(source: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", (1024, 500), BG)
    draw = ImageDraw.Draw(canvas)

    badge = source.resize((300, 300), Image.Resampling.LANCZOS)
    canvas.paste(badge, (72, 100), badge)

    draw.rounded_rectangle((388, 96, 392, 404), radius=2, fill=ACCENT)

    title_font = _font(78, bold=True)
    sub_font = _font(30, japanese=True)
    note_font = _font(22, japanese=True)

    draw.text((420, 118), "Padora", fill=WHITE, font=title_font)
    draw.text((420, 210), "片手ウディタコントローラー", fill=ACCENT, font=sub_font)
    draw.text((420, 262), "十字 · 決定 · 取消", fill=MUTED, font=note_font)
    draw.text((420, 298), "非公式 · Windows Host とセット", fill=MUTED, font=note_font)
    draw.text((420, 348), "1マス移動 · 短タップ触覚 · ライト/ダーク", fill=MUTED, font=note_font)

    return canvas


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(ICON_SRC).convert("RGBA")

    icon512 = make_play_icon(source)
    feature = make_feature_graphic(source)

    icon_path = OUT_DIR / "play-store-icon-512.png"
    feature_path = OUT_DIR / "play-store-feature-1024x500.png"

    icon512.save(icon_path, format="PNG", optimize=True)
    feature.save(feature_path, format="PNG", optimize=True)

    print(f"Wrote {icon_path}")
    print(f"Wrote {feature_path}")


if __name__ == "__main__":
    main()
