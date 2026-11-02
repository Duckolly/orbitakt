
Принял — вижу четыре растровых ассета и правильно их распаковываю. Главное, что ты имел в виду под «не резанные»: у тебя есть **целые композиции без кадрирования**, и их нельзя тупо кропать под чужие пропорции — нужно вписывать с полями (letterbox) на брендовый фон. Ниже — сопоставление, экспорт‑скрипт без обрезки и точечные патчи сайта под эту палитру.

Честная рамка сразу: я **не могу забрать эти PNG как файлы и вернуть их обратно** — я вижу их только как изображения в сообщении. Поэтому даю скрипт, который ты запустишь локально, положив исходники в папку, и он сам нарежет все форматы **без потери композиции**.

---

## 1. Что есть на картинках и куда что идёт

| Твой файл (сохрани так) | Что на изображении | Назначение |
|---|---|---|
| `icon.png` | картинка 1 — скруглённый квадрат, знак на тёмно‑синем | иконка приложения 512×512, high‑res icon, maskable‑основа |
| `wordmark.png` | картинка 2 — горизонтальный логотип «ДВИЖ», тёмные буквы на белом | шапка сайта, README, feature graphic, og‑image, посты |
| `brandbook.png` | картинка 3 — лист брендбука (палитра, ассоциации, мокапы) | референс / карусель в постах / презентация архитектору. **Не для экспорта в стор** |
| `mark.png` | картинка 4 — чистый знак без рамки и фона | foreground для Android adaptive icon, наложение на фото, основа для монохрома |

Вот это и есть «не резанные»: `mark.png` — знак без рамки, `wordmark.png` — логотип без обрезанных краёв. Их нельзя кропать под квадрат/16:9 — только вписывать целиком.

---

## 2. Принцип экспорта: padding вместо crop

Для каждого целевого формата скрипт делает так:

1. берёт исходник целиком;
2. уменьшает с сохранением пропорций (`thumbnail`);
3. создаёт холст нужного размера на **брендовом фоне**;
4. центрирует знак;
5. сохраняет.

Композиция не режется никогда. Фон подбирается по типу ассета:

- `wordmark` (тёмные буквы) → **светлый** фон `#F4F6FA`, иначе буквы пропадут;
- `icon` / `mark` (яркий знак) → тёмный `#0B1A3C` или прозрачность.

Это критично: если положить `wordmark.png` на тёмный фон для og‑image — получишь нечитаемое пятно. Скрипт это учитывает.

---

## 3. Скрипт экспорта (Pillow)

Положи свои 4 PNG в папку `assets_raw/` с именами из таблицы выше. Затем:

```bash
pip install pillow
python export_branding.py
```

```python
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
```

### Что скрипт делает хорошо, а что — черновик

| Результат | Статус |
|---|---|
| `icon-512/192/1024`, `icon-maskable-512` | ✅ готово к загрузке |
| `feature-graphic-1024x500`, `og-cover-1200x630` | ✅ готово (светлый фон под твой wordmark) |
| `logo-horizontal.png` для сайта/README | ✅ готово |
| `adaptive-bg-*` | ✅ готово |
| `adaptive-fg-*` | ⚠️ черновик: если у `mark.png` не было прозрачности, белый фон вырезан порогом — возможны ореолы. Финальный foreground попроси отдельным экспортом **на прозрачности** |
| `favicon-mono-16/32` | ⚠️ черновик из грейскейла. Для продакшена нужен отдельный чистый плоский монохром (в брендбуке есть блок «03 МОНОХРОМНАЯ ВЕРСИЯ» — возьми его исходником, а не мой пересчёт) |

Вывод `favicon-512`/`icon-1024` в 16px из сложного градиента **всегда** будет нечитаем — это не баг скрипта, а свойство детализированного знака. Поэтому для мелких размеров и существует монохромная адаптация.

---

## 4. Патчи сайта под твою палитру и слоган

Твой `index.html` из прошлого шага был на оранжевой палитре. Меняем точечно — не переписываем весь файл.

### 4.1. Замени блок `:root` и тёмную тему

