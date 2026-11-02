
Да — могу подготовить **готовый одностраничный сайт** для рекламы приложения и для передачи информации в Google / Google Play.  
Но честно зафиксирую: **я не могу сам опубликовать сайт или разместить его в каналах**, потому что у меня нет доступа к публикации в интернете и социальным сетям. Ниже даю файлы, которые ты сможешь залить, например, на GitHub Pages, и готовые тексты для Google Play / постов.

Я сделал упор на то, чтобы сайт был:

- **без внешних трекеров**;
- **без рекламы**;
- **без аналитики**;
- **без JavaScript-зависимостей**;
- **понятным для Google Play и Google Search**;
- **с разделом Privacy Policy**;
- **с медицинским дисклеймером**;
- **с информацией для модерации**.

---

# 1. Главный файл сайта: `index.html`

Создай файл `index.html` и вставь туда этот код.

```html
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>Движ — офлайн счётчик активности без рекламы и аналитики</title>
  <meta name="description" content="Движ — локальное Android-приложение для учёта ходьбы, бега и зарядки. Без сервера, без аккаунта, без рекламы, без аналитики, без отправки данных.">
  <meta name="author" content="Sergey Shvetsov">
  <meta name="robots" content="index, follow">
  <meta name="theme-color" content="#ff7a00">

  <link rel="canonical" href="https://duckolly.github.io/dvizh/">

  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Движ">
  <meta property="og:title" content="Движ — офлайн счётчик активности">
  <meta property="og:description" content="Локальный учёт шагов и тренировок. Без интернета, рекламы и сбора персональных данных.">
  <meta property="og:url" content="https://duckolly.github.io/dvizh/">
  <meta property="og:image" content="https://duckolly.github.io/dvizh/og-cover.png">
  <meta property="og:locale" content="ru_RU">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Движ — офлайн счётчик активности">
  <meta name="twitter:description" content="Локальный учёт шагов и тренировок. Без интернета, рекламы и сбора персональных данных.">
  <meta name="twitter:image" content="https://duckolly.github.io/dvizh/og-cover.png">

  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "name": "Движ",
    "applicationCategory": "LifestyleApplication",
    "operatingSystem": "Android",
    "softwareVersion": "3.2.0",
    "datePublished": "2026-10-31",
    "url": "https://duckolly.github.io/dvizh/",
    "sameAs": "https://github.com/Duckolly/dvizh",
    "author": {
      "@type": "Person",
      "name": "Sergey Shvetsov",
      "url": "https://github.com/Duckolly"
    },
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "RUB"
    },
    "description": "Движ — офлайн-приложение для локального учёта физической активности. Считает шаги через датчик движения устройства, хранит историю только на телефоне и не отправляет данные на сервер.",
    "featureList": [
      "Офлайн-режим",
      "Локальное хранение данных",
      "Подсчёт шагов через датчик движения",
      "Выбор типа активности",
      "История тренировок",
      "Очистка истории",
      "Удаление всех данных",
      "Переключатель записи",
      "Переключатель уведомлений",
      "Тёмная тема",
      "Без рекламы",
      "Без аналитики",
      "Без сервера"
    ]
  }
  </script>

  <style>
    :root {
      color-scheme: light dark;
      --bg: #ffffff;
      --fg: #111111;
      --muted: #555555;
      --card: #f6f6f7;
      --accent: #ff7a00;
      --border: #dddddd;
    }

    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #111111;
        --fg: #f2f2f2;
        --muted: #aaaaaa;
        --card: #1b1b1d;
        --border: #333333;
      }
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      margin: 0;
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
      background: var(--bg);
      color: var(--fg);
      line-height: 1.55;
    }

    a {
      color: var(--accent);
    }

    .container {
      width: min(980px, 92vw);
      margin: 0 auto;
    }

    header {
      position: sticky;
      top: 0;
      background: var(--bg);
      border-bottom: 1px solid var(--border);
      z-index: 10;
    }

    nav {
      display: flex;
      gap: 16px;
      align-items: center;
      justify-content: space-between;
      padding: 12px 0;
      flex-wrap: wrap;
    }

    .brand {
      font-weight: 800;
      font-size: 20px;
      text-decoration: none;
      color: inherit;
    }

    .links {
      display: flex;
      gap: 14px;
      flex-wrap: wrap;
    }

    .links a {
      color: var(--muted);
      text-decoration: none;
      font-weight: 600;
    }

    .links a:hover {
      color: var(--accent);
    }

    main {
      padding: 32px 0 64px;
    }

    .hero {
      padding: 48px 0 28px;
    }

    h1 {
      font-size: clamp(34px, 7vw, 64px);
      line-height: 1.05;
      margin: 0 0 16px;
      letter-spacing: -0.03em;
    }

    h2 {
      font-size: clamp(28px, 5vw, 42px);
      margin: 0 0 18px;
      letter-spacing: -0.02em;
    }

    h3 {
      margin: 0 0 8px;
      font-size: 20px;
    }

    .lead {
      font-size: clamp(18px, 2.5vw, 24px);
      color: var(--muted);
      max-width: 760px;
      margin: 0 0 24px;
    }

    .badges {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      margin-bottom: 28px;
    }

    .badge {
      border: 1px solid var(--border);
      background: var(--card);
      padding: 8px 12px;
      border-radius: 999px;
      font-weight: 700;
      font-size: 14px;
    }

    .cta {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 48px;
      padding: 12px 18px;
      border-radius: 14px;
      text-decoration: none;
      font-weight: 800;
      border: 1px solid transparent;
    }

    .btn-primary {
      background: var(--accent);
      color: #ffffff;
    }

    .btn-secondary {
      border-color: var(--border);
      color: inherit;
      background: var(--card);
    }

    .section {
      padding: 42px 0;
      border-top: 1px solid var(--border);
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
    }

    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 18px;
    }

    .card p {
      margin: 0;
      color: var(--muted);
    }

    .steps {
      display: grid;
      gap: 12px;
    }

    .step {
      display: grid;
      grid-template-columns: 44px 1fr;
      gap: 14px;
      align-items: start;
    }

    .num {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      display: grid;
      place-items: center;
      background: var(--accent);
      color: #ffffff;
      font-weight: 900;
    }

    .list {
      margin: 0;
      padding-left: 22px;
    }

    .list li {
      margin: 8px 0;
    }

    details {
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 14px 16px;
      background: var(--card);
      margin-bottom: 10px;
    }

    summary {
      cursor: pointer;
      font-weight: 800;
    }

    .privacy-box {
      border-left: 4px solid var(--accent);
      padding: 16px;
      background: var(--card);
      border-radius: 12px;
    }

    footer {
      border-top: 1px solid var(--border);
      padding: 24px 0 40px;
      color: var(--muted);
    }

    .small {
      font-size: 14px;
    }

    .code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      font-size: 14px;
      background: var(--card);
      padding: 2px 6px;
      border-radius: 6px;
    }
  </style>
</head>

<body>
  <header>
    <div class="container">
      <nav>
        <a class="brand" href="#top">Движ</a>
        <div class="links">
          <a href="#features">Возможности</a>
          <a href="#privacy">Приватность</a>
          <a href="#faq">FAQ</a>
          <a href="#download">Скачать</a>
        </div>
      </nav>
    </div>
  </header>

  <main id="top">
    <section class="hero container">
      <h1>Движ — офлайн счётчик активности</h1>
      <p class="lead">
        Простое локальное приложение для учёта ходьбы, бега и зарядки.
        Без сервера, без аккаунта, без рекламы, без аналитики и без отправки данных.
      </p>

      <div class="badges">
        <span class="badge">Офлайн</span>
        <span class="badge">Без рекламы</span>
        <span class="badge">Без аналитики</span>
        <span class="badge">Открытый код</span>
        <span class="badge">Данные на устройстве</span>
      </div>

      <div class="cta">
        <a class="btn btn-primary" href="https://github.com/Duckolly/dvizh">
          GitHub / исходный код
        </a>
        <a class="btn btn-secondary" href="#privacy">
          Privacy Policy
        </a>
      </div>

      <p class="small" style="margin-top: 16px; color: var(--muted);">
        Google Play-ссылка будет добавлена после публикации приложения.
      </p>
    </section>

    <section id="features" class="section container">
      <h2>Что умеет приложение</h2>

      <div class="grid">
        <div class="card">
          <h3>Локальный учёт</h3>
          <p>
            История тренировок хранится только на устройстве пользователя.
            Приложение не отправляет данные на сервер.
          </p>
        </div>

        <div class="card">
          <h3>Выбор активности</h3>
          <p>
            Можно выбрать тип тренировки: ходьба, бег или зарядка.
          </p>
        </div>

        <div class="card">
          <h3>Подсчёт шагов</h3>
          <p>
            Шаги считаются через датчик движения смартфона во время активной записи.
          </p>
        </div>

        <div class="card">
          <h3>Длительность тренировки</h3>
          <p>
            Приложение показывает время записи и сохраняет результат в локальную историю.
          </p>
        </div>

        <div class="card">
          <h3>Управление данными</h3>
          <p>
            Пользователь может очистить историю или удалить все данные приложения.
          </p>
        </div>

        <div class="card">
          <h3>Переключатели</h3>
          <p>
            Можно отключить запись активности и уведомления в настройках.
          </p>
        </div>

        <div class="card">
          <h3>Тёмная тема</h3>
          <p>
            Поддерживаются светлая, тёмная и системная темы оформления.
          </p>
        </div>

        <div class="card">
          <h3>Без лишних разрешений</h3>
          <p>
            Не используются геолокация, камера, микрофон, контакты и SMS.
          </p>
        </div>
      </div>
    </section>

    <section id="how" class="section container">
      <h2>Как это работает</h2>

      <div class="steps">
        <div class="step">
          <div class="num">1</div>
          <div>
            <h3>Открой приложение</h3>
            <p>
              При первом запуске показывается экран согласия с политикой конфиденциальности
              и подтверждением возраста.
            </p>
          </div>
        </div>

        <div class="step">
          <div class="num">2</div>
          <div>
            <h3>Выбери активность</h3>
            <p>
              Выбери тип тренировки: ходьба, бег или зарядка.
            </p>
          </div>
        </div>

        <div class="step">
          <div class="num">3</div>
          <div>
            <h3>Нажми «Начать»</h3>
            <p>
              Приложение запросит доступ к датчику движения, если это необходимо,
              и начнёт локальную запись активности.
            </p>
          </div>
        </div>

        <div class="step">
          <div class="num">4</div>
          <div>
            <h3>Останови и сохрани</h3>
            <p>
              После нажатия «Стоп» тренировка сохраняется только на устройстве.
            </p>
          </div>
        </div>
      </div>
    </section>

    <section id="privacy" class="section container">
      <h2>Privacy Policy / Политика конфиденциальности</h2>

      <div class="privacy-box">
        <p><strong>Последнее обновление:</strong> 2026-10-31</p>
        <p><strong>Разработчик / maintainer:</strong> Sergey Shvetsov</p>
        <p><strong>Репозиторий:</strong> <a href="https://github.com/Duckolly/dvizh">https://github.com/Duckolly/dvizh</a></p>
      </div>

      <h3>1. Общий принцип</h3>
      <p>
        Приложение «Движ» разработано как офлайн-инструмент для локального учёта физической активности.
      </p>

      <ul class="list">
        <li>Приложение не имеет сервера.</li>
        <li>Приложение не требует регистрации.</li>
        <li>Приложение не собирает ФИО, email, номер телефона, адрес, геолокацию, вес или медицинские данные.</li>
        <li>Приложение не использует рекламу.</li>
        <li>Приложение не использует аналитику.</li>
        <li>Приложение не использует crash reporting.</li>
        <li>Приложение не отправляет данные разработчику.</li>
        <li>Приложение не отправляет данные третьим лицам автоматически.</li>
      </ul>

      <h3>2. Какие данные обрабатываются локально</h3>
      <p>
        Приложение может локально хранить на устройстве пользователя:
      </p>

      <ul class="list">
        <li>тип активности;</li>
        <li>дату и время начала тренировки;</li>
        <li>длительность тренировки;</li>
        <li>количество шагов, рассчитанное на основе датчика движения устройства.</li>
      </ul>

      <p>
        Эти данные не покидают устройство.
      </p>

      <h3>3. Разрешения</h3>

      <h4>Доступ к датчику движения</h4>
      <p>
        Приложение может запрашивать разрешение на доступ к датчикам движения,
        чтобы считать шаги во время активной тренировки, запущенной пользователем.
        Данные обрабатываются локально и не отправляются на сервер.
      </p>

      <h4>Уведомления</h4>
      <p>
        Если пользователь включил уведомления, приложение может показывать локальное
        уведомление о том, что идёт запись активности. Уведомления не используются
        для рекламы и не отправляют данные наружу.
      </p>

      <h3>4. Хранение и удаление данных</h3>
      <p>
        Все данные хранятся только на устройстве пользователя.
      </p>

      <p>Пользователь может:</p>

      <ul class="list">
        <li>очистить историю тренировок;</li>
        <li>удалить все данные приложения внутри приложения;</li>
        <li>удалить приложение, после чего операционная система удалит локальные данные приложения в соответствии со своей политикой.</li>
      </ul>

      <h3>5. Дети</h3>
      <p>
        Приложение не предназначено для детей младше 14 лет без участия родителя
        или законного представителя.
      </p>

      <h3>6. Медицинская информация</h3>
      <p>
        Приложение не является медицинским изделием. Оно не ставит диагнозы,
        не лечит, не заменяет консультацию врача и не гарантирует точность измерений.
      </p>

      <p>
        Данные о шагах и длительности активности носят информационный характер
        и могут быть неточными в зависимости от устройства, датчиков и того,
        как пользователь носит телефон.
      </p>

      <h3>7. Открытый код</h3>
      <p>
        Исходный код приложения доступен публично. Это позволяет независимым
        исследователям проверить отсутствие сетевых запросов, аналитики, рекламы
        и скрытой передачи данных.
      </p>

      <h3>8. Контакты</h3>
      <p>
        По вопросам приватности можно открыть issue в публичном репозитории
        или связаться с maintainer через контакты, указанные в репозитории.
      </p>
    </section>

    <section id="google-info" class="section container">
      <h2>Информация для Google Play и проверяющих</h2>

      <div class="grid">
        <div class="card">
          <h3>Тип приложения</h3>
          <p>
            Офлайн-трекер физической активности для локального использования.
          </p>
        </div>

        <div class="card">
          <h3>Сбор данных</h3>
          <p>
            Данные обрабатываются только на устройстве. Разработчик не получает
            пользовательские данные.
          </p>
        </div>

        <div class="card">
          <h3>Передача данных</h3>
          <p>
            Автоматическая передача данных третьим лицам отсутствует.
          </p>
        </div>

        <div class="card">
          <h3>Реклама</h3>
          <p>
            Реклама не используется.
          </p>
        </div>

        <div class="card">
          <h3>Аналитика</h3>
          <p>
            Аналитика и telemetry не используются.
          </p>
        </div>

        <div class="card">
          <h3>Crash reporting</h3>
          <p>
            Внешние сервисы отчётов о сбоях не используются.
          </p>
        </div>

        <div class="card">
          <h3>Разрешения</h3>
          <p>
            Используются только разрешения на доступ к датчику движения
            и, опционально, на локальные уведомления.
          </p>
        </div>

        <div class="card">
          <h3>Удаление данных</h3>
          <p>
            Пользователь может очистить историю и удалить все данные внутри приложения.
          </p>
        </div>
      </div>
    </section>

    <section id="faq" class="section container">
      <h2>FAQ</h2>

      <details>
        <summary>Приложение работает без интернета?</summary>
        <p>
          Да. Приложение спроектировано как офлайн-инструмент. Оно не требует
          постоянного подключения к интернету и не отправляет данные на сервер.
        </p>
      </details>

      <details>
        <summary>Собирает ли приложение персональные данные?</summary>
        <p>
          Нет. Приложение не собирает ФИО, email, телефон, адрес, геолокацию,
          вес или медицинские данные. История тренировок хранится локально.
        </p>
      </details>

      <details>
        <summary>Зачем нужен доступ к датчику движения?</summary>
        <p>
          Доступ к датчику движения используется только для подсчёта шагов
          во время активной тренировки, которую запустил пользователь.
        </p>
      </details>

      <details>
        <summary>Можно ли удалить данные?</summary>
        <p>
          Да. В приложении есть очистка истории и удаление всех данных.
          Также удаление приложения удаляет локальные данные в соответствии
          с политикой операционной системы.
        </p>
      </details>

      <details>
        <summary>Это медицинское приложение?</summary>
        <p>
          Нет. Приложение не является медицинским изделием, не ставит диагнозы,
          не лечит и не заменяет консультацию врача.
        </p>
      </details>

      <details>
        <summary>Почему шаги могут считаться неточно?</summary>
        <p>
          Точность зависит от устройства, датчиков, способа ношения телефона
          и условий использования. Приложение использует датчик движения смартфона,
          а не специализированный фитнес-трекер.
        </p>
      </details>
    </section>

    <section id="download" class="section container">
      <h2>Скачать и исходный код</h2>

      <p>
        Проект распространяется как open source. Исходный код доступен на GitHub.
      </p>

      <div class="cta">
        <a class="btn btn-primary" href="https://github.com/Duckolly/dvizh">
          Открыть репозиторий
        </a>
        <a class="btn btn-secondary" href="https://github.com/Duckolly/dvizh/issues">
          Сообщить о проблеме
        </a>
      </div>

      <p class="small" style="margin-top: 16px; color: var(--muted);">
        После публикации в Google Play здесь появится ссылка на страницу приложения.
      </p>
    </section>
  </main>

  <footer>
    <div class="container">
      <p>
        <strong>Движ</strong> — офлайн счётчик активности.
      </p>
      <p class="small">
        Автор: Sergey Shvetsov.<br>
        Репозиторий: <a href="https://github.com/Duckolly/dvizh">github.com/Duckolly/dvizh</a><br>
        Лицензия: MIT.<br>
        Приложение не является медицинским изделием.
      </p>
    </div>
  </footer>
</body>
</html>
```

