
Да — сделаю **3 варианта логотипа отдельными картинками**.  
Честно: я не могу прикрепить сюда PNG/JPG-файлы, но могу дать **готовые векторные изображения в формате SVG**. SVG — это полноценная картинка: сохрани каждый блок как отдельный `.svg`-файл, открой в браузере — и получишь логотип. Потом при желании легко экспортировать в PNG 512×512 для Google Play / сайта.

Ниже — 3 варианта:

1. **Волна активности** — современный минимализм, хорошо для иконки.
2. **Приватный трекер** — щит + линия движения, подчёркивает offline / privacy.
3. **Комбинированный логотип с названием** — для сайта, GitHub README, постов.

---

## Фирменные цвета

Рекомендую зафиксировать палитру:

```text
Orange primary: #FF7A00
Orange light:   #FF9A3D
Orange dark:    #FF6A00
Dark:           #111111
White:          #FFFFFF
Gray text:      #6B6B6B
```

---

# Вариант 1. «Волна активности»

Сохранить как:

```text
logo-01-wave.svg
```

Это основной вариант для иконки приложения. Тёмный квадрат, оранжевая линия движения, белая точка — просто, узнаваемо, без текста.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512" role="img" aria-label="Dvizh logo wave">
  <defs>
    <linearGradient id="waveGradient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FF9A3D"/>
      <stop offset="1" stop-color="#FF6A00"/>
    </linearGradient>
  </defs>

  <rect width="512" height="512" rx="112" fill="#111111"/>

  <path
    d="M86 322 C162 202 238 410 318 286 C356 228 392 206 430 194"
    fill="none"
    stroke="url(#waveGradient)"
    stroke-width="42"
    stroke-linecap="round"
  />

  <circle cx="430" cy="194" r="38" fill="#FFFFFF"/>
  <circle cx="86" cy="322" r="22" fill="#FF7A00"/>
</svg>
```

### Для чего использовать
- иконка Android-приложения;
- favicon сайта;
- аватар репозитория;
- основа для feature graphic в Google Play.

---

# Вариант 2. «Приватный трекер»

Сохранить как:

```text
logo-02-privacy-step.svg
```

Этот вариант сильнее передаёт идею: **локальность, приватность, безопасность данных**. Щит + внутренняя линия активности.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512" role="img" aria-label="Dvizh privacy step logo">
  <rect width="512" height="512" rx="112" fill="#FF7A00"/>

  <path
    d="M256 86 L392 136 V256 C392 346 330 404 256 432 C182 404 120 346 120 256 V136 Z"
    fill="none"
    stroke="#FFFFFF"
    stroke-width="28"
    stroke-linejoin="round"
  />

  <path
    d="M180 286 C214 236 246 330 282 260 C304 216 326 214 344 220"
    fill="none"
    stroke="#FFFFFF"
    stroke-width="28"
    stroke-linecap="round"
  />

  <circle cx="344" cy="220" r="18" fill="#FFFFFF"/>
</svg>
```

### Для чего использовать
- как альтернативная иконка;
- для раздела Privacy Policy на сайте;
- для постов, где важно подчеркнуть: «без сбора данных»;
- для бейджа «offline / privacy first».

---

# Вариант 3. «Логотип с названием Движ»

Сохранить как:

```text
logo-03-wordmark.svg
```

Это горизонтальный логотип для сайта, README, презентаций и соцсетей.  
В нём есть иконка, название «Движ» и подпись `offline activity tracker`.

Важно: в этом SVG используется системный шрифт. Для финального публичного бренда потом лучше перевести текст в кривые / outlines, чтобы логотип выглядел одинаково везде.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 256" width="900" height="256" role="img" aria-label="Dvizh offline activity tracker logo">
  <style>
    .name {
      fill: #111111;
      font-family: Inter, "Segoe UI", Roboto, Arial, Helvetica, sans-serif;
      font-size: 112px;
      font-weight: 800;
      letter-spacing: -3px;
    }

    .tag {
      fill: #6B6B6B;
      font-family: Inter, "Segoe UI", Roboto, Arial, Helvetica, sans-serif;
      font-size: 34px;
      font-weight: 600;
      letter-spacing: 1px;
    }

    @media (prefers-color-scheme: dark) {
      .name {
        fill: #F5F5F5;
      }

      .tag {
        fill: #B0B0B0;
      }
    }
  </style>

  <rect x="16" y="16" width="224" height="224" rx="56" fill="#111111"/>

  <path
    d="M56 154 C92 100 128 190 164 132 C184 98 204 92 220 88"
    fill="none"
    stroke="#FF7A00"
    stroke-width="22"
    stroke-linecap="round"
  />

  <circle cx="220" cy="88" r="18" fill="#FFFFFF"/>

  <text class="name" x="276" y="164">Движ</text>
  <text class="tag" x="280" y="210">offline activity tracker</text>