```css
:root {
  color-scheme: light dark;
  --bg: #ffffff;
  --fg: #0B1A3C;
  --muted: #5A6478;
  --card: #F4F6FA;
  --accent: #0A3BFF;     /* электрический синий */
  --accent-2: #B7FF00;   /* лайм */
  --accent-3: #00E5FF;   /* циан */
  --border: #E1E6EF;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0B1A3C;
    --fg: #F4F6FA;
    --muted: #AEB8CC;
    --card: #11224A;
    --accent: #3D6BFF;
    --accent-2: #B7FF00;
    --accent-3: #00E5FF;
    --border: #1E3366;
  }
}
```

### 4.2. Кнопки и бейджи — двойной акцент (синий + лайм)

```css
.btn-primary {
  background: linear-gradient(135deg, var(--accent) 0%, var(--accent-3) 100%);
  color: #ffffff;
}
.btn-primary:hover { filter: brightness(1.08); }

.badge {
  border: 1px solid var(--border);
  background: var(--card);
  color: var(--fg);
}
.badge.hot {                 /* для «офлайн / без данных» */
  border-color: var(--accent-2);
  color: var(--fg);
  background: color-mix(in srgb, var(--accent-2) 14%, var(--card));
}
```

И в hero поменяй бейджи на «горячие»:

```html
<span class="badge hot">Офлайн</span>
<span class="badge hot">Без рекламы</span>
<span class="badge hot">Без аналитики</span>
<span class="badge">Открытый код</span>
<span class="badge">Данные на устройстве</span>
```

### 4.3. Hero: логотип + слоган из брендбука

Вставь над `<h1>` горизонтальный логотип и добавь слоган под lead. Слоган «БОЛЬШЕ ДВИЖЕНИЯ В ТВОЕЙ ЖИЗНИ» — безопасный: не медицинский, не обещает похудение/здоровье, поэтому его можно и в сайт, и в store listing.

```html
<img src="assets/branding/logo-horizontal.png"
     alt="ДВИЖ" width="320" height="96"
     style="display:block;margin-bottom:20px;">

<h1>Движ — офлайн счётчик активности</h1>
<p class="lead">Больше движения в твоей жизни.<br>
Локальный учёт ходьбы, бега и зарядки. Без сервера, без аккаунта,
без рекламы, без аналитики и без отправки данных.</p>
```

### 4.4. Мета‑теги и иконки — обнови пути

```html
<link rel="icon" href="assets/branding/favicon-mono-32.png" sizes="32x32">
<link rel="icon" href="assets/branding/favicon-512.png" sizes="512x512">
<link rel="apple-touch-icon" href="assets/branding/apple-touch-icon-180.png">
<meta name="theme-color" content="#0B1A3C">

<meta property="og:image" content="https://duckolly.github.io/dvizh/assets/branding/og-cover-1200x630.png">
<meta name="twitter:image" content="https://duckolly.github.io/dvizh/assets/branding/og-cover-1200x630.png">
```

### 4.5. Заголовки — имитация жирного курсива wordmark

Чтобы сайт визуально совпадал с логотипом, но **без внешних CDN‑шрифтов** (сохраняем приватность/офлайн‑дух проекта):

```css
h1, h2, .brand {
  font-style: italic;
  font-weight: 800;
  letter-spacing: -0.02em;
}
```

Если захочешь точное совпадение со шрифтом логотипа — положи `.woff2` локально в `assets/fonts/` и подключи через `@font-face` **без CDN**. Тянуть шрифт с Google Fonts нельзя: это внешний запрос, который противоречит твоему «no trackers» и усложнит Data Safety.

---

## 5. Структура папок после экспорта

```text
dvizh/
├── assets_raw/                 # ТВОИ исходники, в git не коммитить если большие
│   ├── icon.png
│   ├── wordmark.png
│   ├── brandbook.png
│   └── mark.png
├── assets/branding/            # сгенерировано скриптом, это и публикуем
│   ├── icon-512.png
│   ├── icon-maskable-512.png
│   ├── feature-graphic-1024x500.png
│   ├── og-cover-1200x630.png
│   ├── logo-horizontal.png
│   ├── adaptive-fg-432.png
│   ├── adaptive-bg-432.png
│   ├── favicon-mono-16.png
│   ├── favicon-mono-32.png
│   ├── favicon-512.png
│   └── apple-touch-icon-180.png
├── index.html
├── privacy.html
└── ...
```

