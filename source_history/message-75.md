
Собрал. Путь 2 зафиксирован (витрина светлая, `VEC-001` в бэклоге как векторная задача — не трогаем). Ниже `release_gate.sh` — единый страж, который переводит задачи из `APPLIED_BY_SCRIPT`/`PATCH_READY` в `VERIFIED` одной командой и привязывает вердикт к конкретному бинарнику (sha256), а не к «когда‑то собиралось».

Сразу рамка честности и ключевые инженерные решения, которые я принял как архитектор, а не переложил на тебя:

| Решение | Почему так, а не иначе |
|---|---|
| **aapt обязателен.** Нет `aapt` → этап permissions = **FAIL окружения**, не SKIP | Gate без проверки `INTERNET` — не gate для офлайн‑приложения. Тихо пропустить security‑проверку опаснее, чем покраснеть. `find_aapt` ищет по `ANDROID_HOME`/`ANDROID_SDK_ROOT`/дефолтным путям/`PATH`, берёт новейшие build‑tools (`sort -V`). |
| **permissions/badging гоняем по debug APK, AAB — только как артефакт** | `aapt` не читает `.aab` (нужен `bundletool`, которого может не быть). Манифест у debug и release один → permissions идентичны. Значит security‑гейт = по APK; релизный AAB проверяем на «собрался + sha256 + размер». Без `key.properties` AAB = **BLOCKED** (ops‑шаг, не качество кода), остальные этапы идут дальше. |
| **R‑5 фактически валидируется сборкой debug** | Рассогласование `namespace`/пакета `MainActivity` не даёт собраться — зелёный `build apk --debug` = R‑5 закрыт по части компилируемости. Финальный выбор `applicationId` для стора остаётся ручным **до первого AAB** (менять после релиза нельзя). |
| **Регресс‑токены = внешний `regress_tokens.txt`, нормативный** | Единый источник истины для gate. `apply_pack.py` я **не** переписываю ради DRY: его регресс = advisory (помогает при ручных правках), gate = normative (гейтит релиз). Рассогласование не критично, т.к. gate сверху поймает всё, что пропустит advisory. Это валидный паттерн (pre‑commit advisory / CI normative), а не перфекционизм ценой переписывания рабочего артефакта. |
| **Сайт‑этап опционален (monorepo или split)** | `index.html`/`privacy.html`/`sitemap.xml` ищу в `ROOT`, `ROOT/docs`, `ROOT/web`; нет — SKIP с заметкой «сайт в другом репо». Gate не ходит в сеть: live‑проверка privacy URL = вне gate (Search Console / руки). |
| **Severity → статус гейта** | MUST = FAIL‑гейт; SHOULD = WARN (не блокирует, но видно); отсутствие подписи = BLOCKED (не FAIL кода). Флаг `--strict` поднимает WARN до FAIL для CI. |
| **Портативность** | `bash` (не `sh`), без `set -e` (иначе `grep`‑пусто убьёт скрипт), `sha256sum`/`shasum -a 256` оба поддержаны, `sed`/`grep` без `\b` (BSD‑совместимо), ANSI‑цвета только в tty (в лог — plain). |

---

## 1. `regress_tokens.txt` (корень проекта)

Формат: `scope:токен`, `#` — комментарий. scope ∈ `lib | pubspec | index | privacy | manifest | all`. Это нормативный список N1..N6 + удалённых полей.

```text
# regress_tokens.txt — нормативный регресс-список для release_gate.sh.
# Формат: scope:токен. scope: lib|pubspec|index|privacy|manifest|all.
# Любое вхождение токена в соответствующей области = FAIL гейта.
# Синхронизирован с N1..N6 (консистентность бренда/контента) и REMOVE-001..005.

# --- палитра / категория (N-1, N-2) ---
lib:Colors.orange
lib:#ff7a00
index:#ff7a00
index:orange
index:HealthApplication
privacy:HealthApplication

# --- удалённые поля продукта v3.2.0 (REMOVE-001..003) ---
lib:nickname
lib:groupCode
lib:calories
lib:weight
lib:mets

# --- запрещённые зависимости / фичи (REMOVE-004..005) ---
pubspec:flutter_foreground_task
pubspec:share_plus
pubspec:pdf:
pubspec:path_provider
pubspec:csv
lib:flutter_foreground_task
lib:share_plus

# --- brandbook публично запрещён (N-3) ---
index:brandbook
privacy:brandbook
manifest:brandbook

# --- сетевые/трекерные токены в коде (офлайн-дух) ---
lib:http
lib:https
lib:dio
lib:socket
lib:firebase
lib:analytics
lib:admob
lib:crashlytics
```