---

# 2. Отдельная страница Privacy Policy: `privacy.html`

Google Play иногда лучше давать **прямую ссылку на privacy policy без якоря**.  
Поэтому рекомендую также создать файл `privacy.html`.

```html
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacy Policy — Движ</title>
  <meta name="robots" content="index, follow">
  <style>
    body {
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
      line-height: 1.6;
      max-width: 860px;
      margin: 40px auto;
      padding: 0 20px;
      color: #111;
      background: #fff;
    }

    @media (prefers-color-scheme: dark) {
      body {
        color: #f2f2f2;
        background: #111;
      }
    }

    a {
      color: #ff7a00;
    }

    h1, h2, h3 {
      line-height: 1.2;
    }

    ul {
      padding-left: 22px;
    }

    li {
      margin: 8px 0;
    }
  </style>
</head>

<body>
  <h1>Privacy Policy — Движ</h1>

  <p><strong>Last updated:</strong> 2026-10-31</p>
  <p><strong>Maintainer:</strong> Sergey Shvetsov</p>
  <p><strong>Repository:</strong> <a href="https://github.com/Duckolly/dvizh">https://github.com/Duckolly/dvizh</a></p>

  <h2>1. General principle</h2>
  <p>
    The app “Dvizh” is an offline tool for local physical activity tracking.
  </p>

  <ul>
    <li>The app has no server.</li>
    <li>The app does not require registration.</li>
    <li>The app does not collect name, email, phone number, address, location, weight, or medical data.</li>
    <li>The app does not use advertising.</li>
    <li>The app does not use analytics.</li>
    <li>The app does not use crash reporting.</li>
    <li>The app does not send data to the developer.</li>
    <li>The app does not automatically send data to third parties.</li>
  </ul>

  <h2>2. Locally processed data</h2>
  <p>
    The app may locally store on the user’s device:
  </p>

  <ul>
    <li>activity type;</li>
    <li>workout start date and time;</li>
    <li>workout duration;</li>
    <li>step count calculated from the device motion sensor.</li>
  </ul>

  <p>
    These data do not leave the device.
  </p>

  <h2>3. Permissions</h2>

  <h3>Motion sensor access</h3>
  <p>
    The app may request access to motion sensors to count steps during an active workout started by the user.
    Data are processed locally and are not sent to a server.
  </p>

  <h3>Notifications</h3>
  <p>
    If the user enables notifications, the app may show a local ongoing notification indicating that recording is active.
    Notifications are not used for advertising and do not send data outward.
  </p>

  <h2>4. Data deletion</h2>
  <p>
    All data are stored only on the user’s device.
  </p>

  <p>The user can:</p>

  <ul>
    <li>clear workout history;</li>
    <li>delete all app data inside the app;</li>
    <li>uninstall the app, after which the operating system removes local app data according to its policy.</li>
  </ul>

  <h2>5. Children</h2>
  <p>
    The app is not intended for children under 14 without involvement of a parent or legal guardian.
  </p>

  <h2>6. Medical information</h2>
  <p>
    The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease.
    Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.
  </p>

  <h2>7. Open source</h2>
  <p>
    The source code is publicly available so independent researchers can verify the absence of network requests, analytics, advertising, and hidden data transmission.
  </p>

  <p>
    <a href="index.html">Back to main page</a>
  </p>
</body>
</html>
```

