# export_adaptive_icons.py
from pathlib import Path
from PIL import Image

BRANDING = Path("assets/branding")      # выход прошлого export_branding.py
RAW      = Path("assets_raw")           # твои исходники
RES      = Path("android/app/src/main/res")

FG_MASTER = BRANDING / "adaptive-fg-432.png"   # RGBA, знак с safe-zone
BG_MASTER = BRANDING / "adaptive-bg-432.png"   # RGB, сплошной #0B1A3C
LEGACY_MASTER = RAW / "icon.png"               # RGBA/RGB, готовая иконка

DENSITY = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
LAYER_DP = 108      # холст адаптивного слоя
LEGACY_DP = 48      # legacy-иконка

def px(dp: float, d: float) -> int:
    return round(dp * d)

def paste_centered(src: Image.Image, size: int) -> Image.Image:
    """Вписывает src целиком в квадрат size без обрезки, фон прозрачный."""
    thumb = src.copy()
    thumb.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(thumb, ((size - thumb.width) // 2,
                                   (size - thumb.height) // 2))
    return canvas

def resize_square(src: Image.Image, size: int) -> Image.Image:
    """Для заведомо квадратных мастеров (фон/legacy) — прямой resize."""
    return src.convert("RGBA").resize((size, size), Image.LANCZOS)

def save_png(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "PNG")
    print(f"  {path}  {im.size[0]}x{im.size[1]}")

fg = Image.open(FG_MASTER).convert("RGBA")
bg = Image.open(BG_MASTER).convert("RGB")
legacy = Image.open(LEGACY_MASTER).convert("RGBA")

print("Адаптивные слои (drawable-*/):")
for name, d in DENSITY.items():
    n = px(LAYER_DP, d)
    save_png(paste_centered(fg, n), RES / f"drawable-{name}" / "ic_launcher_foreground.png")
    save_png(resize_square(bg, n),  RES / f"drawable-{name}" / "ic_launcher_background.png")

print("Legacy-иконки (mipmap-*/):")
for name, d in DENSITY.items():
    n = px(LEGACY_DP, d)
    sq = resize_square(legacy, n)
    save_png(sq, RES / f"mipmap-{name}" / "ic_launcher.png")
    save_png(sq, RES / f"mipmap-{name}" / "ic_launcher_round.png")

print("\nГотово. XML-адаптеры из шага 3 положи вручную в mipmap-anydpi-v26/.")