> Замечание по `lib:http`/`lib:https`: это грубый страж; если в коде легально встречается слово в строковом литерале/комментарии — gate подсветит, решай вручную (advisory‑шум допустим, ложный PASS — нет). При необходимости уточни токен до `package:http`/`Uri.http`.

---

## 2. `release_gate.sh` (корень проекта, `chmod +x`)

```bash
#!/usr/bin/env bash
# release_gate.sh — единый релизный страж Движ v3.2.0 Local-Only.
# Read-only по проекту; пишет только release_gate.log и артефакты в build/.
# По умолчанию: гоняет все этапы, печатает сводку, exit 0=PASS(/warn), 1=FAIL.
#   ./release_gate.sh            # полный прогон
#   ./release_gate.sh --strict   # WARN тоже = FAIL (для CI)
#   ./release_gate.sh --skip-build   # только static+regress (быстро, без flutter build)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

STRICT=0; SKIP_BUILD=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    --skip-build) SKIP_BUILD=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "неизвестный аргумент: $a" >&2; exit 2 ;;
  esac
done

LOG="$ROOT/release_gate.log"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="gate-$TS"

# ---- цвета только в tty (в лог пишем plain) ----
if [[ -t 1 ]]; then
  C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_B=$'\033[36m'; C_0=$'\033[0m'
else
  C_G=""; C_Y=""; C_R=""; C_B=""; C_0=""
fi

# ---- счётчики и логирование ----
N_PASS=0; N_WARN=0; N_FAIL=0; N_SKIP=0; N_BLOCK=0
declare -a ROWS=()
log()  { printf '%s\n' "$*" >> "$LOG"; }
say()  { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$LOG"; }
row()  { # row STATUS NAME NOTE
  local st="$1" nm="$2" nt="${3:-}"
  ROWS+=("$(printf '%-7s %-22s %s' "$st" "$nm" "$nt")")
}
mark_pass(){ N_PASS=$((N_PASS+1)); say "  ${C_G}[PASS]${C_0} $*"; row PASS "$@"; }
mark_warn(){ N_WARN=$((N_WARN+1)); say "  ${C_Y}[WARN]${C_0} $*"; row WARN "$@"; }
mark_fail(){ N_FAIL=$((N_FAIL+1)); say "  ${C_R}[FAIL]${C_0} $*"; row FAIL "$@"; }
mark_skip(){ N_SKIP=$((N_SKIP+1)); say "  ${C_B}[SKIP]${C_0} $*"; row SKIP "$@"; }
mark_block(){ N_BLOCK=$((N_BLOCK+1)); say "  ${C_Y}[BLOCK]${C_0} $*"; row BLOCK "$@"; }

sha256(){
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
  else echo "n/a"; fi
}
fsize(){ wc -c < "$1" 2>/dev/null | tr -d ' '; }

find_aapt(){
  local roots=() r bt found=""
  [[ -n "${ANDROID_HOME:-}" ]] && roots+=("$ANDROID_HOME")
  [[ -n "${ANDROID_SDK_ROOT:-}" ]] && roots+=("$ANDROID_SDK_ROOT")
  roots+=("$HOME/Library/Android/sdk" "$HOME/Android/Sdk")
  for r in "${roots[@]}"; do
    [[ -d "$r/build-tools" ]] || continue
    bt="$(ls -1 "$r/build-tools" 2>/dev/null | sort -V | tail -n1)"
    [[ -n "$bt" && -x "$r/build-tools/$bt/aapt" ]] && { found="$r/build-tools/$bt/aapt"; break; }
  done
  [[ -z "$found" ]] && found="$(command -v aapt 2>/dev/null || true)"
  printf '%s' "$found"
}

# поиск файла сайта в нескольких layout-вариантах (monorepo / split)
find_site(){ # find_site name
  local n="$1" c
  for c in "$ROOT/$n" "$ROOT/docs/$n" "$ROOT/web/$n" "$ROOT/public/$n"; do
    [[ -f "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

# =========================================================================
say "=================================================================="
say " Dvizh release gate  $RUN_ID"
say " root: $ROOT"
say " strict=$STRICT skip_build=$SKIP_BUILD"
say "=================================================================="
log ""

# ---- 0. окружение ----
if ! command -v flutter >/dev/null 2>&1; then
  mark_fail "окружение: flutter не найден в PATH"
  say "  → gate бессмыслен без flutter. Установи Flutter SDK и повтори."
  FINAL="FAIL"; finish; exit 1
fi
AAPT="$(find_aapt)"
if [[ -z "$AAPT" ]]; then
  mark_fail "окружение: aapt не найден (security-этап невозможен)"
  say "  → поставь Android build-tools (aapt) или укажи ANDROID_HOME."
  say "  → gate НЕ может выдать PASS без проверки permissions."
else
  say "  aapt: $AAPT"
fi

# ---- 1. static analysis ----
say ""; say "-- [1] flutter analyze (--no-fatal-warnings --no-fatal-infos) --"
if ANZ="$(flutter analyze --no-fatal-warnings --no-fatal-infos 2>&1)"; then
  if printf '%s' "$ANZ" | grep -qE '^[[:space:]]*warning[[:space:]]'; then
    mark_warn "analyze: errors нет, есть warnings"
  else
    mark_pass "analyze: чисто (0 errors / 0 warnings)"
  fi
else
  mark_fail "analyze: есть errors (см. вывод выше / release_gate.log)"
  printf '%s\n' "$ANZ" >> "$LOG"
fi

# ---- 2. unit tests ----
say ""; say "-- [2] flutter test --"
if TST="$(flutter test 2>&1)"; then
  mark_pass "test: зелено"
else
  mark_fail "test: падения (см. release_gate.log)"
  printf '%s\n' "$TST" >> "$LOG"
fi

# ---- 3. регресс N1..N6 по исходникам (нормативный) ----
say ""; say "-- [3] регресс-аудит по regress_tokens.txt --"
TOKENS="$ROOT/regress_tokens.txt"
if [[ ! -f "$TOKENS" ]]; then
  mark_fail "regress: regress_tokens.txt не найден (нормативный список обязателен)"
else
  REG_HITS=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue
    scope="${line%%:*}"; tok="${line#*:}"
    [[ -z "$scope" || -z "$tok" ]] && continue
    case "$scope" in
      lib)      mapfile -t files < <(find "$ROOT/lib" -name '*.dart' 2>/dev/null) ;;
      pubspec)  files=(); [[ -f "$ROOT/pubspec.yaml" ]] && files+=("$ROOT/pubspec.yaml") ;;
      index)    files=(); f="$(find_site index.html)" && files+=("$f") ;;
      privacy)  files=(); f="$(find_site privacy.html)" && files+=("$f") ;;
      manifest) files=(); f="$(find_site site.webmanifest)" && files+=("$f") ;;
      all)      mapfile -t files < <(find "$ROOT/lib" "$ROOT" -maxdepth 1 -name '*.dart' -o -name '*.html' -o -name '*.yaml' 2>/dev/null) ;;
      *) continue ;;
    esac
    [[ ${#files[@]} -eq 0 ]] && continue
    for fp in "${files[@]}"; do
      [[ -f "$fp" ]] || continue
      if grep -Fn -- "$tok" "$fp" >/dev/null 2>&1; then
        hit="$(grep -Fn -- "$tok" "$fp" | head -n1)"
        say "    ${C_R}REGRESSION${C_0} ${hit#"$ROOT/"}  [scope=$scope tok=$tok]"
        REG_HITS=$((REG_HITS+1))
      fi
    done
  done < "$TOKENS"
  if [[ $REG_HITS -eq 0 ]]; then mark_pass "regress: запрещённые токены не обнаружены"
  else mark_fail "regress: найдено вхождений=$REG_HITS (правь вручную до релиза)"; fi
fi

# ---- 4. сборка debug APK (компилируемость + де-факто R-5) ----
APK_DEBUG="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
if [[ $SKIP_BUILD -eq 1 ]]; then
  mark_skip "build debug APK: пропущен (--skip-build) → permissions/R-5 не проверены"
else
  say ""; say "-- [4] flutter build apk --debug (валидирует R-5: пакет MainActivity) --"
  if flutter clean >/dev/null 2>&1 && flutter pub get >/dev/null 2>&1 && BLD="$(flutter build apk --debug 2>&1)"; then
    if [[ -f "$APK_DEBUG" ]]; then
      mark_pass "build debug APK: ok, R-5 рассогласование пакета не встретилось"
    else
      mark_fail "build debug APK: завершился, но app-debug.apk не найден"
    fi
  else
    mark_fail "build debug APK: не собрался (часто = R-5 namespace/package или битый gradle)"
    printf '%s\n' "$BLD" >> "$LOG"
  fi
fi

# ---- 5. permissions + badging по debug APK (security-гейт) ----
BLACKLIST=(
  android.permission.INTERNET android.permission.ACCESS_NETWORK_STATE
  android.permission.ACCESS_WIFI_STATE android.permission.ACCESS_FINE_LOCATION
  android.permission.ACCESS_COARSE_LOCATION android.permission.CAMERA
  android.permission.RECORD_AUDIO android.permission.READ_CONTACTS
  android.permission.READ_CALENDAR android.permission.WRITE_CALENDAR
  android.permission.READ_SMS android.permission.RECEIVE_SMS
  android.permission.FOREGROUND_SERVICE android.permission.RECEIVE_BOOT_COMPLETED
  android.permission.WAKE_LOCK android.permission.VIBRATE
  com.google.android.gms.permission.AD_ID
)
say ""; say "-- [5] permissions / uses-feature (по debug APK) --"
if [[ -z "$AAPT" ]]; then
  mark_fail "permissions: aapt нет → нельзя подтвердить отсутствие INTERNET"
elif [[ ! -f "$APK_DEBUG" ]]; then
  mark_skip "permissions: нет debug APK (skip-build или сборка упала)"
else
  PERMS="$("$AAPT" dump permissions "$APK_DEBUG" 2>/dev/null || true)"
  BADG="$("$AAPT" dump badging "$APK_DEBUG" 2>/dev/null || true)"
  printf 'permissions:\n%s\n' "$PERMS" >> "$LOG"
  printf 'badging:\n%s\n' "$BADG" >> "$LOG"
  PERM_BAD=0
  for p in "${BLACKLIST[@]}"; do
    if printf '%s' "$PERMS" | grep -qF "$p"; then
      say "    ${C_R}FORBIDDEN PERMISSION${C_0} $p"; PERM_BAD=$((PERM_BAD+1))
    fi
  done
  if [[ $PERM_BAD -eq 0 ]]; then mark_pass "permissions: чёрный список пуст (офлайн подтверждён)"
  else mark_fail "permissions: найдено запрещённых=$PERM_BAD"; fi
  # R-6: акселерометр должен быть not-required
  if printf '%s' "$BADG" | grep -qE "^uses-feature: name='android\.hardware\.sensor\.accelerometer'"; then
    mark_warn "uses-feature: акселерометр required=true (R-6 не выполнен; добавь required=\"false\")"
  elif printf '%s' "$BADG" | grep -qE "accelerometer"; then
    mark_pass "uses-feature: акселерометр not-required (R-6 ok)"
  else
    mark_warn "uses-feature: акселерометр не объявлен явно (проверь badging вручную)"
  fi
fi

# ---- 6. релизный AAB (артефакт стора; зависит от подписи) ----
KEYPROPS="$ROOT/android/key.properties"
AAB_REL="$ROOT/build/app/outputs/bundle/release/app-release.aab"
say ""; say "-- [6] release AAB (артефакт Google Play) --"
if [[ $SKIP_BUILD -eq 1 ]]; then
  mark_skip "AAB: --skip-build"
elif [[ ! -f "$KEYPROPS" ]]; then
  mark_block "AAB: нет android/key.properties → release-подпись не настроена (ops-шаг REL-002)"
  say "    → permissions уже проверены по debug APK; для стора собери AAB после настройки подписи."
else
  if AABOUT="$(flutter build appbundle --release 2>&1)"; then
    if [[ -f "$AAB_REL" ]]; then
      SZ="$(fsize "$AAB_REL")"; H="$(sha256 "$AAB_REL")"
      if [[ "${SZ:-0}" -lt 1048576 ]]; then
        mark_warn "AAB: собран, но размер подозрительно мал ($SZ байт)"
      else
        mark_pass "AAB: собран, size=$SZ"
      fi
      say "    sha256(AAB)=$H"
      log "AAB_SHA256=$H AAB_SIZE=$SZ"
    else
      mark_fail "AAB: build ok, но app-release.aab не найден"
    fi
  else
    mark_fail "AAB: release-сборка упала (проверь подпись/gradle)"
    printf '%s\n' "$AABOUT" >> "$LOG"
  fi
fi

# ---- 7. консистентность URL сайта (WARN, не FAIL) ----
say ""; say "-- [7] site URL consistency (canonical == og:url == sitemap == privacy) --"
IDX="$(find_site index.html)"
if [[ -z "$IDX" ]]; then
  mark_skip "site: index.html не найден в этом репо (сайт в другом? гейти там)"
else
  BASE="$(sed -nE 's:.*<link[^>]*rel="canonical"[^>]*href="([^"]+)".*:\1:p' "$IDX" | head -n1)"
  [[ -z "$BASE" ]] && BASE="$(sed -nE 's:.*property="og:url"[^>]*content="([^"]+)".*:\1:p' "$IDX" | head -n1)"
  if [[ -z "$BASE" ]]; then
    mark_warn "site: не извлечён canonical/og:url из index.html"
  else
    say "    base=$BASE"
    MISS=0
    chk(){ # chk file label
      local f="$1" lbl="$2"
      [[ -z "$f" || ! -f "$f" ]] && { say "    (нет $lbl)"; return; }
      grep -qF "$BASE" "$f" || { say "    ${C_Y}URL-DRIFT${C_0} $lbl не содержит base"; MISS=$((MISS+1)); }
    }
    OG="$(sed -nE 's:.*property="og:url"[^>]*content="([^"]+)".*:\1:p' "$IDX" | head -n1)"
    [[ "$OG" == "$BASE" ]] || { say "    ${C_Y}URL-DRIFT${C_0} og:url != canonical"; MISS=$((MISS+1)); }
    SM="$(find_site sitemap.xml)";  chk "$SM" "sitemap.xml"
    PR="$(find_site privacy.html)"; chk "$PR" "privacy.html canonical"
    if [[ $MISS -eq 0 ]]; then mark_pass "site: URL-токены консистентны"
    else mark_warn "site: расхождений URL=$MISS (почини перед подачей; не блокер кода)"; fi
  fi
fi

# =========================================================================
# сводка
say ""; say "=================================================================="
say " СВОДКА $RUN_ID"
say "=================================================================="
for r in "${ROWS[@]}"; do say "  $r"; done
say "------------------------------------------------------------------"
say "  PASS=$N_PASS  WARN=$N_WARN  FAIL=$N_FAIL  BLOCK=$N_BLOCK  SKIP=$N_SKIP"

VERDICT="PASS"
[[ $N_FAIL -gt 0 ]] && VERDICT="FAIL"
[[ $STRICT -eq 1 && $N_WARN -gt 0 && "$VERDICT" == "PASS" ]] && VERDICT="FAIL(strict)"
[[ "$VERDICT" == "PASS" && $N_WARN -gt 0 ]] && VERDICT="PASS(with warnings)"
[[ "$VERDICT" == "PASS" && $N_BLOCK -gt 0 ]] && VERDICT="PASS(local; store AAB blocked)"

say "  VERDICT: $VERDICT"
log "VERDICT=$VERDICT PASS=$N_PASS WARN=$N_WARN FAIL=$N_FAIL BLOCK=$N_BLOCK SKIP=$N_SKIP"
say "  полный лог: $LOG"
say "=================================================================="

# что gate НЕ закрывает (остаётся VERIFIED вручную) — печатаем всегда
say ""
say "  Gate НЕ проверяет (остается на maintainer, VERIFIED вручную):"
say "   - рантайм на устройствах (API 26+ адаптивная иконка/safe-zone; API 23-25 legacy; Xiaomi/Tecno background-kill);"
say "   - live-открытие privacy URL и индексацию (Google Search Console / Яндекс.Вебмастер);"
say "   - заполнение Data Safety / content rating / store listing в консоли Google Play;"
say "   - финальный выбор applicationId ДО первого AAB (R-5 ops-часть);"
say "   - визуальную читаемость букв на превью стора (FEAT-B) и альфу углов icon.png (R-10)."

case "$VERDICT" in
  FAIL|FAIL\(strict\)) exit 1 ;;
  *) exit 0 ;;
esac
```