---

# 3. Файл для поисковых систем: `robots.txt`

Создай файл `robots.txt` в корне сайта.

```txt
User-agent: *
Allow: /

Sitemap: https://duckolly.github.io/dvizh/sitemap.xml
```

---

# 4. Карта сайта: `sitemap.xml`

Создай файл `sitemap.xml`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://duckolly.github.io/dvizh/</loc>
    <lastmod>2026-10-31</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://duckolly.github.io/dvizh/privacy.html</loc>
    <lastmod>2026-10-31</lastmod>
    <changefreq>yearly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

---

# 5. Обложка для соцсетей и Google

Сайт ссылается на изображение:

```text
https://duckolly.github.io/dvizh/og-cover.png
```

Тебе нужно добавить файл:

```text
og-cover.png
```

Рекомендуемый размер:

```text
1200 × 630 px
```

Что можно разместить на обложке:

```text
Движ
Офлайн счётчик активности

Без рекламы
Без аналитики
Без отправки данных
```

Важно: не добавляй на обложку медицинские обещания, слова «похудение», «здоровье», «калории», «лечение», «реабилитация».

---

# 6. Как разместить сайт на GitHub Pages

Допустим, твой GitHub:

```text
https://github.com/Duckolly
```

## Шаг 1. Создай репозиторий

