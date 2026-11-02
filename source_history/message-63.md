
Собрал пункт (а). Сразу честная рамка, чтобы потом не было сюрпризов на сборке:

- Я **не могу положить файлы в твой репозиторий и не могу собрать APK** — вижу ассеты только как картинки в сообщении. Даю `BRAND_LICENSE.md`, точную раскладку папок, XML-адаптеры и скрипт нарезки, который ты запускаешь локально.
- Adaptive icon **валидируется только сборкой и запуском на устройстве API 26+**. Ниже дам команды проверки, но «зелёный свет» поставишь ты.
- По фонy иконки принял решение **по брендбуку, а не по hero-превью**: в блоке 04 палитры и в блоке 02 «иконка приложения» фон зафиксирован как сплошной тёмно-синий `#0B1A3C`. Градиент/блики на первом изображении — это декоративный рендер, не спецификация. Поэтому адаптивный фон = сплошной `#0B1A3C` (совпадает со сгенерированным `adaptive-bg`). Если захочешь вернуть градиент — нужен отдельный чистый bg-ассет без знака, рецепт дал в примечаниях.

---

## 1. `BRAND_LICENSE.md`

Кладём в корень репозитория. Смысл: **код под MIT, бренд — нет**. Это разделение важно, иначе MIT на весь репо формально отдаёт и логотип всем, включая тех, кто клонирует и выдаёт форк за «официальный Движ».

```markdown
# Brand Assets License — Движ / Dvizh

This file governs the **brand assets** of the Dvizh project: the name
“Движ” / “Dvizh”, the logo, the icon, the symbol/mark, the wordmark,
the slogan, and all files under `assets/branding/` and
`android/app/src/main/res/mipmap-*` / `drawable-*/ic_launcher_*`.

The **source code** of the application is licensed separately under the
MIT License. See `LICENSE`. This file does **not** apply to source code.

Maintainer: Sergey Shvetsov
Repository: https://github.com/Duckolly/dvizh
Effective date: 2026-10-31

## You MAY

- Use the brand assets to promote the official Dvizh project.
- Use them when contributing code, issues, or documentation to the project.
- Build the app from source for personal, educational, or testing purposes
  and display the brand assets within that build.
- Reference the project by name and logo in articles, reviews, and talks
  about the official project.

## You MUST NOT

- Present a modified or forked app as the official Dvizh product.
- Use the brand assets in a way that implies endorsement, affiliation, or
  approval by the maintainer.
- Register “Движ”, “Dvizh”, the logo, or the mark as your own trademark,
  design mark, or company name.
- Sell, sublicense, or commercially exploit the brand assets without prior
  written permission from the maintainer.
- Remove or alter attribution and license notices in redistributed brand
  assets.

## Provenance and IP caveat (read this)

The current brand assets are raster graphics. Some elements may have been
produced with the assistance of generative AI tools. As of the effective
date, the maintainer has not registered the mark as a trademark and has not
yet converted the logo to clean vector outlines.

Consequences you should understand:

- Trademark/design-mark protection may be limited or unavailable until
  registration and/or vector conversion.
- A visually similar symbol could, in principle, be produced independently
  by others.
- The maintainer intends to migrate the brand to vector form and, if
  desired, pursue formal registration; until then, downstream users rely
  on these assets at their own IP risk.

This section is a factual disclosure, not legal advice. For commercial use
of the brand, obtain written permission and, if needed, independent legal
review.

## Dual-license summary

| Asset type            | License                          |
|-----------------------|----------------------------------|
| Application source    | MIT (`LICENSE`)                  |
| Brand assets          | This Brand Assets License        |
| Third-party fonts/SDK | Per their own licenses           |

Questions about brand usage: open an issue in the repository or contact
the maintainer via the method listed there.
```

В `README.md` добавь одну строку-указатель, чтобы никто не спутал лицензии:

```markdown
## License
Source code: MIT (see `LICENSE`).
Brand assets (logo, name, icons): see `BRAND_LICENSE.md`.
```

---

## 2. Точная раскладка папок (после нарезки)

Всё живёт под `android/app/src/main/res/`. Слои адаптивной иконки — в `drawable-*` (канон Android), legacy-растры — в `mipmap-*`, XML-адаптеры — в `mipmap-anydpi-v26/`.