</svg>
```

### Для чего использовать
- шапка сайта;
- GitHub README;
- посты в Telegram / VK;
- презентации для архитектора / руководства;
- store listing graphics, если нужен горизонтальный бренд.

---

# Как быстро сохранить эти логотипы в файлы

## Вариант для Linux / macOS / Git Bash

Выполни в папке проекта:

```bash
cat > logo-01-wave.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512" role="img" aria-label="Dvizh logo wave">
  <defs>
    <linearGradient id="waveGradient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FF9A3D"/>
      <stop offset="1" stop-color="#FF6A00"/>
    </linearGradient>
  </defs>

  <rect width="512" height="512" rx="112" fill="#111111"/>

  <path
    d="M86 322 C162 202 238 410 318 286 C356 228 392 206 430 194"
    fill="none"
    stroke="url(#waveGradient)"
    stroke-width="42"
    stroke-linecap="round"
  />

  <circle cx="430" cy="194" r="38" fill="#FFFFFF"/>
  <circle cx="86" cy="322" r="22" fill="#FF7A00"/>
</svg>
EOF
```

Аналогично можно сохранить второй и третий. Но проще просто скопировать каждый SVG-блок в отдельный файл через любой редактор.

---

# Как получить PNG для Google Play

Google Play обычно требует иконку приложения в размере:

```text
512 × 512 px
```

Лучше использовать **Вариант 1** или **Вариант 2**.

Если у тебя установлен `rsvg-convert`:

```bash
rsvg-convert -w 512 -h 512 logo-01-wave.svg -o dvizh-icon-512.png
```

Если установлен ImageMagick:

```bash
magick logo-01-wave.svg -resize 512x512 dvizh-icon-512.png
```

Если нет инструментов — просто открой SVG в браузере, сделай скриншот квадратной области и обрежь до 512×512. Для чернового размещения этого достаточно.

---

# Где положить логотипы в проекте

Рекомендую такую структуру:

```text
dvizh/
├── assets/
│   └── branding/
│       ├── logo-01-wave.svg
│       ├── logo-02-privacy-step.svg
│       ├── logo-03-wordmark.svg
│       ├── dvizh-icon-512.png
│       └── og-cover.png
├── docs/
│   └── privacy.html
├── index.html
├── README.md
└── PRIVACY.md
```

---

# Какой вариант я рекомендую как основной

Для приложения «Движ» я бы выбрал:

## Основной логотип / иконка
**Вариант 1 — «Волна активности»**

Почему:
- проще;
- лучше читается в маленьком размере;
- выглядит как современный fitness / activity tracker;
- не перегружен смыслом;
- хорошо масштабируется.

## Дополнительный знак для privacy-сообщения
**Вариант 2 — «Приватный трекер»**

Почему:
- хорошо подходит для сайта и постов;
- визуально говорит: «данные защищены, локально, без отправки»;
- полезен как отдельный бейдж в разделе Privacy.

## Для сайта и README
**Вариант 3 — «Логотип с названием»**

Почему:
- сразу видно название;
- подходит для шапки сайта;
- хорошо смотрится в соцсетях и документации.

---

# Важное замечание по правам

Эти SVG-исходники ты можешь использовать в своём проекте как автор логотипов, раз ты владелец идеи и кода.  
Но для публичного бренда я бы рекомендовал:

1. оставить у себя исходники SVG;
2. не отдавать их под MIT как «бренд», если позже захочешь защищать название/логотип;
3. код приложения можно публиковать под MIT / Apache-2.0;
4. логотип и название можно отдельно пометить как brand assets.

Например, в репозитории можно сделать так:

```text
LICENSE              — для кода приложения
BRAND_LICENSE.md     — для логотипов и названия
```

Черновик `BRAND_LICENSE.md`:

```markdown
# Brand Assets License

The source code of Dvizh is licensed under the MIT License.

However, the name “Dvizh”, logos, icons, and brand assets are provided for use in connection with the official Dvizh project.

You may use these assets to:
- promote the official project;
- contribute to the project;
- build the app from source for personal or testing purposes.

You may not:
- present modified apps as the official Dvizh product;
- use the brand assets in a way that implies endorsement by the maintainer;
- register the name or logos as your own trademark.

Maintainer: Sergey Shvetsov
Repository: https://github.com/Duckolly/dvizh
```

---

# Итог

Я подготовил **3 отдельных логотипа в SVG**:

1. `logo-01-wave.svg` — основная иконка.
2. `logo-02-privacy-step.svg` — privacy-вариант.
3. `logo-03-wordmark.svg` — логотип с названием для сайта и README.

Если хочешь, следующим сообщением я могу сделать ещё:

- **круглую версию логотипа** для аватарок;
- **монохромный чёрно-белый вариант**;
- **feature graphic 1024×500 для Google Play**;
- **favicon набор: 16×16, 32×32, 180×180, 512×512**;
- **официальный `BRAND_LICENSE.md` и структуру репозитория для публикации на GitHub**.