Название:

```text
dvizh
```

Или, если хочешь именно сайт:

```text
dvizh-site
```

## Шаг 2. Добавь файлы

В корень репозитория положи:

```text
index.html
privacy.html
robots.txt
sitemap.xml
og-cover.png
```

## Шаг 3. Включи GitHub Pages

В репозитории:

```text
Settings → Pages
```

Выбери:

```text
Source: Deploy from a branch
Branch: main / root
Save
```

## Шаг 4. Получи URL

Сайт будет доступен по адресу:

```text
https://duckolly.github.io/dvizh/
```

Если репозиторий называется `dvizh-site`, тогда:

```text
https://duckolly.github.io/dvizh-site/
```

После этого замени во всех файлах URL на актуальный.

---

# 7. Что заменить перед публикацией

В `index.html`, `privacy.html`, `robots.txt`, `sitemap.xml` проверь эти адреса:

```text
https://duckolly.github.io/dvizh/
https://duckolly.github.io/dvizh/privacy.html
https://github.com/Duckolly/dvizh
```

Если репозиторий будет называться иначе, замени ссылку.

Например:

```text
https://duckolly.github.io/dvizh-site/
```

---

# 8. Информация для Google Play Console

Ниже — готовые тексты и ответы, которые можно перенести в Google Play.

