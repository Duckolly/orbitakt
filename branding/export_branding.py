# export_branding.py
from pathlib import Path
from PIL import Image, ImageOps, ImageEnhance

SRC = Path("assets_raw")
OUT = Path("assets/branding")
OUT.mkdir(parents=True, exist_ok=True)

# Брендовая палитра из твоего брендбука
BLUE   = (0x0A, 0x3B, 0xFF)   # электрический синий
LIME   = (0xB7, 0xFF, 0x00)   # лайм
CYAN   = (0x00, 0xE5, 0xFF)   # циан
DARK   = (0x0B, 0x1A, 0x3C)   # тёмный синий
LIGHT  = (0xF4, 0xF6, 0xFA)   # светлый серый (почти белый)
WHITE  = (0xFF, 0xFF, 0xFF)


def open_rgba(name: str) -> Image.Image:
    im = Image.open(SRC / name)
    return im.convert("RGBA")


def fit_canvas(src: Image.Image, w: int, h: int, bg, pad_ratio: float = 0.0) -> Image.Image:
    """Вписывает src целиком в холст w*h на фон bg, без обрезки.
    pad_ratio — дополнительный внутренний отступ (0..0.5) для safe-zone."""
    inner_w = int(w * (1 - 2 * pad_ratio))
    inner_h = int(h * (1 - 2 * pad_ratio))
    thumb = src.copy()
    thumb.thumbnail((inner_w, inner_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h), bg + (255,))
    x = (w - thumb.width) // 2
    y = (h - thumb.height) // 2
    canvas.alpha_composite(thumb, (x, y))
    return canvas.convert("RGB")


def fit_transparent(src: Image.Image, w: int, h: int, pad_ratio: float = 0.0) -> Image.Image:
    """То же, но фон прозрачный — для foreground/адаптивных иконок."""
    inner_w = int(w * (1 - 2 * pad_ratio))
    inner_h = int(h * (1 - 2 * pad_ratio))
    thumb = src.copy()
    thumb.thumbnail((inner_w, inner_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = (w - thumb.width) // 2
    y = (h - thumb.height) // 2
    canvas.alpha_composite(thumb, (x, y))
    return canvas


def white_to_alpha(im: Image.Image, thresh: int = 238) -> Image.Image:
    """Черновое вырезание белого фона в прозрачность (для mark без альфы).
    Светлые участки лайма/циана выживают, т.к. у них не все каналы > thresh."""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if min(r, g, b) >= thresh:
                px[x, y] = (r, g, b, 0)
    return im


def to_mono(im: Image.Image) -> Image.Image:
    """Грейскейл + контраст — черновая монохромная версия знака."""
    g = ImageOps.grayscale(im.convert("RGB"))
    g = ImageEnhance.Contrast(g).enhance(1.6)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    # чёрный знак на прозрачном: берём luminance как инвертированную альфу
    alpha = ImageOps.invert(g)
    black = Image.new("RGBA", im.size, (0x0B, 0x1A, 0x3C, 255))
    black.putalpha(alpha)
    return black


# ---------- ИКОНКА ПРИЛОЖЕНИЯ (из icon.png, он уже квадратный) ----------
icon = open_rgba("icon.png")
fit_canvas(icon, 512, 512, DARK).save(OUT / "icon-512.png")          # Google Play high-res
fit_canvas(icon, 192, 192, DARK).save(OUT / "icon-192.png")          # PWA / web
fit_canvas(icon, 1024, 1024, DARK).save(OUT / "icon-1024.png")       # запас

# maskable-иконка: знак с большим отступом, чтобы маска не срезала
fit_canvas(icon, 512, 512, DARK, pad_ratio=0.18).save(OUT / "icon-maskable-512.png")

# ---------- FEATURE GRAPHIC 1024x500 (wordmark на СВЕТЛОМ фоне) ----------
wordmark = open_rgba("wordmark.png")
fg = fit_canvas(wordmark, 1024, 500, LIGHT, pad_ratio=0.10)
fg.save(OUT / "feature-graphic-1024x500.png")

# ---------- OG / SOCIAL 1200x630 (тоже светлый фон под тёмные буквы) ----------
og = fit_canvas(wordmark, 1200, 630, LIGHT, pad_ratio=0.12)
og.save(OUT / "og-cover-1200x630.png")

# ---------- ГОРИЗОНТАЛЬНЫЙ ЛОГОТИП ДЛЯ САЙТА/README (прозрачный фон) ----------
fit_transparent(wordmark, 1200, 360).save(OUT / "logo-horizontal.png")

# ---------- ANDROID ADAPTIVE ICON FOREGROUND (из mark.png) ----------
mark = open_rgba("mark.png")
# если у mark нет альфы (белый фон) — вырезаем черново
if mark.getextrema()[3][0] == 255:  # альфа везде 255 => нет прозрачности
    mark_t = white_to_alpha(mark)
else:
    mark_t = mark
# foreground 432x432 со safe-zone ~66% => pad_ratio 0.17
fit_transparent(mark_t, 432, 432, pad_ratio=0.17).save(OUT / "adaptive-fg-432.png")
fit_transparent(mark_t, 512, 512, pad_ratio=0.17).save(OUT / "adaptive-fg-512.png")
# background — сплошной тёмно-синий
Image.new("RGB", (432, 432), DARK).save(OUT / "adaptive-bg-432.png")
Image.new("RGB", (512, 512), DARK).save(OUT / "adaptive-bg-512.png")

# ---------- FAVICON ----------
# цветной favicon из иконки (читается в 32+, в 16 будет кашей — см. предупреждение)
fit_canvas(icon, 32, 32, DARK).save(OUT / "favicon-32.png")
fit_canvas(icon, 180, 180, DARK).save(OUT / "apple-touch-icon-180.png")
fit_canvas(icon, 512, 512, DARK).save(OUT / "favicon-512.png")
# черновой монохромный favicon из mark (для 16/32 на светлом фоне сайта)
mono = to_mono(mark_t)
fit_transparent(mono, 16, 16, pad_ratio=0.10).save(OUT / "favicon-mono-16.png")
fit_transparent(mono, 32, 32, pad_ratio=0.10).save(OUT / "favicon-mono-32.png")

print("Готово. Файлы в:", OUT)
for p in sorted(OUT.iterdir()):
    print("  ", p.name, p.size)