---

## 3. Запуск

```bash
chmod +x release_gate.sh

# быстрый статик-проход без сборки (regress + analyze + test):
./release_gate.sh --skip-build

# полный гейт (нужны flutter + aapt в окружении):
./release_gate.sh

# для CI — warnings тоже красные:
./release_gate.sh --strict
```

Exit‑code: `0` = PASS / PASS(with warnings) / PASS(local…), `1` = FAIL, `2` = неверный аргумент. В CI достаточно `./release_gate.sh --strict || exit 1`. Каждый прогон дописывает `release_gate.log` (plain, без ANSI) и строку `AAB_SHA256=…`/`VERDICT=…` — это и есть привязка `VERIFIED` к конкретному бинарнику (связка с `COPYRIGHT_FIXATION.md`: гейтился именно этот sha256, а не «вообще»).

Добавь в `.gitignore` (логи прогонов не для git, но sha256 из лога копируй в `TASKS.md` при переводе в `VERIFIED`):

```gitignore
release_gate.log
release_gate.log.*
```

---

## 4. Дельта в `TASKS.md` (вставь секции)

```markdown
## Release gate

### GATE-001: release_gate.sh — единый страж — CODE_READY
**Что гейтит (нормативно):** analyze, test, регресс по regress_tokens.txt (N1..N6 + REMOVE-001..005 +
офлайн-токены), build debug APK (= де-факто валидация R-5 по компилируемости), permissions/blacklist
по debug APK, uses-feature accelerometer required=false (R-6), сборка release AAB при наличии
android/key.properties, консистентность URL сайта (canonical==og:url==sitemap==privacy, WARN).
**Статусы:** MUST=FAIL-гейт; SHOULD=WARN; нет подписи=BLOCK (не FAIL кода); --strict поднимает WARN.
**Exit:** 0 PASS, 1 FAIL, 2 bad-arg. Лог + AAB_SHA256 + VERDICT -> release_gate.log.
**Иерархия регресса:** regress_tokens.txt = нормативный (gate); REGRESS_SCOPES в apply_pack.py = advisory.
Рассогласование не критично: gate сверху поймает всё, что пропустит advisory. apply_pack.py НЕ переписан
ради DRY — переписывать рабочий артефакт дороже, чем держать normative-страж единым источником релиза.

### GATE-002: что gate НЕ закрывает -> VERIFIED вручную — MANUAL (maintainer)
- рантайм на устройствах (API 26+ иконка/safe-zone; API 23-25 legacy; Xiaomi/Tecno background-kill);
- live privacy URL + индексация (Search Console / Вебмастер);
- Data Safety / content rating / store listing в консоли Google Play;
- финальный applicationId ДО первого AAB (R-5 ops-часть);
- визуальная читаемость букв на превью стора (FEAT-B) и альфа углов icon.png (R-10).

### Лог гейт-прогонов
_(sha256 и VERDICT из release_gate.log; при переводе задач в VERIFIED вписывай сюда AAB_SHA256 прогона)_
```