```text
android/app/src/main/res/
├── mipmap-anydpi-v26/
│   ├── ic_launcher.xml            # адаптер (круг/квадрат/капля)
│   └── ic_launcher_round.xml      # адаптер для round-слота
│
├── drawable-mdpi/
│   ├── ic_launcher_foreground.png # 108 px
│   └── ic_launcher_background.png # 108 px, сплошной #0B1A3C
├── drawable-hdpi/      # 162 px  (то же имя файлов)
├── drawable-xhdpi/     # 216 px
├── drawable-xxhdpi/    # 324 px
├── drawable-xxxhdpi/   # 432 px
│
├── mipmap-mdpi/
│   ├── ic_launcher.png            # 48 px  legacy (< API 26)
│   └── ic_launcher_round.png      # 48 px
├── mipmap-hdpi/      # 72 px
├── mipmap-xhdpi/     # 96 px
├── mipmap-xxhdpi/    # 144 px
└── mipmap-xxxhdpi/   # 192 px
```

Почему слои в `drawable`, а не в `mipmap`: `mipmap` зарезервирован под иконки запуска с dpi-вариациями и под legacy; адаптивные слои по официальной конвенции Android — `drawable`. Flutter прокидывает `res/` в Android-сборку как есть, так что это работает и в Flutter-проекте. Если в шаблоне уже лежат `mipmap-*/ic_launcher_foreground.png` — удали их, чтобы не плодить неиспользуемые ресурсы (см. шаг 5).

---

## 3. XML-адаптеры

### `mipmap-anydpi-v26/ic_launcher.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />

    <!--
      OPT-IN: themed / monochrome icons (Android 13+, API 33).
      Раскомментируй ТОЛЬКО если положил drawable/ic_launcher_monochrome
      во ВСЕ плотности (mdpi..xxxhdpi), иначе сборка упадёт на отсутствующем ресурсе.
      Чистый монохром бери из блокa «03 МОНОХРОМНАЯ ВЕРСИЯ» брендбука,
      а не из моего грейскейл-черновика.
    -->
    <!-- <monochrome android:drawable="@drawable/ic_launcher_monochrome" /> -->
</adaptive-icon>
```

### `mipmap-anydpi-v26/ic_launcher_round.xml`

Содержимое идентично (Android требует отдельный файл для round-слота):

```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <!-- <monochrome android:drawable="@drawable/ic_launcher_monochrome" /> -->
</adaptive-icon>
```

### Проверка в `AndroidManifest.xml`

Убедись, что в `<application>` есть обе ссылки (Flutter-шаблон обычно даёт `icon`, но `roundIcon` иногда отсутствует — добавь, иначе часть лаунчеров не возьмёт round-адаптер):

```xml
<application
    android:label="Движ"
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round"
    ... >
```

### Лёгкая альтернатива растровому фону

Так как фон сплошной `#0B1A3C`, его можно не резать по плотностям, а задать цветом — меньше байт в APK и ноль риска blur. В `res/values/colors.xml`:

```xml
<resources>
    <color name="ic_launcher_background">#0B1A3C</color>
</resources>
```

И в адаптерах заменить строку background на:

```xml
<background android:drawable="@color/ic_launcher_background" />
```

Тогда папки `drawable-*/ic_launcher_background.png` не нужны. Я по умолчанию оставил растровый вариант (ты просил «из adaptive-bg»), но этот путь чище — выбирай сам.

---

## 4. Скрипт нарезки всех плотностей

Сохраняй как `export_adaptive_icons.py`. Читает то, что уже сгенерировал прошлый `export_branding.py` (`adaptive-fg-432`, `adaptive-bg-432` в `assets/branding/`) плюс `icon.png` в `assets_raw/`, и раскладывает по `android/app/src/main/res/`. Safe-zone уже заложена в `adaptive-fg-432` (pad 0.17 от прошлого шага), поэтому даунскейл корректен.

```python
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
```

Запуск:

```bash
pip install pillow
python export_adaptive_icons.py
```

Скрипт не трогает `mipmap-anydpi-v26/*.xml` — их ты создаёшь из шага 3 (текст фиксированный, генерить бессмысленно).

---

## 5. Уборка старого шаблона и проверка сборки

Первой сборкой после нарезки удали конфликтующие/лишние файлы из шаблона Flutter, если они есть (чтобы не осталось «двойных» foreground в mipmap):