## Название приложения

Вариант 1:

```text
Движ — offline activity tracker
```

Вариант 2:

```text
Dvizh: local step tracker
```

## Короткое описание

```text
Simple offline activity tracker. No account, no internet, no ads, no analytics.
```

Русский вариант:

```text
Простой офлайн-счётчик активности. Без аккаунта, без интернета, без рекламы и без аналитики.
```

## Полное описание

Английский, лучше для Google Play:

```text
“Dvizh” is a simple offline mobile app for local physical activity tracking.

What it can do:
• choose activity type: walking, running, or workout;
• count steps using the device motion sensor;
• track workout duration;
• store history only on the device;
• let the user disable recording;
• let the user disable notifications;
• let the user clear history;
• let the user delete all local data.

Privacy:
• the app works offline;
• no registration;
• no server;
• no advertising;
• no analytics;
• no crash reporting;
• no location access;
• no camera access;
• no microphone access;
• no contacts access;
• no personal data collection;
• no automatic data sharing with the developer or third parties.

Important:
The app is not a medical device. It does not diagnose, treat, cure, or prevent any disease. Step counting and activity tracking are approximate and depend on the device, sensors, and how the phone is carried.
```

Русский вариант:

```text
«Движ» — простое офлайн-мобильное приложение для локального учёта физической активности.

Что оно умеет:
• выбирать тип активности: ходьба, бег или зарядка;
• считать шаги с помощью датчика движения смартфона;
• отслеживать длительность тренировки;
• хранить историю только на устройстве;
• позволять пользователю отключить запись;
• позволять пользователю отключить уведомления;
• позволять пользователю очистить историю;
• позволять пользователю удалить все локальные данные.

Приватность:
• приложение работает офлайн;
• без регистрации;
• без сервера;
• без рекламы;
• без аналитики;
• без crash reporting;
• без доступа к геолокации;
• без доступа к камере;
• без доступа к микрофону;
• без доступа к контактам;
• без сбора персональных данных;
• без автоматической передачи данных разработчику или третьим лицам.

Важно:
Приложение не является медицинским изделием. Оно не ставит диагнозы, не лечит, не предотвращает заболевания и не заменяет консультацию врача. Подсчёт шагов и учёт активности приблизительны и зависят от устройства, датчиков и того, как пользователь носит телефон.
```