И обнови строки статусов в таблице ревью: `R-1,R-2,R-3,R-4,R-7` после зелёного `--apply` + зелёного gate → `VERIFIED` (вписать `AAB_SHA256`); `R-5` → `VERIFIED` по сборке (compile‑часть) + `MANUAL` до фиксации `applicationId`; `R-6` → `VERIFIED` если gate дал `uses-feature not-required`, иначе `WARN`; `FEAT-B` → `VERIFIED` после загрузки feature‑graphic в стор и проверки читаемости букв (это рантайм/витрина, gate не покрывает).

---

## Итог

`release_gate.sh` закрывает механически всю статическую и сборочную часть `VERIFIED`: компилируемость (включая R‑5 по пакету), permissions‑чёрный список (главная гарантия офлайн‑духа), R‑6 по `uses-feature`, регресс N1..N6 по нормативному `regress_tokens.txt`, тесты, наличие релизного AAB с sha256 и консистентность URL сайта. Что он **не** может и не должен проверять статически — рантайм на железе, живые URL/индексацию и заполнение консоли стора — это честно вынесено в `GATE-002` и остаётся `VERIFIED` за тобой как за архитектором, с привязкой к `AAB_SHA256` из лога.

Открытых технических хвостов по коду/конфигу больше нет: `apply_pack.py --apply` закрывает R‑1..R‑4,R‑7, `release_gate.sh` их верифицирует, `VEC-001` (тёмная витрина) осознанно отложен как векторная задача, `FEAT-B` закрыт светлой витриной. Дальше по твоему выбору: либо гонишь `./release_gate.sh` и присылаешь сводку/лог — разберу красные строки построчно (первым делом, если стрельнёт, это будет R‑5/подпись/битый плагин‑permission); либо, если gate зелёный, переходим к заполнению Google Play Console по `GOOGLE_PLAY_RELEASE_CHECKLIST.md` и `STORE_LISTING.md` (это уже `GATE-002`, руками).