```bash
# посмотрим, что лежит в mipmap-*/ кроме наших ic_launcher / ic_launcher_round
find android/app/src/main/res/mipmap-* -type f \
  ! -name ic_launcher.png ! -name ic_launcher_round.png
```

Если вывод показывает `ic_launcher_foreground.png` / `ic_launcher_background.png` внутри `mipmap-*` — удали их (наши слои теперь в `drawable-*`, и XML ссылается на `@drawable/...`):

```bash
find android/app/src/main/res/mipmap-* -type f \
  \( -name ic_launcher_foreground.png -o -name ic_launcher_background.png \) -delete
```

Затем полная проверка:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug
```

Визуальная проверка адаптивности (главное — увидеть, что лаунчер маскирует слой, а не показывает квадрат):

```bash
flutter install
# на устройстве API 26+ посмотри иконку в лаунчере:
# она должна обрезаться под форму маски (круг/капля/squircle),
# а знак не должен залезать под срез => safe-zone из pad 0.17 отработала.
```

Если на эмуляторе/устройстве API < 26 — увидишь legacy `mipmap-*/ic_launcher.png` (это ожидаемо, адаптер там не применяется).

---

## 6. Known issues, которые я обязан назвать, а не замазать

1. **Legacy на старых Android (< 26) может иметь светлые уголки.** `icon.png` — скруглённый квадрат; если у него непрозрачный светлый фон по углам, на API < 26 (где система не маскирует) будет квадрат с белыми уголками. Для MVP терпимо. Фикс, если захочешь чистоты: экспортируй `icon` на прозрачности или на сплошном `#0B1A3C`-холсте 108dp и режь legacy уже из него (тогда в скрипте замени `LEGACY_MASTER` на этот файл).
2. **Монохром/themed-иконка выключена по умолчанию.** Тег `<monochrome>` закомментирован, потому что честного плоского монохрома у нас нет (мой грейскейл — черновик). Включай только когда возьмёшь блок «03 МОНОХРОМНАЯ ВЕРСИЯ» брендбука как отдельный ассет с альфой и нарежешь `drawable-*/ic_launcher_monochrome.png` по всем плотностям — иначе билд упадёт.
3. **Градиентный фон hero-превью не перенесён в адаптер.** Осознанно, по палитре брендбука. Если решишь вернуть градиент — нужен чистый bg-ассет без знака (сгенерируй/попроси отдельно), и тогда `BG_MASTER` указывает на него, а не на сплошной `adaptive-bg-432`.
4. **Я не проверял резолвинг `@drawable` vs `@mipmap` на твоём конкретном шаблоне Flutter.** Канон — `drawable` для слоёв, и я на него завязал XML. Если после `flutter build` получишь ошибку вида «resource ic_launcher_foreground not found», значит в твоём шаблоне XML всё ещё ссылается на `@mipmap/...` — тогда либо переложи слои в `mipmap-*` и поправь ссылки в XML на `@mipmap/`, либо (правильнее) приведи XML к шагу 3. Это единственное место, где моя раскладка может разойтись с кастомным шаблоном; лечится одной правкой ссылок.

---

## Итог по (а)

- `BRAND_LICENSE.md` — бренд отделён от MIT-кода, с честным дисклеймером про AI-происхождение и отсутствие регистрации знака.
- Точная раскладка `drawable-*/` (слои) + `mipmap-*/` (legacy) + `mipmap-anydpi-v26/` (адаптеры).
- Два XML-адаптера + opt-in монохром + проверка `roundIcon` в манифесте + альтернатива фоном через `colors.xml`.
- `export_adaptive_icons.py` режет все 5 плотностей из уже сгенерированных `adaptive-fg/bg` и `icon.png`, без обрезки композиции.
- Команды уборки шаблона и сборки, и 4 known-issue пункта.

Статус всего этого — **CODE_READY / CONFIG_READY**, не `VERIFIED`: финальное «иконка круглая, знак в safe-zone, билд зелёный» даст только твой `flutter build` + запуск на устройстве API 26+.

Дальше по списку остались (б) feature-graphic на тёмном фоне (нужен светлый вариант wordmark — уточни, есть ли) и (в) SEO/alt-тексты под новую палитру. Скажи, что берём следующим, или гони вывод `flutter build apk --debug` после нарезки — разберу ошибки построчно, если что-то из пункта 6.4 стрельнет.