## Privacy policy URL

Используй:

```text
https://duckolly.github.io/dvizh/privacy.html
```

Или, если основной сайт будет в другом репозитории:

```text
https://duckolly.github.io/dvizh-site/privacy.html
```

---

# 9. Data Safety для Google Play

Примерные ответы для версии v3.2.0 Local-Only.

## Собирает ли приложение данные?

Можно указать, что данные обрабатываются только на устройстве и не передаются разработчику.

## Тип данных

```text
Physical activity / motion sensor data
```

## Цель обработки

```text
App functionality
```

## Где обрабатываются данные

```text
On-device only
```

## Передаются ли данные третьим лицам

```text
No
```

## Получает ли разработчик данные

```text
No
```

## Может ли пользователь удалить данные

```text
Yes
```

## Шифрование при передаче

```text
Not applicable, because data are not transmitted.
```

Важно: ответы в Data Safety должны совпадать с реальным поведением приложения, кодом и privacy policy.

---

# 10. Обоснования разрешений для Google Play

## ACTIVITY_RECOGNITION

Английский:

```text
This permission is used only to access the device motion sensor in order to count steps during an active workout started by the user. Data are processed locally and are not sent to a server.
```

Русский:

```text
Это разрешение используется только для доступа к датчику движения устройства, чтобы считать шаги во время активной тренировки, запущенной пользователем. Данные обрабатываются локально и не отправляются на сервер.
```