В `.gitignore` добавь `assets_raw/`, если исходники тяжёлые или не хочешь их публично; сгенерированные ассеты из `assets/branding/` коммить можно и нужно — они и есть публичный бренд.

---

## 6. Три честных риска, которые надо закрыть до «лейбла» и Google Play

Это не придирки, а инженерные находки именно по твоим картинкам.

1. **AI‑артефакты в знаке.** На `wordmark` и в брендбуке видны типичные следы генерации: неровные контуры букв «Ж/Х», «мыло» на монохроме, рваные градиенты. Для «просто помочь друзьям» это не критично. Но если позже захочешь **регистрировать товарный знак** или давать бренд под лицензию — AI‑растр в ряде юрисдикций не охраняется как произведение, а похожий знак мог сгенерировать кто‑то ещё. Решение на будущее: перерисовать знак в **векторе** по мотивам (чистые кривые, идеальное масштабирование, однозначные права). Код приложения при этом спокойно живёт под MIT/Apache, а бренд — отдельно (см. `BRAND_LICENSE.md` из прошлого шага).

2. **Брендбук обещает больше, чем делает v3.2.0.** В блоке «05 КЛЮЧЕВЫЕ АССОЦИАЦИИ» у тебя заявлены «ЛЮДИ И СООБЩЕСТВО» и «ГОРОД И ВОЗМОЖНОСТИ». Но текущая версия — локальная, без сервера, без соцфункций, без геолокации. Если эти ассоциации попадут в store listing или в описание, получится **противоречие с Data Safety** («no social features», «no location») и почва для жалоб/отказа. Правило: в маркетинге v3.2.0 используем только «движение / энергия / прогресс / вдохновение в каждом дне» и слоган «больше движения в твоей жизни». «Сообщество/город» — это roadmap‑вперёд, не текст магазина сейчас.

3. **Монохром и мелкие размеры.** `mark.png`/`icon.png` — детализированный градиентный знак. В 16px (favicon, уведомление, список приложений) он превратится в грязное пятно. Поэтому в скрипте я развёл: цветной знак → от 32px и выше; для 16/32 и для печати/чёрного фона → отдельная плоская монохромная адаптация (в брендбуке она есть как блок 03 — возьми её исходником, а не мой пересчёт из грейскейла).

---

## 7. Кратко по каналам

К постам, которые я давал в прошлом шаге, прикладывай каруселью: `icon.png` (иконка) → `wordmark.png` (логотип) → `brandbook.png` (лист с палитрой и ассоциациями, без спорных «сообщество/город» в подписи). Ссылки в тексте — на `https://duckolly.github.io/dvizh/` и `https://github.com/Duckolly/dvizh`. Публиковать за тебя я по‑прежнему не могу — это твои каналы и твой аккаунт.

---

## Итог

- Сопоставил 4 ассета по назначениям, включая «не резанные» `mark`/`wordmark`.
- Дал скрипт экспорта **без обрезки** (letterbox на брендовый фон), покрывающий иконку, maskable, feature graphic, og, adaptive foreground/background, favicon, apple‑touch.
- Пометил, что自适应 foreground и монохром‑favicon — черновики, финал требует чистого экспорта с альфой и отдельного монохрома.
- Залатил сайт под твою палитру `#0A3BFF / #B7FF00 / #00E5FF / #0B1A3C` и слоган, без внешних шрифтов.
- Подсветил 3 реальных риска: AI‑артефакты для будущего бренда, конфликт брендбука с офлайн‑версией в store listing, нечитаемость знака в мелких размерах.

Следующим шагом могу: (а) собрать `BRAND_LICENSE.md` + точный `android/app/src/main/res/mipmap-*/` расклад под adaptive icon из сгенерированных `adaptive-fg/bg`; (б) сделать feature‑graphic‑вариант на тёмном фоне, если захочешь тёмную витрину (тогда wordmark нужно брать светлой версией — уточни, есть ли у тебя белый логотип); (в) подготовить SEO‑описание и alt‑тексты под новую палитру. Что из этого?