## POST_NOTIFICATIONS

Английский:

```text
This permission is used only if the user enables notifications. The app shows a local ongoing notification indicating that recording is active. Notifications do not contain personal data and are not used for advertising.
```

Русский:

```text
Это разрешение используется только если пользователь включил уведомления. Приложение показывает локальное уведомление о том, что идёт запись активности. Уведомления не содержат персональных данных и не используются для рекламы.
```

---

# 11. Чего нельзя писать в Google Play

Не используй в описании, скриншотах и сайте эти формулировки:

```text
похудение
лечение
диагностика
медицинский эффект
реабилитация
улучшение здоровья
снижение риска заболеваний
калории как медицинская метрика
для детей
для школьников
для класса
для родительского контроля
```

Лучше использовать:

```text
local activity tracking
step counting
workout duration
offline history
```

Русский:

```text
локальный учёт активности
подсчёт шагов
длительность тренировки
офлайн-история
```

---

# 12. Готовые посты для размещения в каналах

Ты писал «хочу разместить у себя в каналах». Я не могу опубликовать за тебя, но вот готовые тексты.

## Короткий пост для Telegram / VK

```text
Сделал простое офлайн-приложение «Движ» — локальный счётчик активности.

Оно считает шаги через датчик телефона, хранит историю только на устройстве и не отправляет данные никуда.

Без аккаунта.
Без интернета.
Без рекламы.
Без аналитики.
Без сбора персональных данных.

Есть выбор активности: ходьба, бег, зарядка.
Можно отключить запись и уведомления.
Можно очистить историю или удалить все данные.

Исходный код открыт:
https://github.com/Duckolly/dvizh

Сайт:
https://duckolly.github.io/dvizh/
```

## Более технический пост

```text
Подготовил open-source Android-приложение «Движ» — offline activity tracker.

Основная идея: минимальный трекер активности, который не требует аккаунта, не использует сервер, не собирает персональные данные и не отправляет ничего наружу.

Что внутри:
• Flutter;
• локальное хранение в SQLite;
• подсчёт шагов через датчик движения;
• privacy consent screen;
• переключатель записи;
• переключатель уведомлений;
• очистка истории;
• удаление всех данных;
• тёмная тема;
• усиленный AndroidManifest;
• без INTERNET permission;
• без рекламы, аналитики и crash reporting.

Репозиторий:
https://github.com/Duckolly/dvizh

Сайт:
https://duckolly.github.io/dvizh/
```

## Пост для IT-сообщества

```text
Собрал простой offline-first Flutter-проект «Движ».

Задача была сделать не ещё один фитнес-комбайн, а локальный счётчик активности без сервера, аккаунтов, рекламы и аналитики.

Технически:
• Flutter;
• sensors_plus для акселерометра;
• sqflite для локальной истории;
• shared_preferences для настроек;
• permission_handler для запроса разрешений;
• flutter_local_notifications для опционального ongoing notification;
• AndroidManifest hardened: INTERNET, location, camera, microphone, contacts, SMS, AD_ID removed via tools:node="remove";
• backup disabled;
• privacy consent before permissions;
• delete all data flow.

Open source:
https://github.com/Duckolly/dvizh
```

---

# 13. Минимальный чек-лист перед отправкой в Google

Перед подачей в Google Play проверь:

- [ ] Сайт опубликован.
- [ ] `index.html` открывается.
- [ ] `privacy.html` открывается.
- [ ] `robots.txt` доступен.
- [ ] `sitemap.xml` доступен.
- [ ] `og-cover.png` загружен.
- [ ] Все URL заменены на актуальные.
- [ ] В описании нет медицинских обещаний.
- [ ] В описании нет слов «для детей», «школьников», «класса».
- [ ] Privacy policy URL указан в Google Play Console.
- [ ] Data Safety заполнена честно.
- [ ] AAB собран в release.
- [ ] Подпись release настроена.
- [ ] В merged manifest нет `INTERNET`.
- [ ] Пройдён ручной smoke-test.
- [ ] Если аккаунт личный, выполнено требование закрытого тестирования.

---

# 14. Мой итог

Я подготовил:

1. **Одностраничный сайт** `index.html`.
2. **Отдельную Privacy Policy** `privacy.html`.
3. **SEO-файлы** `robots.txt` и `sitemap.xml`.
4. **Информацию для Google Play Console**.
5. **Готовые посты для каналов**.
6. **Чек-лист перед публикацией**.

Но повторю главное: **я не могу сам разместить сайт или опубликовать посты в каналах**. Ты можешь залить эти файлы на GitHub Pages, а затем использовать ссылку для Google Play и соцсетей.