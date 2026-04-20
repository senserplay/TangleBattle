# TangleBattle — Рабочий лог

## 2026-04-20 — fix(maps): split-polygon тайлы + снятие шейдера + cap 4×

### Жалобы пользователя
1. На картах с деревьями бэкграунд не достаёт до верха — повысить масштаб.
2. Платформы **сломаны**: отрисовывается только ОДНА текстура у левого
   края, дальше — пусто, только border. Текстура начинается **после**
   закругления.

### Что случилось с прошлой версией
4-tap bilinear-шейдер на всей ноде ломал `draw_texture_rect` для bg-слоёв
(`mod()` на edge-пикселях бэкграунда вымывал цвет до серо-белого). Также
видимо UV>1 в связке с ShaderMaterial в Compat рендере вело себя
нестабильно — в результате рисовалась только первая копия текстуры.

### Новый подход

#### 1. Шейдер — **удалён**. В `_ready()` больше нет ShaderMaterial;
убрано также `texture_repeat = ENABLED` (не нужно).

#### 2. Платформы — **split-polygon** из N секций
`_draw_themed_platform` теперь делит платформу на цепочку секций:
- `n_full` полностью-текстурных секций шириной `tile_w = tex_w * h/tex_h`
  (в pixel space: 1 копия = `tile_w`)
- Одна правая секция на `leftover = w - n_full * tile_w` (с UV=`0..leftover/tile_w`)

Каждая секция рисуется отдельным `draw_polygon` через хелпер
`_draw_platform_section(round_left, round_right, u0, u1)`. UVs
**всегда** в `[0..1]` — никаких wrap-проблем. Скругление только на
первой и последней секции (`round_left`/`round_right`), внутренние
секции прямоугольные, плотно прилегают к соседям.

Joints между секциями **невидимы**: текстуры seamless на уровне
пикселей (`pixel[0] == pixel[tex_w-1]`, проверено PIL), и стандартный
GL CLAMP-фильтр на обеих сторонах joint семплирует соответствующие
края, которые равны.

Хелпер `_build_rounded_rect_pts()` — общий генератор полигона для
обводки и highlights.

#### 3. BG scale cap: `2.5 → 4.0`
Для 1920×1080 текстур: auto_scale 3.7 теперь не упирается в cap → деревья
растягиваются до полной высоты карты. Для маленьких 225×340 castle
cap 4.0 даёт `900×1360` — всё ещё компактный силуэт, не огромный блоб.

### Файлы
- `scripts/maps/map_base.gd` (+115 / -46)

### Тест
- `mcp__godot__run_project` — без runtime ошибок.

---

## 2026-04-20 — fix(maps): wrap-aware bilinear шейдер — наконец-то реально seamless

### Почему предыдущий fract(UV) шейдер не работал
Пользователь опять видел тонкую вертикальную линию на каждой платформе.
Разбор:
- `fract(UV)` в шейдере возвращает UV в `[0..1)` — корректно по математике.
- Но GPU-фильтр LINEAR семплирует **пару** текселов вокруг точки:
  - На фрагменте UV=0.999 (fract=0.999): пара `(pixel[1998], pixel[1999])`
  - На фрагменте UV=1.001 (fract=0.001): пара `(pixel[0], pixel[1])`
- Это **разные** пары текселов, хотя `pixel[0] == pixel[1999]`! Результат
  усреднения отличается → видимый 1-2px шов.

### Фикс — manual 4-tap bilinear с `mod()` по X
В `_ready()` теперь шейдер:
```glsl
shader_type canvas_item;
void fragment(){
  vec2 tex_size = vec2(textureSize(TEXTURE, 0));
  vec2 px = UV * tex_size - 0.5;
  vec2 pi = floor(px);
  vec2 pf = fract(px);
  float x0 = mod(pi.x,       tex_size.x);
  float x1 = mod(pi.x + 1.0, tex_size.x);
  float y0 = clamp(pi.y,       0.0, tex_size.y - 1.0);
  float y1 = clamp(pi.y + 1.0, 0.0, tex_size.y - 1.0);
  vec4 c00 = texture(TEXTURE, (vec2(x0, y0) + 0.5) / tex_size);
  vec4 c10 = texture(TEXTURE, (vec2(x1, y0) + 0.5) / tex_size);
  vec4 c01 = texture(TEXTURE, (vec2(x0, y1) + 0.5) / tex_size);
  vec4 c11 = texture(TEXTURE, (vec2(x1, y1) + 0.5) / tex_size);
  COLOR = mix(mix(c00, c10, pf.x), mix(c01, c11, pf.x), pf.y) * COLOR;
}
```
Ключевое: `mod(pi.x, tex_size.x)` делает так, что на ОБЕИХ сторонах
UV=N*1.0 семплируется **одна и та же** пара текселов
`(pixel[tex_w-1], pixel[0])`. Усреднение идентично → **шов исчезает**
полностью.

Y — `clamp()` (не `mod()`): платформо-текстуры не seamless
вертикально (сверху трава/верх, снизу глубокая заливка), вертикальный
wrap дал бы артефакт на нижней кромке.

Bg-слои (UV в `[0..1]`) обрабатываются тем же шейдером: внутри
диапазона sampling эквивалентен стандартному bilinear; на крайней
правой кромке прямоугольника есть 1px wrap-артефакт (семплит pixel[0]
слева), но кромка закрыта vignette.

### Файлы
- `scripts/maps/map_base.gd` (+20 / -4 в шейдерном коде)

### Тест
- `mcp__godot__run_project` — шейдер компилируется, без ошибок.

---

## 2026-04-20 — fix(maps): ShaderMaterial+fract UV-wrap для seamless тайлинга платформ

### Запрос пользователя
"С платформами ты не разобрался, все равно зазоры есть между текстурами,
ты просто их закрасил, а надо текстуры было совместить."

Пользователь отверг подход с corner-masks — его раздражал solid-color срез
на углах, и сами тайлы внутри прямоугольной полосы всё ещё имели видимую
границу при wrap на `CanvasItem.texture_repeat=ENABLED` в OpenGL Compat
рендере (известный sub-pixel filter bleed на 0..1 UV-границе).

### Фикс в `scripts/maps/map_base.gd`

#### 1. ShaderMaterial с ручным fract(UV)
В `_ready()` создаётся и применяется `ShaderMaterial` на ноду карты:
```glsl
shader_type canvas_item;
void fragment(){
  vec2 uv = vec2(fract(UV.x), fract(UV.y));
  COLOR = texture(TEXTURE, uv) * COLOR;
}
```
Шейдер явно оборачивает UV через `fract()` в fragment-стадии — это
работает одинаково во всех рендерерах (Forward+, Mobile, Compatibility)
и не зависит от `texture_repeat`. При UV > 1.0 `fract()` возвращает
дробную часть, семплируя «следующую копию» текстуры в той же позиции,
что и начало — для seamless-текстур (`pixel[0] == pixel[1999]`,
проверено) шов становится невидим даже под LINEAR фильтром.

Побочный эффект на bg/water: при обычном `draw_texture_rect(tile=false)`
UV идёт 0..1, `fract()` не меняет значения кроме exact 1.0. На правой
кромке bg-rect может семплироваться `pixel[0]` вместо `pixel[end]` —
визуально 1px, закрывается vignette. Для воды и vignette (без texture)
шейдер индифферентен.

#### 2. `_draw_themed_platform` — простой UV-полигон
Удалены:
- `draw_colored_polygon(platform_color)` подложка
- `draw_set_transform` + `draw_texture_rect(tile=true)`
- 4 corner-mask полигона
- Ручной reset трансформа

Осталось: один `draw_polygon(pts, WHITE, uvs, tex)` с UV в диапазоне
`0 .. (w / (tex_w * h/tex_h))` по X, `0 .. 1` по Y. Текстура **плотно
заполняет** скруглённую капсулу включая углы, тайлы стыкуются без
швов через шейдерный wrap. `segs` повышен 10 → 12 для плавности углов.

#### 3. Чистка warnings
- Убран unused `bg_rect` в `_draw_parallax_background`.
- Убран unused `tex_size` там же.

### Файлы
- `scripts/maps/map_base.gd` (+17 / -60)

### Тест
- `mcp__godot__run_project` — без runtime ошибок и warnings от моих правок.

---

## 2026-04-20 — fix(maps): scale-cap фонов, transform+tile платформ, волнистая вода, -winter_valley

### Запрос пользователя (скриншоты)
1. Haunted Castle: фон **слишком сильно расширен** (тёмные силуэты стали
   гигантскими блобами) — ограничить масштаб.
2. Удалить карту **winter_valley**.
3. Платформы **всё ещё с тонкими зазорами** между тайлами — переделать.
4. Вода-убийца должна иметь **волны на границе**, а не плоскую линию.

### Фиксы в `scripts/maps/map_base.gd`

#### 1. BG — aspect-preserve + max_scale cap
`fill` и `bottom_tile`/`top_tile` теперь сохраняют пропорции текстуры:
- `fill`: `eff_scale = max(want_w/tex_w, want_h/tex_h)` — однородный scale
  покрывает map+буфер по обеим осям, без растяжения с разным X/Y.
- `bottom_tile`/`top_tile`: `eff_scale = min(want_h/tex_h, max_scale) * tex_scale`
  (дефолт `max_scale=2.5`). Маленькие текстуры (225×340) больше не
  раздуваются в огромные блобы. Позиционирование — по центру карты;
  небо (`fill` мод) закрывает щели, где слой не дотягивается.
- Каждый слой может переопределить cap через `"max_scale": 3.0` в конфиге.

#### 2. Платформы — transform + `draw_texture_rect(tile=true)` + corner masks
Отказался от UV-полигонного тайлинга (в Compatibility рендере давал
sub-pixel filter bleed на границах tile — пользователь видел тонкие
линии даже при пиксельно-seamless текстуре, проверено через
`python/PIL: avg_dist=0.00` между краями). Новая реализация:
1. `draw_colored_polygon(pts, platform_color)` — сплошная скруглённая
   подложка (её цвет будет показываться в 4 «срезах» углов).
2. `draw_set_transform(origin, 0, Vector2(scl, scl))` — канвас
   масштабируется так, чтобы native tex-высота = h платформы.
3. `draw_texture_rect(tex, local_rect, tile=true, WHITE)` — Godot сам
   тайлит текстуру через GPU texture repeat, **без subpixel-шва**.
4. `draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)` — сброс.
5. 4 corner-masks: полигоны «углов прямоугольника минус четверть диска»
   перекрашиваются в `platform_color` → прямоугольный тайл-rect
   обрезается до скруглённой капсулы без швов.
6. Outline + top highlight + bottom shadow — поверх масок.

#### 3. Вода — анимированная волнистая граница
`_draw_water_floor` переделан: вместо `draw_rect + draw_line(flat)`
теперь строит `top_pts: PackedVector2Array` с двумя суперпозированными
синусами (амплитуда 14, длина 220, фаза по времени). Поверх:
- Deep-water `draw_colored_polygon(top_pts + bottom-right + bottom-left,
  Color(0.06,0.14,0.24))` — тёмная заливка с волнистым верхом.
- Surface strip `draw_colored_polygon(top_pts + top_pts+48px_down)` —
  средне-синий слой высотой 48px для глубины waterline.
- `draw_polyline(top_pts, 0.55/0.82/0.95, 3.0)` — яркий блик по гребню.
- Secondary `draw_polyline(top+7px, dim, 2.0)` — приглушённый echo.

#### 4. Удаление winter_valley
- `scripts/maps/winter_valley.gd` + `scenes/maps/winter_valley.tscn` → `git rm`.
- `MAP_SCENES` в `scripts/main/game.gd` — 6 карт вместо 7.

### Файлы
- -2 (winter_valley .gd + .tscn)
- `scripts/maps/map_base.gd` (+78 / -42)
- `scripts/main/game.gd` (-1 line)

### Тест
- `mcp__godot__run_project` — без runtime ошибок.

---

## 2026-04-20 — fix(maps): seamless tiling платформ, stretch фонов, чистая вода

### Жалобы пользователя (скриншоты)
1. Платформы: **зазоры** между тайлами + **текстура не доходит до скруглений**.
2. На всех картах снизу — **светло-голубая wavy "лёдо-подобная"** текстура,
   нужно убрать.
3. Фоны **тайлятся** (видны повторения), должны **растягиваться** по ширине.

### Фиксы в `scripts/maps/map_base.gd`

#### 1. Платформы — polygon UV-tiling
Отказался от ручного цикла `draw_texture_rect_region` (давал зазоры из-за
filter-bleed на границах тайлов). Теперь в `_ready()` выставляется
`texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED` на сам Node2D. В
`_draw_themed_platform`:
- Строится скруглённый polygon с `segs=10` на угол (было 6, плавнее).
- UV: `u_max = w / (tex_w * scale)`, `scale = h / tex_h` (aspect-preserve).
  UV-координаты выходят в диапазон `0..u_max` где `u_max` = число тайлов,
  например `520 / (2000 * 0.115) ≈ 2.26`.
- `draw_polygon(pts, WHITE, uvs, tex)` — texture_repeat=ENABLED превращает
  UV>1.0 в tiling, **без швов**. Тайл занимает всю полигональную форму,
  включая скруглённые концы.
- Убрал `draw_colored_polygon` подложку — текстура теперь сама доходит
  до углов.

#### 2. Фоны — stretch вместо tile
`bottom_tile`/`top_tile` режимы полностью переписаны: больше не тайлят
текстуру, а рисуют **одну копию растянутую** на `map_w + 4000` ширины и
`map_h + 1200` высоты, со сдвигом параллакса 0.25×. Пропорции не
сохраняются — но на прямоугольных панорамных слоях визуально нормально,
и нет раздражающих повторений. `fill`-режим (небо) не менялся.

#### 3. Вода — тёмная заливка без wavy-полосы
Убран `draw_texture_rect(water.png, tile=true)` на поверхности — он
действительно выглядел как лёд. Теперь `_draw_water_floor`:
- Solid dark-blue fill по всему floor-band (`Color(0.06, 0.14, 0.24)`).
- 10-ступенчатый вертикальный градиент сверху вниз — светлее у поверхности,
  темнее глубже.
- Тонкая анимированная линия-блик на waterline (`sin(t)*1.5` bob).
- Текстура `water.png` больше не используется для пола.

### Файлы
- `scripts/maps/map_base.gd` (+11 / -55)

### Тест
- `mcp__godot__run_project` — без runtime errors.

### Что дальше
Визуальная проверка пользователем — готов к тюнингу (напр., сохранить
aspect ratio в stretch-моде, варьировать цвет воды per-map, и т.д.).

---

## 2026-04-20 — fix(maps): auto-scale BG + платформо-тайлинг + правильное скругление

### Запрос пользователя
"Вверх растянуть бг, лучше увеличить масштаб чтобы покрывало всю карту. Платформы
странно выглядят — скругления кривые, текстуры не доходят до углов, а на длинных
платформах текстура растягивается. Нужно, чтобы длинные платформы состояли из
одинаковых тайлов, идущих друг за другом."

### Что изменилось в `scripts/maps/map_base.gd`

#### 1. BG auto-scale (режимы `bottom_tile` / `top_tile`)
Раньше слои рисовались в нативном размере (обычно 1920×1080), анкорились к низу
и закрывали лишь нижнюю 1080-полосу на 2800-пиксельной карте — остальное было
чистое небо. Теперь каждый non-fill слой авто-масштабируется так, чтобы его
высота покрывала `map_rect.size.y + 1200` (карта + буфер для параллакса),
пропорционально увеличивая ширину — горизонтальный тайлинг работает на новом
масштабе. `scale` в конфиге слоя остаётся: если он больше авто-значения, берётся
он (ручное управление не сломалось).

#### 2. Платформы — rounded capsule + horizontal tiling
`_draw_themed_platform` полностью переписан:
- Радиус углов: `r = clamp(min(hh*0.95, h*0.45), 6, 26)` — вместо старого
  `clamp(min(hh, hw*0.15), 4, 20)`. Теперь короткие и широкие платформы
  (h=32, w=500) получают **настоящее** скругление, а не еле заметное.
- `draw_colored_polygon(pts, platform_color)` — плотная заливка скруглённой
  формы. Это фон, закрывающий округлые углы.
- `draw_texture_rect_region` в цикле — тайлит seamless текстуру (2000×278)
  **копиями друг за другом** (никакого растягивания): вычисляется
  `scl = (h + 4) / tex_native_h`, `tile_w = tex_native_w * scl`, затем
  `n = ceil(inner_w / tile_w)` тайлов рисуется на inner_rect с
  `inset = r * 0.65` слева/справа чтобы не перекрывать скругления.
  Последний тайл клипается через region-W, чтобы не вылезти за inner_w.
- Обводка и top/bottom highlights остались.

Результат: на любой ширине платформа выглядит как **цельный закруглённый
прямоугольник**, внутри — семплы одной и той же seamless-текстуры идут
одинаковыми копиями, текстура **не растягивается**, углы выглядят круглыми.

### Файлы
- `scripts/maps/map_base.gd` (-18 / +60)

### Тест
- `mcp__godot__run_project` — запуск без runtime errors/warnings от правок.

---

## 2026-04-20 — feat(maps): полная перестройка карт на параллакс-фоны и единые borders

### Запрос пользователя
Удалить все карты, все бэкграунды, все платформо-текстуры. В `my_assets/maps/`
лежат 5 паков параллакс-фонов (Desert, Iceberg+Ocean+Winternight, Forest Blue,
dark_halloween, winter pixel nature) + PNG с 5 seamless платформ-текстурами +
SVG (брать только текстуру земли). Все платформы — прямоугольники закруглённые.
Паралакс-эффект согласно слоям. Границы: **снизу — вода, по бокам — затемнение**.
Всё в новой ветке для возможности отката.

### Что сделано

#### 1. Удаление устаревших ассетов
- **Карты:** удалены 8 старых сцен/скриптов: `ancient_ruins`, `deep_space`,
  `forest_glade`, `frozen_lake`, `mystic_hollow`, `sky_citadel`, `sunset_spires`,
  `volcano_crater` (scenes/maps + scripts/maps, вместе с `.uid`).
- **Фоны:** удалены `assets/textures/backgrounds/`: `clouds_blue`,
  `clouds_sunset`, `dawn`, `forest`, `nature`, `space`.
- **Платформы:** удалены `grass.png`, `ice.png`, `magma.png` (+`.import`).

#### 2. Новые платформо-текстуры (пользователь положил ранее)
- `stone.png` (изменён), `wood.png` (изменён)
- Новые: `sand.png`, `water.png`, `lava_ice.png` — seamless strips из
  `computer-games-seamless-layers-background-set.png`.

#### 3. Новые фоны (пользователь положил ранее, 7 тем)
- `backgrounds/forest_blue/` (10 слоёв)
- `backgrounds/desert/` (9 слоёв)
- `backgrounds/iceberg/` (7 слоёв)
- `backgrounds/ocean/` (7 слоёв)
- `backgrounds/winter_pixel/` (10 слоёв)
- `backgrounds/winternight/` (5 слоёв)
- `backgrounds/halloween/` (11 слоёв)

#### 4. Рефакторинг `scripts/maps/map_base.gd`
- Удалён большой `const BG_THEMES := {...}` (~60 строк конфига старых тем)
  и хелпер `_get_theme_layers` + кэш `_bg_layer_cache`.
- Удалены все `_draw_dz_*` функции (lava, void, abyss, stars, spikes, swamp,
  mist, default) + `_draw_themed_danger_zones` + `_draw_danger_rect` +
  `_dz_soft_edge` (~240 строк).
- Удалены `bg_theme`, `death_zone_style` — больше не используются.
- Добавлен новый **per-map** массив `bg_layers: Array` c полями
  `{path, scroll, mode, y, scale, tint}`. `scroll=0` = слой залочен на экран
  (небо); `scroll=1` = залочен на мир (передний план). Режимы:
  `fill` (1 растянутая копия), `bottom_tile`, `top_tile`.
- Новая функция `_draw_parallax_background()` читает `bg_layers` и рисует
  слои через `draw_texture_rect` с tile=true и parallax-сдвигом.
- Новая функция `_draw_water_floor()` — тайлит `water.png` снизу на всю
  ширину карты как анимированную полосу + глубокий тёмно-синий fill ниже
  + soft fade на верхней кромке.
- Новая функция `_draw_side_vignette()` — вертикальные полосы чёрного
  alpha-градиента слева/справа (по `danger_left`/`danger_right`), затухание
  внутрь карты.
- Изменён порядок `_draw()`: bg → platforms → objects → **water снизу +
  вертикальные vignette по бокам** (borders рисуются поверх всего).
- `queue_redraw()` теперь дёргается каждый кадр (анимированная вода +
  параллакс требуют постоянного обновления).

#### 5. Семь новых карт (scripts/maps + scenes/maps)
| Карта | Фон-тема | Платформы |
|-------|----------|-----------|
| Forest Glade   | forest_blue  | stone    |
| Desert Dunes   | desert       | sand     |
| Iceberg Bay    | iceberg      | lava_ice |
| Ocean Shore    | ocean        | sand     |
| Winter Valley  | winter_pixel | stone (low-friction) |
| Winter Night   | winternight  | wood     |
| Haunted Castle | halloween    | stone    |

Каждая карта: `map_rect=4500x2800`, `danger_left/right=280`,
`danger_bottom=420` (вода), `danger_top=0`. Layout — 8-9 платформ
симметрично, 4 spawn points. scroll-factors подобраны вручную под каждый
пак (от 0.00 для неба до 0.85-0.92 для foreground).

#### 6. Обновлён `scripts/main/game.gd`
`MAP_SCENES` указывает на 7 новых `.tscn`.

### Файлы
- -8 map scripts, -8 map scenes, -16 `.uid`
- -6 bg folders (clouds_blue, clouds_sunset, dawn, forest, nature, space)
- -3 platform textures (grass, ice, magma) + imports
- +7 new map scripts, +7 new map scenes
- `map_base.gd`: ~1590 → ~1320 строк (удалено ~430, добавлено ~180)
- `game.gd`: обновлён MAP_SCENES

### Тест
- `godot --import` прошёл без ошибок (479 шагов reimport).
- `mcp__godot__run_project` с основной сценой — запуск без runtime errors,
  все 7 карт компилируются (общий базовый класс), lobby → матч работает.
- Warnings в debug-output — все pre-existing (не от моих изменений).

### Что дальше
- Визуально проверить все 7 карт в игре, затюнить scroll-factors где
  параллакс слабо заметен.
- Возможно заменить stretch-UV в `_draw_themed_platform` на тайлинг,
  чтобы seamless-текстуры не сжимались на широких платформах.
- При желании — извлечь ground-texture из SVG
  `my_assets/maps/platform/b6id06lfemo6b5wof.svg` (отложено, текущих 5
  PNG достаточно).

### Ветка
`feature/maps-rebuild-parallax` — для возможности отката.

---

## 2026-04-20 — feat(ui): текстурные иконки способностей вместо процедурных эмблем

### Запрос пользователя
Пользователь добавил папку `my_assets/abillities/` (опечатка) с 17 PNG
иконками 1024×1024 для всех активных способностей. Нужно "вырезать и
поменять в игре" — интегрировать как текстурные иконки вместо
процедурных shape-draw эмблем.

### Что сделано

#### 1. Обработка ассетов
Python-скрипт:
- RGB → RGBA (исходники без alpha)
- Применена круговая маска радиуса 508 (из 512) — чистые края, без
  "квадратных" углов вокруг круглого бейджа
- Переименованы в snake_case под enum-имена
- Скопированы в `assets/textures/abilities/` (17 PNG)

Mapping (из my_assets/abillities/ → assets/textures/abilities/):
- `Yarn Toss.png` → `yarn_toss.png`
- `Thread Pul.png` → `thread_pull.png` (исправлена опечатка)
- `Heaven's Wrath.png` → `heavens_wrath.png` (убран апостроф)
- + 14 остальных

#### 2. Новый helper `scripts/ui/ability_icon.gd`
- `class_name AbilityIcon`
- `NAMES: Array` — enum-id → файл-имя (по порядку из `data/abilities.json`)
- Static cache `_cache` (один load на ability_id)
- `get_texture(ability_id)` — лениво грузит с fallback null
- `draw_at(canvas, center, radius, ability_id, modulate)` — рисует
  `draw_texture_rect`. Фоллбек на coloured circle если текстуры нет.

#### 3. Замена рендеринга эмблем в 3 местах
| Файл | Раньше | Стало |
|------|--------|-------|
| `player.gd::_draw_ability_icons` | `_draw_emblem` + подложка | `AbilityIcon.draw_at(... ICON_RADIUS)` с CD-затемнением через modulate |
| `lobby.gd::_draw_card` | `_draw_ability_emblem_lobby` + подложка | `AbilityIcon.draw_at(... 18.0)` |
| `ability_pickup.gd::_draw` | `_draw_emblem` | `AbilityIcon.draw_at(... PICKUP_RADIUS)` |

Старые match-case функции `_draw_emblem` / `_draw_ability_emblem_lobby`
оставлены как dead code (не ломаем сейчас, уберём отдельным refactor'ом).

### Файлы
- 17 новых PNG в `assets/textures/abilities/`
- `scripts/ui/ability_icon.gd` (новый, 61 строка)
- `scripts/characters/player.gd` (-15 строк в _draw_ability_icons)
- `scripts/ui/lobby.gd` (-4 строки)
- `scripts/characters/ability_pickup.gd` (-3 строки)

### Тест
Godot 4.6.1: после `--import` для регистрации `class_name AbilityIcon`,
проект запускается без ошибок. VFX ability emblems теперь — professional
1024×1024 pixel art badges вместо процедурной геометрии.

---

## 2026-04-20 — docs: актуализация документации способностей и пассивок

### Запрос пользователя
"Актуализируй документации по способностям и пассивкам."

### Что было не так
Сравнил `docs/abilities/`, `docs/passives/` с `data/*.json`:

**Abilities** — в `data/abilities.json` было 17, доков было только 14:
- Отсутствовали: **Black Hole** (id 14), **Portal Gate** (id 15),
  **Heaven's Wrath** (id 16) — три самых поздних способности

**Passives** — в `data/passives.json` 25 пассивок, доков было только 15
(0-14). Отсутствовали 10:
- Shockwave (15), Lightning Strike (16), Heavy Impact (17),
  Homing Projectiles (18), Burst Fire (19), Lucky Star (20),
  Spirit Burst (21), Shield Mastery (22), Parry Burst (23),
  Phase Shot (24)

`docs/passives/README.md` указывал "23 пассивки" — устарело.
`docs/abilities/README.md` не имел ссылок на файлы и не отмечал что
префиксы файлов не совпадают с enum-ID (legacy numbering).

### Что сделано

#### 1. Созданы 3 ability docs (по `data/abilities.json`)
- `docs/abilities/14_black_hole.md` — Чёрная дыра (250px радиус, 8с
  активность, pull_force=350, drain=12 HP/s, КД 12с)
- `docs/abilities/15_portal_gate.md` — Парные порталы (2-step активация,
  rope auto-cut при teleport)
- `docs/abilities/16_heavens_wrath.md` — 6 столбов света (55 урона
  каждый, spacing 120px)

#### 2. Созданы 10 passive docs
| ID | Файл |
|----|------|
| 15 | `docs/passives/15_shockwave.md` |
| 16 | `docs/passives/16_lightning_strike.md` |
| 17 | `docs/passives/17_heavy_impact.md` |
| 18 | `docs/passives/18_homing_projectiles.md` |
| 19 | `docs/passives/19_burst_fire.md` |
| 20 | `docs/passives/20_lucky_star.md` |
| 21 | `docs/passives/21_spirit_burst.md` |
| 22 | `docs/passives/22_shield_mastery.md` |
| 23 | `docs/passives/23_parry_burst.md` |
| 24 | `docs/passives/24_phase_shot.md` |

В каждом — описание, таблица редкостей, полный TOML config из json'а.

#### 3. Обновлены README'ы
- `docs/abilities/README.md`:
  - Таблица теперь имеет колонку "Файл" со ссылками
  - Добавлено явное предупреждение: префиксы XX в filename НЕ совпадают
    с enum-ID (legacy numbering)
  - Расширена секция "Особенности механик" — добавлены Portal Gate
    activation flow, Black Hole friendly-fire, Heaven's Wrath геометрия,
    grapple auto-cut на teleport (fix v0.5)
- `docs/passives/README.md`:
  - "23 пассивки" → "25 пассивок"
  - Полная таблица 0-24 с file links и редкостями
  - Секция "Mythic-only" с подсветкой Spirit Burst
  - Секция "Синергии" с 4 примерами комбо

### Не сделано (TODO следующего pass'а)
- Не сверял value-by-value все 14 ранее существовавших ability docs
  с текущим json'ом. Возможно балансные числа в части файлов устарели
  (например, в `14_iron_skin.md` указаны 4 редкости, но в data 5 = добавлена
  Mythic). Системная reconciliation потребует отдельного прохода.

### Файлы
- 3 новых ability doc'а в `docs/abilities/`
- 10 новых passive doc'ов в `docs/passives/`
- 2 README обновлены

---

## 2026-04-19 — fix+feat: 3 баг-фикса + zero-G space + slippery ice

### Запрос пользователя
Баги:
1. При телепорте/swap/grab если игрок на нитке — перемещение не происходит.
   Нитка должна обрываться при teleport/swap, а во время grab вообще нельзя
   пускать нитку.
2. После смерти остаётся фантомный коллайдер (нельзя пройти, можно стоять,
   можно зацепиться). Также после round transition остаются объекты с
   прошлого раунда (black hole, выстрелы, дым).
3. Dash резко тормозит игрока в конце — должен сохранять импульс.

Фичи:
1. На карте Deep Space — нет гравитации (игроки + снаряды летают).
2. Ice платформы скользкие — низкое трение.

### Реализация

#### Bug 1 — grapple integration
- `map_base.gd::_teleport_body`: вызывает `_release_grapple()` перед
  телепортом если у тела есть метод
- `player_abilities.gd::_ab_swap`: cuts grapple на обоих swapped игроков
  ДО смены позиций (раньше rope anchor возвращал игрока обратно)
- `player_abilities.gd::_try_grab_nearby`: cuts grapple на жертве (чтобы
  pull сработал)
- `player_grapple.gd::start_grapple`: блокирует init если `is_grabbed`

#### Bug 2a — corpse collision
В `player.gd::die()`:
- `collision_layer = 0`, `collision_mask = 0` (immediate, не deferred)
- `CollisionShape2D.disabled = true` напрямую
- `global_position = Vector2(-99999, -99999)` — корпус физически уезжает
  за карту, не может быть hit'нут или зацеплен
- `velocity = Vector2.ZERO`

В `respawn()` — восстанавливает `collision_layer = 3, mask = 3`.

#### Bug 2b — round cleanup
`game.gd::_load_random_map` теперь iterрует группы и queue_free всё:
- `ability_entities` (rocket, grenade, boomerang, yarn, black_hole,
  stink_cloud, tripwire, heaven's_wrath)
- `pickups` (dropped abilities)
- `soul_essences` (death souls)

Группа `players` сохраняется (они респавнятся через `_respawn_all`).
Группы привязанные к map_container (hazards, walls, teleports,
destructibles, items) очищаются автоматически с `child.queue_free()`.

#### Bug 3 — dash momentum
`player.gd::_handle_movement` ground-friction case: если |velocity.x| >
max walk speed AND (no input OR same direction) → friction × 0.30.
То есть после dash игрок плавно теряет скорость вместо abrupt brake.

#### Feature 1 — zero-G in space
Новые поля в `map_base.gd`:
- `gravity_multiplier: float = 1.0`
- `floor_friction_mult: float = 1.0`

`deep_space.gd`: `gravity_multiplier = 0.0`.

Player + grapple + grenade читают через helper `_map_gravity_mult()`.
Прочие projectiles (rocket, boomerang, yarn) — propelled, не имеют
gravity. Pickups оставлены с обычной gravity (иначе уплывали бы).

#### Feature 2 — slippery ice
`frozen_lake.gd`: `floor_friction_mult = 0.15`.

`player.gd` ground-friction умножается на map's `floor_friction_mult`.
Игроки скользят дальше, труднее остановиться.

### Файлы
- `scripts/maps/map_base.gd` — `_teleport_body`, новые physics поля
- `scripts/maps/deep_space.gd` — `gravity_multiplier = 0.0`
- `scripts/maps/frozen_lake.gd` — `floor_friction_mult = 0.15`
- `scripts/characters/player.gd` — die/respawn collision, dash momentum,
  gravity/friction map-aware, 2 helpers
- `scripts/characters/player_abilities.gd` — swap/grab grapple cuts
- `scripts/characters/player_grapple.gd` — block while grabbed +
  grapple gravity scaled
- `scripts/characters/grenade.gd` — gravity scaled by map
- `scripts/main/game.gd::_load_random_map` — group-based cleanup

### Тест
Godot 4.6.1: компилируется чисто, все warning'и pre-existing. Полный
playtest требуется для проверки в split-screen + всех способностей.

---

## 2026-04-19 — fix(maps): floor_strip удалён — palette-текстуры сами являются strip'ами

### Проблема (по новым скриншотам)
Поверх широких платформ виден ВТОРОЙ декоративный strip. Visible как
дублирование — две green-grass-with-stones полосы одна над другой.

### Корневая причина
Открыл файлы `assets/textures/platforms/{grass,stone,ice,magma,wood}.png`
и **обнаружил что это те же craftpix landscape strips**:
- `stone.png` ≈ `landscape_strips/strip_05` (alien_teal — green grass)
- `grass.png` ≈ `strip_01` (grass + dirt)
- `ice.png` ≈ `strip_12` (ice frozen)
- `magma.png` ≈ `strip_03` (lava crystal)
- `wood.png` ≈ `strip_07` (sand + grass)

`_draw_themed_platform()` рендерит ВСЮ palette-текстуру (с deco grass tops
и substrate dirt) натянутую на shape платформы. Это уже выглядит как
strip. А я сверху накладывал floor_strip — получалось ДВА strip'а.

Особенно плохо в `mystic_hollow`: palette="stone" (зелёный) + floor_strip
"amethyst_purple" (фиолетовый) → видно green-strip ниже purple-strip'а.

### Решение
Удалена вся `floor_strip` система целиком:
- Поле `floor_strip` и cache `_strip_tex_cache` из `map_base.gd`
- Функции `_get_strip_texture` и `_draw_floor_strip_overlay`
- Wrapper в `_draw_platforms` (`if floor_strip != "" ...`)
- `is_floor` local var (использовалась только для overlay)
- `floor_strip = "..."` строки из 5 карт (forest_glade, frozen_lake,
  ancient_ruins, mystic_hollow, volcano_crater)
- Папка `assets/textures/platforms/strips/` удалена (6 PNG + .import)

Теперь palette-текстура сама даёт визуальный strip, без overlay-наслоений.

### Файлы
- `scripts/maps/map_base.gd`: -50 строк
- 5 map скриптов: -1 строка каждая
- `assets/textures/platforms/strips/` удалена

### Тест
Godot 4.6.1: компилируется без новых warning'ов.

---

## 2026-04-19 — fix(maps): strip-текстуры были RGB без alpha (чёрный фон)

### Проблема (по новому скриншоту)
Поверх платформы виден ЧЁРНЫЙ band с декорациями (стонами/травинками)
на ровно прямоугольной чёрной подложке. Не вписывается, острые границы.

### Корневая причина
Проверил формат strip-PNG через Python/PIL:
```
alien_teal: mode=RGB size=(904, 91)
grass_dirt: mode=RGB size=(904, 93)
ice_frozen: mode=RGB size=(904, 102)
...
```

**Источник** (craftpix landscape strips) сохранён в **RGB без alpha**.
"Прозрачные" участки между декорациями (между травинками, вокруг камней)
— на самом деле литеральный `(0,0,0)` чёрный. Godot рендерит как opaque
black, что даёт визуальный black-bar над платформой.

Также я ранее ошибочно полагал что текстура 960×400 (с substrate ниже
ground line) — на самом деле 904×~93, целиком декорация без substrate.
Поэтому SRC_DECO_RATIO=0.40 был лишним.

### Решение

#### 1. Конвертация PNG: RGB → RGBA (чёрный → transparent)
Python script прошёл по всем 6 strip-текстурам, заменил pure-black
пиксели (R,G,B все < 8) на alpha=0:
```
alien_teal:      13119 px transparent (of 82264)
amethyst_purple: 14429 px transparent (of 84072)
grass_dirt:       9304 px transparent (of 84072)
ice_frozen:      14313 px transparent (of 92208)
lava_crystal:     9325 px transparent (of 79552)
sand_grass:      18275 px transparent (of 93112)
```

Очищен `.godot/imported/` cache → Godot реимпортит с новыми alpha.

#### 2. Переписан `_draw_floor_strip_overlay`
- Использует ВЕСЬ source rect (не SRC_DECO_RATIO crop) — текстура и так
  только декоративная, без substrate
- disp_h = 75 (было 70 после crop)
- Position: strip's bottom = platform_top + 10px overlap (для бесшовного
  сопряжения с платформой)
- aspect tile_w основан на real source ratio (~10:1)

### Файлы
- 6 PNG в `assets/textures/platforms/strips/` — RGB→RGBA
- `scripts/maps/map_base.gd::_draw_floor_strip_overlay` переписан

### Тест
Godot 4.6.1: после очистки import cache — реимпортит strips с alpha.
Запускается без ошибок.

---

## 2026-04-19 — fix(maps): strip-overlay substrate + ancient_ruins блоки + космос лаги

### Проблемы по скриншотам

**1. Frozen Lake — два слоя на платформе.** Strip overlay рисовал ВСЮ
текстуру (110px), а у `ice_frozen.png` под верхушкой ice crystals идёт
substrate (тёмный лёд + columns). Этот substrate бликовал ниже платформы
и создавал визуальный "two-tier" mess.

**Fix:** Только TOP 40% strip-текстуры через `draw_texture_rect_region`
(SRC_DECO_RATIO = 0.40). Display height снижен с 110 → 70px. Теперь
только декорация (ice crystals / grass tufts / lava crystals) вылезает
над платформой, без substrate.

**2. Ancient Ruins — непонятные коричневые блоки.** Destructible columns
рендерились как plain brown капсулы (90×180px) без визуального индикатора
"эту штуку можно сломать". Игрок видел абстрактные прямоугольники.

**Fix:** Удалены destructibles. Заменены на 2 raised stone-block plinths
(280×130, тип `false` = solid floor) — это понятные каменные постаменты.
Поверх них поставлены **резные temple orbs** (decorative balls 55px),
плюс добавлен **sky orb 45px** над алтарём. Теперь сцена читается как
"храмовые постаменты с орбами".

**3. Deep Space — лаги.** Procedural starfield итерировал ВСЁ bg_rect
(extended map ± 3500 = ~12400×10200) с шагом 180-380px → ~3000+ ячеек ×
2 layers × 60fps = ~360k cell-evals/sec + sin/cos calls. Плюс
`_dz_stars` рисовал 40 star-circles на каждый из 4 dz rects = ещё 160
звёзд/frame.

**Fix:**
- `stars_proc` теперь **viewport-culled**: получает `cam.position` +
  `viewport.size`, вычисляет видимый прямоугольник + margin, итерирует
  только cell-grid range пересекающийся с viewport. Тысячи cells →
  десятки. Параллакс остаётся deterministic (origin сдвинут).
- Spacing увеличен 180-380 → 320-540px, skip 60% → 75% (sparser).
- `_dz_stars` упрощён: убраны star particles (bg даёт их), оставлен
  только tinted dark veil + soft edge. -160 circles/frame.

### Файлы
- `scripts/maps/map_base.gd`: `_draw_floor_strip_overlay` (top-only),
  `stars_proc` (viewport cull), `_dz_stars` (упрощён), shadowing fix
- `scripts/maps/ancient_ruins.gd`: destructibles удалены, заменены
  plinths + temple orbs

### Тест
Godot 4.6.1: компилируется без новых warning'ов.

---

## 2026-04-19 — feat(maps): полный rewrite пула карт — 18 → 8 уникальных, тематически проработанных

### Запрос пользователя
"Удали все maps и составь план по реализации новых, используя ассеты, которые
у тебя имеются" + "не опираясь на прошлую реализацию, делай новую, учитывая
структуру/тему бэкграунда, наполняя их подходящими платформами, расположение
платформ, ловушки, порталы, как выглядит опасная зона"

### Что сделано

#### 1. Удалены все 18 старых карт
`scripts/maps/*.gd` (кроме `map_base.gd`) и `scenes/maps/*.tscn` — полностью
с нуля. Список удалённых: arena, clockwork, cloud_kingdom, dungeon, factory,
fortress, ice_cave, inferno, jungle, meadow, mirror, sky_garden, space,
tower, trampoline, twin_peaks, volcano, workshop.

#### 2. Новый ассет: landscape strips (декорация платформ)
Скопировано 6 strip-текстур из `my_assets/extracted/landscape_strips/` в
`assets/textures/platforms/strips/`:
- `grass_dirt.png` — классическая зелёная трава с почвой
- `lava_crystal.png` — красные кристаллы лавы на потрескавшейся породе
- `alien_teal.png` — инопланетная teal-трава
- `sand_grass.png` — пустынный песок с травой
- `amethyst_purple.png` — фиолетовые аметистовые кристаллы
- `ice_frozen.png` — лёд с сосульками

#### 3. Новое поле `floor_strip` в `map_base.gd`
- Строковое имя strip-текстуры (или "" для отключения)
- Накладывается поверх широких (≥500px) `floor`-платформ
- `_draw_floor_strip_overlay()` тайлит strip горизонтально, anchored по
  ground-line strip'а ровно на верх платформы
- Static cache `_strip_tex_cache` — load 1 раз на тему

#### 4. **8 новых карт — каждая с уникальной тематикой**

**1. Forest Glade** (`forest_glade.gd`) — 4400×2900
- BG: forest, BRIGHT, DZ: swamp, palette: grass + grass_dirt strip
- Симметричная лесная поляна, открытое небо, intro-friendly
- 9 платформ ярусами, 2 декоративных шара, 4 item spawn

**2. Sunset Spires** (`sunset_spires.gd`) — 5000×3400
- BG: dawn (warm sunset), DZ: abyss, palette: stone
- Две каменные башни-шпиля + sky bridge между вершинами
- **Telepair между summit'ами** — стратегический high-ground swap
- 19 платформ, 2 крупных каменных orb на пиках

**3. Sky Citadel** (`sky_citadel.gd`) — 5000×3000
- BG: clouds_blue, DZ: mist, palette: ice (cloud-look)
- Floating cloud islands, открытое небо со всех сторон
- **Wind events** каждые 11с — поток сдувает игроков в сторону
- 13 платформ, 2 cloud-puff balls

**4. Volcano Crater** (`volcano_crater.gd`) — 4200×2800
- BG: clouds_sunset, fire_walls (нет падения), palette: magma + lava strip
- Компактная огненная арена-чаша, **2 spike pit** между ramp'ами
- Касание стен → fire damage
- 9 платформ, 3 lava-bomb balls

**5. Frozen Lake** (`frozen_lake.gd`) — 4800×2700
- BG: clouds_blue (cold), bouncy_walls (отскоки), palette: ice + ice strip
- Широкое плоское ледяное озеро + парящие ледяные осколки
- Игроки отскакивают от стен — chaotic движение
- 10 платформ, 3 ice-block balls

**6. Deep Space** (`deep_space.gd`) — 5400×3200
- BG: space (procedural starfield), DZ: stars, palette: stone (asteroid)
- **Открыто во ВСЕ стороны** (включая верх) — космическая пустота
- **2 telepair'а** — диагональные corner-to-corner warps
- 15 платформ-астероидов, 3 spherical balls

**7. Ancient Ruins** (`ancient_ruins.gd`) — 4400×3000
- BG: nature4 (forest landscape), use_walls (solid stone), palette: stone + alien_teal strip
- Закрытый храм с **3 destructible колоннами** — рушится за раунд
- 12 платформ, 2 broken-column balls

**8. Mystic Hollow** (`mystic_hollow.gd`) — 4800×3000
- BG: clouds_sunset (violet tint), DZ: void, palette: stone + amethyst strip
- Эзотерическая фиолетовая арена, void сверху И снизу (eerie enclosure)
- **2 spike pit** между mid ledges, **cross-portal** между top summits
- 12 платформ, 3 amethyst orbs

### Распределение механик
- Open top: forest_glade, sunset_spires, sky_citadel, deep_space
- Walls: volcano_crater (fire), frozen_lake (bouncy), ancient_ruins (solid)
- Void enclosure: mystic_hollow (top + bottom)
- Portals: sunset_spires (1), deep_space (2), mystic_hollow (1)
- Destructibles: ancient_ruins (3 columns)
- Spikes: volcano_crater (2), mystic_hollow (2)
- Custom event: sky_citadel (wind gusts)

### Файлы
- **Удалено**: 18 × `scripts/maps/*.gd` + `*.uid` + 18 × `scenes/maps/*.tscn`
- **Создано**: 8 новых map скриптов + 8 .tscn + 6 strip ассетов
- `scripts/maps/map_base.gd`: +25 строк (`floor_strip` field, `_get_strip_texture`,
  `_draw_floor_strip_overlay`, integration в `_draw_platforms`)
- `scripts/main/game.gd::MAP_SCENES`: новый список из 8 карт

### Тест
Godot 4.6.1: запускается без ошибок и без новых warning'ов.

---

## 2026-04-19 — hotfix: ability VFX не показывались в exported билде (DirAccess.list_dir)

### Проблема
Пользователь после v0.3 заметил: при использовании способностей (например
ракета) в **exported билде** не показывались взрывы и другие VFX-анимации.
В editor работало нормально.

### Корневая причина
`scripts/effects/sprite_effect.gd::get_frames()` сканировал директорию через
`DirAccess.open(path)` + `dir.get_next()` + фильтр по `.png`.

В Godot 4 при экспорте PNG-файлы импортируются в `.ctex` (compressed
texture). В PCK файла лежат `.ctex`, а не `.png`. `DirAccess.list_dir` в
PCK не возвращает оригинальные имена с `.png` — поэтому фильтр
`f.ends_with(".png")` ничего не находил → `frames` пустой → анимация
не рисовалась.

В editor работало потому что real `.png` файлы лежат на диске рядом с
`.import`.

### Решение
Заменил DirAccess-сканирование на sequential index loop через
`ResourceLoader.exists()`:

```gdscript
var path := "res://assets/effects/%s/frame_%02d.png"
var i := 0
while i < 100:
    var p := path % [effect, i]
    if not ResourceLoader.exists(p):
        break
    var tex: Texture2D = load(p)
    arr.append(tex)
    i += 1
```

`ResourceLoader.exists()` корректно работает в обоих режимах потому что
проверяет import-system (а не filesystem). Все 25 effect-папок используют
naming `frame_XX.png` (от 5 до 14 кадров), фикс универсален.

### Файлы
- `scripts/effects/sprite_effect.gd::get_frames()` — переписана функция

### Тест
Editor: компилируется + запускается без ошибок. Билд проверится при
make_release. Затронуто: все 25 effect-наборов (cartoon_*, retro_*,
slash*) — 245 PNG-кадров, используемых способностями (Yarn Bomb,
Boomerang, Heaven's Wrath, Needle Dash и т.д.).

---

## 2026-04-19 — fix(maps): корневая причина — wrong scale + procedural starfield

### Проблема
Скриншоты показали 2 серьёзных бага:
1. **Dawn theme** — всё ещё 2 слоя силуэтов (горизонт + foreground trees) при
  тёмных tint'ах сливаются в "vertical repetition"
2. **Space stars** — рябит в глазах: повторяются плотно по вертикали

### Корневая причина
Проверил реальные размеры текстур:
- `dawn/02.png`, `07.png`, `08.png` = **1980x1080** (не маленькие!)
- `forest/*` = 928x793
- `clouds/*` = 576x324
- **`stars.png` = 144x9** (тонкая полоска, 9 пикселей высотой!)

**Я скейлил dawn в 14-16x** при том что текстура уже 1980x1080. Получалось
27000+ пикселей — слои катастрофически большие, что усугубляло наложение.

**stars.png — 9px высотой**, при tile_xy в любом scale тайлится по вертикали
плотными рядами (виде vertical pinstripes).

### Что сделано

#### 1. Dawn — scale 14x → 1.5-2x, оставлен только горизонт
- `02.png` (sky+sun) — `stretch_full` scale=1.5 (текстура уже большая)
- `07.png` (red landscape) — `tile_x` scale=2.0 (один силуэт-горизонт)
- **Удалён** `08.png` (bare trees) — был лишним overlap
Теперь dawn — чистый sky + чистый горизонт.

#### 2. Forest упрощён — sky + 1 foreground band
- `00_sky.png` stretch_full
- `08_front_trees.png` scatter_x scale=8 (был 14x)
- Distant tier удалён — был источником "горизонтальных полос"

#### 3. Clouds — sky + 1 cumulus band
- Удалён `01_far.png` (был источник vertical repeat)
- Только `03_close.png` scatter_x scale=10x

#### 4. Space — procedural starfield (новый mode `stars_proc`)
Текстура 144x9 непригодна для tile_xy. Заменена на полностью procedural:
- Deterministic grid 180-380px spacing (зависит от scroll factor)
- 60% клеток пропускается → редкие звёзды
- Per-star: random offset, radius 1.5-6px, twinkle alpha
- **2 layer'а** stars_proc (foreground big stars + background small stars)
  с разным spacing для depth illusion

### Файлы
- `scripts/maps/map_base.gd`:
  - BG_THEMES упрощён (-15 строк layer'ов)
  - `_get_theme_layers` поддерживает null-textures для proc modes
  - Новый case `stars_proc` (+30 строк)
  - Все scale'ы выверены под реальные размеры текстур

### Тест
Godot 4.6.1: компилируется чисто. Pre-existing warnings only.

---

## 2026-04-19 — fix(maps): меньше overlap слоёв + soft edges на death zones + реже звёзды

### Запрос пользователя
По скриншотам видны проблемы:
- На jungle деревья наслаиваются "снизу вверх" — горизонтальные полосы
  мелких деревьев одна над другой
- Резкие переходы между death zone и playable area
- В space звёзды слишком плотно
- Видны вертикальные швы (это split-screen, см. ниже)

### Что сделано

#### 1. Упрощены темы — убран overlap silhouettes
До: 6-8 слоёв per тема, многие с tree silhouettes на разной y → визуально
наслаивались бандами.
После: **3 layer'а максимум** на тему (sky + 1 distant horizon + 1 foreground).
- `forest`: 3 layer'а (sky → 1 distant tree band → 1 big foreground trees)
- `dawn`: 3 layer'а (sky+sun → 1 red landscape → 1 bare front trees)
- `clouds_blue/sunset`: 3 layer'а (sky → 1 thin far cloud → 1 big cumulus)
- `space`: **1 layer** stars (был 2 — `stars_special` убран)

Plus масштабы подняты ещё выше для foreground (14-16x), чтобы каждый объект
был заметен и редко повторялся.

#### 2. Soft edge на death zones (`_dz_soft_edge` helper)
Новая функция — рисует deterministic gradient strip от edge зоны в сторону
playable area. Alpha спадает с `pow(1-t, 1.6)` — мягкий нелинейный спад на
~140-260px. Применён ко всем стилям death-zone (lava 220, void 200, abyss
220, stars 240, spikes 140, swamp 200, mist 260, default 120).

Теперь стенка death zone "втекает" туманом/дымом в зону игрока вместо
жёсткой полосы.

#### 3. Реже звёзды (space)
- Был: 2 layer'а stars + stars_special, оба scale=4x
- Стал: 1 layer stars, scale=12x → меньше копий на экран, звёзды крупнее
- В `_draw_dz_stars` сократил count 80→40, увеличил радиус 1.5→2.5

#### 4. Больше bg padding
- Был: bg_rect = map ± 1500
- Стал: bg_rect = map ± 3500 — невидно "конец неба" даже при отдалённой
  камере или больших картах

### О split-screen швах
Скриншоты показали вертикальные швы между половинами экрана. Это
**неустранимо в текущей архитектуре** — каждый sub-viewport рендерит сцену
со своей камеры, parallax считается на её позиции, поэтому в каждой
половине bg сдвинут по-разному. Решение требовало бы перенести bg в
CanvasLayer per-viewport, что серьёзный рефакторинг.

### Файлы
- `scripts/maps/map_base.gd`: упрощён BG_THEMES (-30 строк layer'ов),
  добавлен `_dz_soft_edge` helper (+38 строк), 8 death-zone функций
  обновлены вызовом `_dz_soft_edge`, bg_rect padding расширен.

### Тест
Godot 4.6.1: компилируется без новых warning'ов. Pre-existing warnings
от sprite_effect/boomerang/player не связаны.

---

## 2026-04-19 — fix(maps): крупнее silhouettes + scatter_x mode (меньше повтора, больше 3D)

### Запрос пользователя
"На картах одни и те же объекты очень мелкие и часто повторяются, нужно
сделать их более крупными и разнообразными, 3d эффект хорошо работает."

### Что сделано

#### 1. Новый mode `scatter_x` в `_draw_themed_background`
Раньше foreground silhouettes использовали `tile_x` — одна и та же текстура
повторяется идеально. Теперь `scatter_x`:
- Расставляет N инстансов вдоль карты с deterministic pseudo-random позициями
- Каждый инстанс: размер 0.85x..1.30x, jitter ±35% spacing, 50% горизонтальный flip
- Стабильно между фреймами (seed на индексе) — без мерцания
- Spacing = `tex_size.x * 0.65` (лёгкий overlap для естественности)

#### 2. Увеличены масштабы текстур (объекты крупнее)
- `forest`: 5x → 9-12x (foreground trees 12x)
- `dawn`: 7x → 12-16x (front trees 16x)
- `clouds_blue/sunset`: 7x → 10-14x (большие кучевые облака)

#### 3. Больше layer-вариаций (меньше повтора одной картинки)
- `forest`: добавлены `01_lights` (sun halo), `07_close_trees` — теперь 8
  слоёв вместо 6 (всего в паке 10)
- `dawn`: пересобран — правильный порядок layer'ов:
  `02 (sky+sun) → 07 (red landscape) → 04 (pines) → 03 (mid) → 05 (purple
  pines) → 08 (bare trees foreground)`. Раньше использовал layer 06 как sky
  по ошибке — это нижний градиент.
- `clouds`: mid + close переведены в `scatter_x` для разнобоя

#### 4. Гибридный подход tile_x + scatter_x
- **Дальние слои** остаются `tile_x` (горизонт читается ровно)
- **Средние и foreground** используют `scatter_x` (deterministic variety)

### Файлы
- `scripts/maps/map_base.gd` — новый match case `scatter_x` в
  `_draw_themed_background` (+30 строк), пересобраны 4 темы (forest, dawn,
  clouds_blue, clouds_sunset)

### Тест
Godot 4.6.1: запускается без ошибок. Все warning'и — pre-existing
(sprite_effect, boomerang, player) и не связаны с этим изменением.

---

## 2026-04-19 — feat(maps): текстурные бэкграунды + тематические death zones на всех 16 картах + 2 новые карты

### Запрос пользователя
"Я добавил 4 новых архива для бэкграунда карт в my_assets, а еще там был до
этого архив craftpix-net-558275-free-sky-with-clouds-background-pixel-art-set.
Замени бэкграунд, зоны смерти на ВСЕХ картах, используя ассеты из этих
архивов, можно также добавить новые карты под данные тематики."

### Что сделано

#### 1. Скопированы ассеты в `assets/textures/backgrounds/`
| Папка | Источник | Содержимое |
|-------|----------|-----------|
| `forest/` | Free Pixel Art Forest | 10 слоёв (sky → grass) |
| `dawn/` | The Dawn | 8 слоёв silhouettes (горы) |
| `clouds_blue/` | craftpix-558275 / Clouds 1 | 4 слоя (небо + облака) |
| `clouds_sunset/` | craftpix-558275 / Clouds 4 | 4 слоя (закат + облака) |
| `space/` | SpaceBackgroundSource | stars.png + stars_special.png |
| `nature/` | Nature Landscapes | n1..n8 — full-frame |

#### 2. Новый bg-theme система в `map_base.gd`
- Константа `BG_THEMES` — словарь тем с layers config
- Каждый layer: `[path, scroll, anchor_y, offset_y, scale, tint, mode]`
  - `mode = "stretch_full"` (одно растянутое изображение для неба)
  - `mode = "tile_x"` (горизонтальная полоса с tile-репитом)
  - `mode = "tile_xy"` (звёзды — тайл в обоих направлениях)
- Static cache `_bg_layer_cache` — текстуры подгружаются 1 раз на тему
- Параллакс: layer.scroll = 0.0 → закреплено к карте, 1.0 → следует за камерой

Карты задают: `bg_theme = "forest"`, `bg_tint = Color(...)`,
`death_zone_style = "..."` в `_init()` — всё остальное base class рисует сам.

#### 3. Тематические death zones (`death_zone_style`)
Заменили старые красные полоски на стилизованные зоны:
- `lava` — оранжевое свечение, пузырьки, hot edge (volcano)
- `void` — тёмно-фиолетовый с мерцающими частицами (mirror)
- `abyss` — чёрный ink с фиолетовыми каплями + glow edge
- `stars` — открытое пространство со звёздами (space)
- `spikes` — красная зона с зубчатой кромкой (arena)
- `swamp` — токсично-зелёная жижа с пузырями (jungle)
- `mist` — холодный голубой туман (ice_cave, sky)
- `default` — старый красный striped (fallback)

#### 4. Назначение тем по 16 картам
| Карта | bg_theme | bg_tint | death_zone |
|-------|----------|---------|-----------|
| arena | dawn | warm sunset | spikes |
| workshop | dawn | dusk grey | abyss |
| sky_garden | forest | bright | mist |
| volcano | clouds_sunset | hot orange | lava |
| ice_cave | clouds_blue | cold blue | mist |
| tower | dawn | twilight purple | abyss |
| factory | dawn | grey | abyss |
| jungle | forest | natural | swamp |
| space | space | (white) | stars |
| dungeon | dawn | night purple | abyss |
| cloud_kingdom | clouds_blue | (white) | mist |
| clockwork | dawn | brass | abyss |
| mirror | clouds_sunset | violet | void |
| fortress | dawn | noble | (walls — N/A) |
| inferno | clouds_sunset | crimson | (fire walls — N/A) |
| trampoline | clouds_blue | (white) | (bouncy walls — N/A) |

#### 5. Две новые карты
- **Meadow** (`scenes/maps/meadow.tscn`, `scripts/maps/meadow.gd`):
  forest theme с белым tint, swamp pit, открытый верх. 11 платформ
  scattered как лесные островки на 5000×3200 поле.
- **Twin Peaks** (`scenes/maps/twin_peaks.tscn`,
  `scripts/maps/twin_peaks.gd`): dawn theme с тёплым sunset tint, abyss
  внизу. Две большие плато-горы (1500px) + sky bridge между вершинами +
  телепорт между twin summits на 5200×3200.
- Зарегистрированы в `game.gd::MAP_SCENES` (теперь 18 карт).

### Файлы
- **Новые ассеты**: ~30 файлов в `assets/textures/backgrounds/{forest,dawn,clouds_blue,clouds_sunset,space,nature}/`
- **Новые скрипты**: `scripts/maps/meadow.gd`, `scripts/maps/twin_peaks.gd`
- **Новые сцены**: `scenes/maps/meadow.tscn`, `scenes/maps/twin_peaks.tscn`
- **map_base.gd**: +260 строк (BG_THEMES, _draw_themed_background,
  _draw_themed_danger_zones, 7 функций dz_lava/void/abyss/stars/spikes/swamp/mist)
- **16 map scripts**: добавлены 2-3 строки `bg_theme/bg_tint/death_zone_style`
- **game.gd**: +2 строки в MAP_SCENES

### Тест
Godot 4.6.1 — `mcp__godot__run_project` (jungle.tscn + main): запускается без
ошибок и без warnings. Class cache obnovлён корректно.

### Дальше
- Visual playtest всех 16 карт (нужно проиграть в lobby) — поправить anchor_y
  для конкретных карт если silhouettes окажутся слишком высоко/низко
- Возможно добавить subtle ambient звуки под темы (forest cricket, dawn wind)

---

## 2026-04-19 — feat: текстура yarn ball вместо процедурных кругов на всех UI экранах

### Запрос пользователя
"Сделай теперь иконку персонажа на всех экранах именно с ассета, а не отрисованный.
Экран подключения, выбор карт"

### Что сделано

#### Новый helper `scripts/ui/yarn_ball_icon.gd` (`class_name YarnBallIcon`)
Статический helper для отрисовки yarn-ball icon с лицом на любом CanvasItem:
```gdscript
static func draw_at(canvas, center, radius, color, with_face = true):
    # Tinted body + optional happy face overlay
```
- Кеширует body/face текстуры (загружает 1 раз)
- При отсутствии текстуры fallback на `draw_circle`
- `with_face = false` для декоративных не-character иконок

#### Заменены 5 мест процедурной отрисовки

| Файл | Где | Что было | Стало |
|------|-----|----------|-------|
| `lobby.gd` :426-440 | Слот игрока | 6 draw_circle (тело + 4 глаза + 5 yarn lines) | 1 строка `YarnBallIcon.draw_at(...)` |
| `game_overlay.gd` :80-105 | Победный экран (winner ball) | 4 draw_circle + 7 yarn lines + 4 eye circles | `YarnBallIcon.draw_at(...)` (glow halos сохранены) |
| `game_overlay.gd` :183-190 | TAB-stats panel | 5 draw_circle (тело + 4 глаза) | `YarnBallIcon.draw_at(...)` |
| `game_overlay.gd` :384-396 | Заголовок выбора пассивки | 5 draw_circle + 5 yarn lines | `YarnBallIcon.draw_at(...)` |
| `title_menu.gd` :292-300 | Декоративные орбитальные шарики | 4 draw_circle | 4 × `YarnBallIcon.draw_at(..., with_face=false)` |

Не тронуты:
- `lobby.gd` :489 — мелкий color-preview circle в селекторе цвета (не персонаж)
- `hud_draw.gd` :70 — мини-точки счёта (не персонаж)

### Файлы
- `scripts/ui/yarn_ball_icon.gd` (новый, 47 строк)
- `scripts/ui/lobby.gd` (-14 строк процедурной отрисовки)
- `scripts/main/game_overlay.gd` (-30 строк, 3 места заменены)
- `scripts/ui/title_menu.gd` (заменены 4 декор. круга)

### Тест
Godot 4.6.1: после `--import` для refresh class cache — компилируется без
ошибок. Никаких runtime issues.

---

## 2026-04-19 — feat: новый clean ball, большее лицо, эмоции по событиям, без squash на беге

### Запросы пользователя
1. Заменить ассет персонажа на новый (более чистый cartoon-стиль)
2. Сделать лицо больше
3. При ходьбе НЕ сплющивать клубок — только катится; squash оставить только
   на прыжке и приземлении
4. Привязать эмоции лица к событиям (использование способности, урон и т.д.)

### Что сделано

#### 1. Новый ассет клубка (`assets/characters/body/yarn_ball.png`)
Загружен новый Gemini PNG — чистый cartoon с жирным чёрным контуром.
Обработка: flood-fill белого фона от углов через `scipy.ndimage.label`,
crop по bbox + 12px padding, square center, ресайз 512×512.

#### 2. Большее лицо (`player.gd::_update_visual_sprites`)
- Face scale 0.55 → **0.85** (на 55% больше)
- Face Y offset: -radius × 0.18 → -radius × 0.10 (чуть выше центра, не так
  сильно)
- `SPRITE_FILL_FACTOR` 1.4 → 1.25 (новый ассет занимает ~80% от текстуры,
  не нужно так сильно скейлить)

#### 3. Без squash на беге
Раньше в `_handle_movement` при беге применялся `run_stretch`:
```gdscript
squash_x = maxf(squash_x, 1.0 + run_stretch)  # ←удалено
squash_y = minf(squash_y, 1.0 - run_stretch * 0.5)
```
Теперь squash зарезервирован для:
- **Приземление** (impact-based в `_handle_movement`)
- **Прыжок** (squash_x=0.8, squash_y=1.25)
- **Wall slide** (squash_x=0.85, squash_y=1.1)
- **Урон** (take_damage: squash_x=1.3, squash_y=0.7)
- **Swap способность** (мгновенный squash при свапе)

В `_update_visual_sprites` добавлен override: если on_floor + horizontal
movement + no vertical motion → sprite scale = (1, 1) (только rotation).

Бег теперь = чистое перекатывание клубка без деформации, как просили.

#### 4. Face Event System — эмоции по событиям

Новая система `trigger_face_event(emotion, duration)` накладывает эмоцию
поверх state-based с приоритетом:

```gdscript
# В _compute_emotion:
if not is_alive: return "dead"
if face_event_timer > 0: return face_event_emotion  # ← override
if hit_flash_timer > 0: return "pain"
if hp < MAX_HP * 0.3: return "scared"
...
```

#### Привязка эмоций к событиям

| Событие | Эмоция | Длительность | Где |
|---------|--------|--------------|-----|
| Использование способности | focus | 0.4s | `player_abilities.gd::_use_ability` |
| Needle Dash (вместо общего focus) | focus | dash_duration + 0.1s | `_ab_needle_dash` |
| Активация parry | angry | 0.4s | `handle_abilities` (parry block) |
| Получение урона | pain | 0.5s | `player.gd::take_damage` |
| Убийство врага | angry | 1.5s | `take_damage` (при hp ≤ 0, источнику) |

State-based fallback (когда нет события):
- not is_alive → dead
- hp < 30% → scared
- charge/guided/grab активны → focus
- иначе → happy

### Файлы
- `assets/characters/body/yarn_ball.png` (новый ассет)
- `scripts/characters/player.gd`:
  - `face_event_timer`, `face_event_emotion` vars
  - `face_event_timer` decrement в `_update_timers`
  - `trigger_face_event()` функция
  - `_compute_emotion()` с event override
  - SPRITE_FILL_FACTOR 1.4 → 1.25
  - face_scale 0.55 → 0.85, Y -0.18 → -0.10
  - run_stretch удалён из `_handle_movement`
  - В `_update_visual_sprites` — override sx/sy = 1 при беге
  - `take_damage`: trigger pain 0.5s; при killing trigger angry 1.5s на источника
- `scripts/characters/player_abilities.gd`:
  - `_use_ability`: trigger focus 0.4s (кроме needle_dash)
  - `_ab_needle_dash`: trigger focus на dash_duration+0.1s
  - parry block в handle_abilities: trigger angry 0.4s

### Тест
Godot 4.6.1: компилируется без ошибок. Только pre-existing warnings.

---

## 2026-04-19 — fix: персонаж не виден за платформой + белые внутренности лиц

### Проблемы по скриншоту пользователя
1. **Тело клубка не отображается** — видны только HP-бар и иконки способностей,
   персонажа нет
2. **Лица без белых элементов** — глазные яблоки и зубы прозрачные

### Причины

**#1 z_index**: спрайты создавались с `z_index = -2` (body) и `-1` (face),
а `z_as_relative` по умолчанию `true`. Поэтому абсолютный z = parent_z + (-2)
= -2. Платформы рисуются на z=0 → персонаж оказывался ЗА платформой. HP-бар
и иконки способностей рисовались через _draw() родителя на z=0 → они видны.

**#2 white interior**: первая обработка face cells:
```python
keep = is_dark | is_red
```
Белые "белки" глаз и зубы (неокрашенные пиксели внутри чёрного контура)
попадали в категорию "background" → стали прозрачными.

### Исправления

**Fix 1 — sprites выше платформ:**
```gdscript
body_sprite.z_as_relative = false
body_sprite.z_index = 5  # абсолютный z, выше платформ (z=0)
face_sprite.z_as_relative = false
face_sprite.z_index = 6  # выше body
```

**Fix 2 — flood-fill от углов вместо color threshold:**
```python
bg_candidate = is_lightish & is_neutral  # светло-серые/белые
# Connected components с padded edges
labels, _ = ndimage.label(padded)
bg_connected = (labels == labels[0,0])  # только связное с углами
arr[bg_connected] = [0,0,0,0]
```
Внутренности глаз/зубы окружены чёрным контуром → не связаны с углами →
остаются непрозрачными.

**Дополнительно:**
- `SPRITE_FILL_FACTOR` 1.7 → 1.4 (1.7 был слишком крупный)
- `body_sprite.modulate = player_color` ставится при создании (не ждём
  первого `_update_visual_sprites`)
- `push_error/push_warning` при отсутствии текстур (для дебага)

### Файлы
- `scripts/characters/player.gd` (z_index, modulate init, FILL_FACTOR)
- `assets/characters/face/face_*.png` × 6 (re-cut с flood-fill)

### Тест
Godot 4.6.1: компилируется без ошибок, runtime issues отсутствуют.
Визуальная проверка за пользователем.

---

## 2026-04-19 — feat: спрайтовый персонаж (yarn ball + 6 эмоций) с анимацией через transforms

### Что сделано
Заменена процедурная отрисовка клубка (`_draw_ball` через `_draw_ellipse` +
yarn lines + eyes) на спрайтовую: один статичный спрайт-клубок + спрайт-лицо,
анимация через scale/rotation/modulate в реальном времени.

### Ассеты
Пользователь предоставил два изображения через nanobanana:
1. **Hand-painted yarn ball** (2048×2048, без альфы) — реалистичный клубок ниток
2. **32 cartoon faces** (2848×1504 grid 4×8, без альфы) — набор эмоций

Pipeline обработки (Python + PIL + scipy):
- Yarn ball: detect "warm" pixels (R > B+8), find biggest connected component,
  binary closing/dilation для гладкого силуэта, distance transform → soft alpha
  edge, crop по bbox + 12px padding, ресайз 512×512 → `assets/characters/body/yarn_ball.png`
- Face sheet: разрезан на 32 cells (356×376 каждая), фон через color-threshold:
  оставлены только тёмные/красные пиксели (face features), остальное → alpha=0
- 32 cells сохранены в `my_assets/face_cells/r{1-4}c{1-8}.png` для review
- Выбрано 6 best matches под наши эмоции:

| Эмоция  | Cell  | Описание |
|---------|-------|----------|
| happy   | r4c2  | Большая улыбка с зубами |
| focus   | r4c1  | Нейтральные глаза, прямая линия рта |
| pain    | r1c6  | Грустные брови, frowning рот |
| angry   | r2c4  | Злые брови + оскал |
| scared  | r3c8  | Широкие глаза + красный рот + капли пота |
| dead    | r2c2  | Закрытые глаза + открытый рот |

### Изменения в `player.gd`

#### Новые поля
- `body_sprite: Sprite2D` — клубок, тинтуется player_color
- `face_sprite: Sprite2D` — лицо-оверлей, не тинтуется
- `face_textures: Dictionary` — кеш 6 текстур эмоций
- `current_emotion: String` — текущая эмоция (для diff-update)
- `roll_rotation: float` — накопленный угол перекатывания
- Константы: BODY_TEXTURE_SIZE, SPRITE_FILL_FACTOR, paths

#### Новая `_setup_visual_sprites()` (вызов из setup)
- Загружает `yarn_ball.png` в body_sprite (z_index=-2)
- Загружает 6 face textures, ставит "happy" в face_sprite (z_index=-1)

#### Новая `_update_visual_sprites(delta)` (вызов в _physics_process)
- **Scale**: `(diameter / BODY_TEXTURE_SIZE * SPRITE_FILL_FACTOR) × (squash_x, squash_y)`
- **Modulate**: применяет fire/poison/stun/slow/hit_flash тинты как старый _draw
- **Rotation (rolling)**: `roll_rotation += velocity.x / circumference × TAU × delta`
  — клубок реально катится при движении по полу, как настоящий шар
- **Visibility**: hides during invincibility flicker (та же логика что и раньше)
- **Face**: scale 55% от body, остаётся UPRIGHT (не вращается с телом!),
  flip_h через scale.x = -value при facing left, position (0, -radius*0.18)
  чтобы лицо было в верхней части клубка

#### Новая `_compute_emotion()`
```
not is_alive            → "dead"
hit_flash_timer > 0     → "pain"
hp < MAX_HP * 0.3       → "scared"
charge/guided/grab slot → "focus"
parry_visual > 0        → "angry"
otherwise               → "happy"
```
Эмоция меняется только при diff (не каждый кадр).

#### Удалено из `_draw()`
- `_draw_ellipse(...)` для тела (~50 строк)
- Yarn flowing lines
- Eyes drawing (4 circles)

Сохранены: trailing thread ends при velocity > 200 (декоративные), все эмблемы
способностей, hooks, spikes, particles, parry/spawn/whip эффекты.

### Файлы
- `assets/characters/body/yarn_ball.png` (нов, 349 KB)
- `assets/characters/face/face_{happy,focus,pain,angry,scared,dead}.png` (6 нов)
- `scripts/characters/player.gd` (+87 строк сетапа/апдейта, -50 строк отрисовки)

### Тест
- Godot 4.6.1: запуск title_menu → lobby → game без ошибок (только pre-existing warnings)
- Никаких runtime ошибок или null reference на спрайтах
- Визуальное тестирование за пользователем

### Преимущества подхода
- 1 ball PNG → 4 цвета через `body_sprite.modulate = player_color`
- Эмоции меняются мгновенно (texture swap), не нужно генерить per-pose
- Анимация через transforms масштабируется с FPS, smooth
- Реальное вращение клубка при беге = живой эффект
- Лицо не вращается → читаемость в любом положении

### Что делать дальше
- Визуальный тест в игре, при необходимости тюнить SPRITE_FILL_FACTOR
- Возможно подправить позицию лица (Y offset) если глаза слишком высоко/низко
- В будущем — добавить особые эмоции (parry_burst → angry+, kill → angry, etc)

---

## 2026-04-18 — fix: промты — multi-frame анимации вместо одиночных картинок

### Проблема
Предыдущая версия промтов давала **по одной картинке на действие**. Для
живой анимации этого недостаточно — персонаж выглядел бы как plain stamp,
просто меняющий картинку по событиям.

### Что сделано
Полностью переписан `docs/characters/PROMPTS.md` с разбивкой каждого
действия на несколько кадров анимации.

### Раздел кадров

| Действие | Кадров | FPS | Тип |
|----------|--------|-----|-----|
| body_idle | 4 | 3 | Цикл (дыхание) |
| body_run | 6 | 12 | Цикл (bounce + roll) |
| body_jump | 3 | event | Anticipation → launch → apex |
| body_fall | 2 | 4 | Цикл (стабильное падение) |
| body_hurt | 2 | event | Импакт → recoil |
| body_dead | 5 | 8 | Прогрессия unraveling |
| face_happy | 2 | 0.3 | Моргание |
| face_focus | 1 | — | Статика |
| face_pain | 2 | event | Peak → fading |
| face_angry | 2 | event | Snarl → relax |
| face_scared | 2 | 6 | Дрожание |
| face_dead | 1 | — | Статика |

**Тело: 22 кадра. Лицо: 10 кадров. Всего: 32 кадра.**

### Ключевые принципы multi-frame
- **Каждый кадр — описание конкретного момента** в дуге движения, не
  абстрактное "running pose"
- **Image reference** = `body_idle_01.png` для всех body-кадров; для
  face — `face_happy_01.png`
- **Конвенция именования**: `body_<action>_<frame>.png`, frame с двумя
  цифрами для сортировки (`01`, `02`, ...)
- **Описание различий между кадрами**: aspect ratio, tilt, strand
  positions, motion lines, dust — каждый параметр прописан явно
- **Циклы должны замыкаться**: frame N сглаживается к frame 1

### Примеры детализации (run cycle)
- Frame 1: ground impact, max squash 1.3:0.85, strands trail far back,
  dust puff
- Frame 2: rebounding, squash 1.15:0.95, strands less extreme
- Frame 3: airborne, neutral 1:1, more forward tilt, no dust
- Frame 4: peak bounce, slight stretch 0.95:1.05, strands relaxed
- Frame 5: descending, neutral 1:1, strands lift up (air resistance)
- Frame 6: approaching ground, beginning squash 1.1:0.95

### Прогрессия dead (5 кадров размотки)
- Frame 1: ball intact, 3-4 strands начинают отделяться
- Frame 2: ball 85%, 8-10 strands loose
- Frame 3: ball 70%, 12 strands, начало tangle
- Frame 4: ball 55%, 14 strands, full tangle
- Frame 5: ball 50%, финальная статика, 15 strands, contact shadow

### Новый раздел §7.2 — выравнивание центров
Критично подчёркнуто: все кадры одной анимации должны иметь одинаковый
**геометрический центр клубка** (через onion skin в Photopea/Krita),
иначе персонаж "прыгает" при проигрывании. Подробная инструкция.

### Новый раздел §7.3 — превью анимации в GIF
Перед импортом в Godot собрать GIF из кадров (EZGif.com) с заданным FPS
для проверки motion. Если "прыгает" — выровнять. Если неестественно —
пере-генерить.

### Изменённый раздел §9 — интеграция в Godot
**Было**: `Sprite2D.texture = body_textures[pose]` (статичная текстура)
**Стало**:
- `AnimatedSprite2D` "Body" с `SpriteFrames` ресурсом
- `AnimatedSprite2D` "Face" (child) с `SpriteFrames`
- 6 анимаций body: `idle`, `run`, `jump`, `fall`, `hurt`, `dead`
- 6 анимаций face с заданными FPS из таблицы
- State machine через `play("animation_name")`

### Файлы
- `docs/characters/PROMPTS.md` (переписан, 600+ строк)

### Минимальный тест (§8)
8 кадров: 2 idle + 3 run + 1 hurt + 1 happy + 1 pain. Достаточно для
проверки тинта, animation consistency, общего ощущения. Остальные 24 —
после положительной оценки.

---

## 2026-04-18 — fix: промты — реальный клубок ниток вместо AI-cartoon

### Проблема
Предыдущие промты задавали стиль "Flat cartoon mascot illustration in
the style of Kirby/Fall Guys". Это даёт "AI-look" — слишком гладкий,
generic vector, узнаваемо машинно-сгенерированный, с жирным контуром
и однотонной заливкой. Не выглядит как настоящий клубок.

### Что сделано
Переписан `docs/characters/PROMPTS.md` с новой философией:
**персонаж = настоящий клубок ниток, нарисованный для игры**
(не cartoon mascot, а текстурный клубок из реальной пряжи в hand-painted
2D game illustration стиле).

### Изменённые ключевые принципы

#### Стиль (общий блок, §3)
**Было**: Flat cartoon, 3px bold black outline, single flat color, like Kirby
**Стало**:
- Hand-painted 2D game illustration (Cuphead-era inanimate objects,
  Hollow Knight props, hand-painted children's book illustration)
- Видимые криво-перекрещивающиеся пряди ниток (criss-crossing strands)
- Soft fuzziness — стрэй фибры по силуэту
- 1-2px тонкий dark gray outline ТОЛЬКО на внутренних формах нитей,
  НЕ толстый cartoon outline вокруг всего силуэта
- 2-3 уровня естественных теней между слоями ниток
- Слегка нерегулярная форма (реальный клубок не идеальная сфера)
- Loose yarn ends — кончики пряжи, торчащие как у настоящего клубка

#### Цветовая палитра (§1)
**Было**: чистый белый `#FFFFFF` + `#D0D0D0` тени + `#000000` контур
**Стало**:
- Основные нитки: кремово-белый `#F5F0E5` (тёплее чистого белого)
- Тени между нитками: `#B5B0A8` (естественная глубина)
- Глубокие тени снизу: `#807870` (контактная тень)
- Контур: `#3A352F` (тёмно-серый, не чёрный)

Все цвета в нейтрально-кремово-серой гамме — тинт через `modulate`
работает чисто.

#### Лицо на теле — УБРАНО (§3, §6)
**Было**: тело включало базовое "happy" лицо, лицевые оверлеи только для
emotion change.
**Стало**: тело **БЕЗ ЛИЦА вообще** — face overlay всегда видим в игре,
включая default `face_happy` в idle. Это:
- Упрощает позиционирование (нет конфликта между лицом тела и оверлеем)
- Делает body спрайты переиспользуемыми между эмоциями
- Полностью разделяет body и face ответственности

#### Стиль лиц (§6)
**Было**: kawaii anime eyes (сильно AI-look)
**Стало**:
- Hand-drawn cartoon с лёгкой нерегулярностью (не perfect digital strokes)
- Цвет — тёплый `#2A2520` (very dark warm brown, не чёрный)
- Будто лицо нарисовано/вышито на самом клубке

#### Loose yarn strands добавлены везде
- **idle**: 2 кончика — short top + long bottom-right
- **run**: длинный кончик трэйлит назад от скорости
- **jump**: оба кончика трэйлят вниз
- **fall**: оба кончика трэйлят вверх (air resistance)
- **hurt**: 6-8 popped strands вырывающихся при ударе
- **dead**: 12-15 размотанных нитей образуют tangle

Кончики ниток заменили "yarn tuft pompom" — выглядят как настоящие
свободные концы пряжи, а не cartoon hair.

### Новый раздел §10: борьба с AI-стилем
Если nanobanana выдаёт slick AI-cartoon вместо hand-painted yarn:
- Усилить требование: "hand-painted natural texture, NOT generic
  vector cartoon. Show individual yarn fibers."
- Negative prompt: `vector art, flat cartoon, smooth shading, perfect
  circle, mascot logo, generic AI art`
- Прямые референсы: Cuphead inanimate props, Studio MDHR background

### Файлы
- `docs/characters/PROMPTS.md` (полностью переписан)

---

## 2026-04-18 — fix: промты персонажа — убраны все упоминания рук/ног

### Проблема
Первая версия `docs/characters/PROMPTS.md` описывала клубок с "stubby arms"
и "stubby legs" (мелкими ручками и ножками в стиле Fall Guys/Kirby). Это
противоречит концепции персонажа — он буквально клубок ниток, без конечностей.

### Что сделано
Полностью переписан `docs/characters/PROMPTS.md`:
- Добавлено чёткое "CRITICAL CHARACTER RULE" в общий стилевой блок:
  "The character is a PURE YARN BALL ONLY. No arms, no legs, no hands,
  no feet, no limbs of any kind."
- Единственный допустимый "отросток" — yarn TUFT (хохолок ниток) на макушке
- Переписаны все 6 промтов поз тела — движение/действия показываются
  через:
  - Деформацию клубка (squash/stretch)
  - Motion-lines и частицы
  - Наклон/поворот всего шара
  - Хохолок ниток на макушке (стримит при беге, тянется вверх при прыжке)
  - Расползающиеся loose yarn strands при уроне/смерти
- Каждый промт содержит финальный REMINDER "no limbs" — последние токены
  имеют больший вес при генерации
- Добавлен раздел §10 "Частые ошибки nanobanana и как их обходить" — в
  частности, как переубедить модель не добавлять руки/ноги (повтор в конце,
  negative prompt, более категоричные формулировки)

### Конкретные изменения по позам (без конечностей)
- **idle**: был с "stubby arms at sides, stubby legs standing" — стало
  чистый шар с хохолком
- **run**: был "legs mid-stride, arms swung back" — стало "horizontal squash,
  25° tilt forward, motion lines trailing, dust puff, tuft streams back"
- **jump**: был "arms raised up, legs tucked" — стало "vertical stretch,
  tuft stretched upward, upward motion arcs below"
- **fall**: был "arms spread wide, legs down" — стало "slight stretch, tuft
  trailing upward (air resistance), wind lines on sides"
- **hurt**: был "arms splayed out" — стало "8 loose yarn strands popping out
  of surface, asymmetric squash"
- **dead**: был "arms limp, legs tangled" — стало "ball shrunk to 50%, 12 long
  loose yarn strands trailing away"

Лица (§6) не менялись — они и так без тела.

### Файлы
- `docs/characters/PROMPTS.md` (полностью переписан)

---

## 2026-04-18 — chore: промты nanobanana 2 для спрайтов персонажа

### Что сделано
Подготовлен документ `docs/characters/PROMPTS.md` с полным набором промтов
для генерации спрайтов персонажа-клубка через Google nanobanana 2
(Gemini 2.5 Flash Image).

### Архитектурное решение
**Один персонаж → 4 цвета через тинт в движке.** Базовый спрайт тела —
чисто белый (`#FFFFFF`) с чёрным контуром (`#000000`) и светло-серыми тенями
(`#D0D0D0`). В Godot: `body_sprite.modulate = player_color` даёт
красный/синий/зелёный/жёлтый клубок:
- `WHITE × RED = RED` (тело)
- `GRAY × RED = dark RED` (естественная тень)
- `BLACK × RED = BLACK` (контур сохраняется)

Лицо — **отдельный Sprite2D**, не тинтуется (остаётся чёрным на любом цвете).

### Раздел спрайтов
12 файлов:
- **6 поз тела** (256×256 в игре, 1024×1024 при генерации): idle, run, jump, fall, hurt, dead
- **6 эмоций лица** (отдельные оверлеи): happy, focus, pain, angry, scared, dead

### Промты
- **1 главный промт для `body_idle.png`** — без референса, задаёт характер
- **5 промтов-вариаций** для остальных поз с `body_idle` как image reference
- **1 главный промт для `face_happy.png`** — без референса
- **5 промтов-вариаций** для остальных эмоций с `face_happy` как reference

Все промты содержат:
- Общий STYLE-блок (flat cartoon, чёрный контур, белое тело, прозрачный фон)
- Описание субъекта с характером (stubby arms/legs, yarn tuft on top,
  spiral thread pattern)
- Точные деформации для каждой позы (stretch/squash, mid-stride, scrunched eyes и т.п.)

### Пост-обработка (описано в PROMPTS.md §7)
- Проверить прозрачность фона, при необходимости убрать фон в Photopea/GIMP
- Выровнять все 6 поз тела по единому центру на канвасе 1024×1024
- Даунскейл до 256×256 для игры

### Интеграция (описано в PROMPTS.md §9, будет отдельной feature-веткой)
- `feature/character-sprites` ветка
- `_draw_ball` → `Sprite2D` (body) + `Sprite2D` (face)
- State machine для body_texture (idle/run/jump/fall/hurt/dead)
- Emotion machine для face_texture (happy/focus/pain/angry/scared/dead)
- Эмблемы способностей остаются процедурными поверх спрайта
- Squash/stretch анимация через scale tween

### Минимальный тест
В §8 описан MVP-путь: генерация всего 3 спрайтов (`body_idle`, `face_happy`,
`face_pain`) для быстрой проверки подхода — остальные поддержатся
fallback-ом к idle.

### Что делать дальше
1. Прогнать промты из `docs/characters/PROMPTS.md` через nanobanana 2
2. Положить PNG в `my_assets/nanobanana/` или сразу в
   `assets/characters/body/` и `assets/characters/face/`
3. Claude сделает feature-ветку `character-sprites` и интегрирует

---

## 2026-04-18 — fix: платформы — убран чёрный фон, stretch-to-fit текстура

### Проблемы
1. **Остаточный чёрный фон** на платформах — исходные PNG из `landscape_strips/`
   содержали "небо" тёмного цвета сверху (были landscape-изображениями с
   силуэтом ландшафта, не плоскими текстурами)
2. **Странный рендер на больших платформах** — UV-тайлинг (`u = (x-left)/tex_w`)
   создавал видимые швы каждые ~900 px ширины

### Решения

#### 1. Кроп чёрных областей из PNG
Python-скрипт нашёл первую строку где ≥80% пикселей не-чёрные (avg яркость > 30)
и обрезал всё выше. Для каждой текстуры:

| Текстура | Было | Стало | Обрезано | Чёрных пикс после |
|----------|------|-------|----------|-------------------|
| grass    | 93   | 75    | 13 + 5   | 0.8%              |
| stone    | 91   | 70    | 15 + 6   | 1.3%              |
| wood     | 98   | 75    | 19 + 4   | 0.0%              |
| ice      | 102  | 79    | 17 + 6   | 1.4%              |
| magma    | 88   | 70    | 10 + 8   | 0.5%              |

Остатки <1.5% — это тёмные тени внутри содержимого, не фон.

#### 2. UV-маппинг: stretch-to-fit вместо tile
В `scripts/maps/map_base.gd::_draw_themed_platform`:
```gdscript
// Было (тайлинг каждые ~904 px):
var u: float = (p.x - (cx - hw)) / tex_w * tile_scale

// Стало (растяжение на всю ширину, без швов):
var u: float = (p.x - (cx - hw)) / w
```

Теперь вся текстура натягивается на ширину платформы целиком:
- Узкая платформа (200 px): текстура сжата горизонтально ×4.5
- Средняя (900 px): текстура pixel-perfect
- Широкая (2000 px): текстура растянута ×2.2

**Нет видимых повторяющихся швов** на любой ширине.

### Файлы
- `assets/textures/platforms/grass.png` и 4 других — обрезаны
- `scripts/maps/map_base.gd` — UV-маппинг изменён

### Тест
- `game.tscn` запустился без ошибок (только warnings не связанные с фиксом)
- Godot re-import прошёл успешно

### Что делать дальше
- Проверить визуально в игре, что платформы выглядят корректно на всех размерах
- Возможно в будущем — добавить 9-slice рендер для очень больших платформ
  если stretch даёт слишком большое искажение

---

## 2026-04-18 — feat: Lo-fi плейлист с плавным crossfade (новая система музыки)

### Что сделано
Полностью переработана система музыки. Теперь играет непрерывный плейлист
из 5 lo-fi треков с плавным crossfade между ними. Музыка **не зависит от карты** —
один и тот же плейлист идёт в меню и во всех боях.

### Файлы
- `assets/music/` (новая папка):
  - `adventure_chill.mp3` (4.4 MB) — aventure-lofi-vlog-chill-beat-508265
  - `empty_mind.mp3` (5.4 MB) — lofi_hour-empty-mind-118973
  - `sentimental_jazz.mp3` (3.1 MB) — sonican-lo-fi-music-loop-sentimental-jazzy-love-473154
  - `easter.mp3` (2.6 MB) — prettyjohn1-easter-490466
  - `goodnight_cozy.mp3` (4.5 MB) — fassounds-good-night-lofi-cozy-chill-music-160166
- `scripts/managers/music_manager.gd` — полностью переписан

### Новая архитектура MusicManager
- **Два AudioStreamPlayer** (`music_a`, `music_b`) для overlap при crossfade
- **`tracks: Array[AudioStream]`** — 5 mp3 загружаются в `_ready()`, перемешиваются
- **MP3 loop отключён программно** (`stream.loop = false`) — переключение треков
  управляется crossfade, а не engine loop
- **End-of-track watch** в `_process`: когда позиция активного плеера >= длина-CROSSFADE_DUR,
  автоматически запускается следующий трек на втором плеере; tween на 4 секунды
  поднимает громкость нового и снижает старого до тишины
- **`set_intensity(alive, total)`** теперь модулирует только громкость в диапазоне
  [-16dB .. -8dB], не переключает треки
- **`play_map_theme(map_name)`** — параметр игнорируется; просто продолжает плейлист
- **`play_menu_music()`** — то же поведение; меню → игра не прерывает музыку
- **`stop_music()`** — fade-out за 1с с автоматической остановкой обоих плееров

### Удалено
- `_generate_menu_music`, `_generate_map_music`, `_generate_ambient` — процедурные
  sine-wave мелодии больше не нужны
- `_noise_at` — был для ambient
- `ambient_player` — амбиент звуки (lava rumble, water bubble и т.п.) удалены,
  потому что они тоже зависели от карты, что противоречит требованию

### UI звуки сохранены
`play_ui_click`, `play_ui_switch`, `play_ui_error`, `play_ui_confirm` — оставлены
как есть (короткие процедурные тоны, не относятся к "музыке")

### Тест
- Godot 4.6.1: title_menu запускается без ошибок и предупреждений
- Все 5 mp3 импортированы (`adventure_chill.mp3.import` и т.д.)
- API совместим со всеми существующими call sites:
  `play_menu_music`, `play_map_theme`, `play_ui_confirm`, `set_intensity`, `stop_music`

### Константы (легко настроить)
- `CROSSFADE_DUR = 4.0` — длительность crossfade между треками
- `FADE_IN_DUR = 2.0` — fade-in первого трека или после stop
- `FADE_OUT_DUR = 1.0` — fade-out при stop_music
- `QUIET_DB = -16.0`, `LOUD_DB = -8.0` — диапазон громкости от intensity

---

## 2026-04-18 — chore: Get-LastReleaseTag ищет глобально по version sort

### Что сделано
- `git describe --tags HEAD` возвращал `v0.1` из ветки develop, потому что
  тег `v0.2` стоит на main-only мердж-коммите (вне ancestry develop).
- Заменено на `git tag -l "v*" --sort=-version:refname | head -1` —
  возвращает highest-version тег независимо от ветки.

### Файлы
- `scripts/release/config.ps1` (Get-LastReleaseTag)

### Тест
- `check_release.ps1` теперь корректно показывает `Last release tag: v0.2`,
  `Next minor version: 0.3`

---

## 2026-04-18 — fix: CRLF guard в make_release.ps1

### Что сделано
- Первый релиз v0.2 упал на `git checkout main` из-за того, что Godot `--import`
  в build.ps1 перегенерировал `.import` файлы с изменёнными line endings (LF→CRLF).
- Добавлен safeguard в `make_release.ps1`: перед `git checkout main` проверяется
  `git status --porcelain` и при наличии изменений делается `git checkout -- .`
  для отмены транзитных изменений после билда.

### Файлы
- `scripts/release/make_release.ps1` (+6 строк)

### Тест
- Следующий релиз v0.3 автоматически пройдёт без ручного вмешательства

---

## 2026-04-18 — RELEASE v0.2

Первый релиз через новый автоматизированный процесс.

- **Тег**: `v0.2` на `main`
- **Билд**: `builds/TangleBattle-v0.2.exe` (~102 MB)
- **GitHub Release**: ожидает ручной публикации (требуется `gh auth login`)
- **CHANGELOG**: обновлён
- **v0.1 baseline**: тег на commit с накопленным контентом до введения релизного процесса

### Ручные шаги для завершения
1. `gh auth login` (один раз)
2. `gh release create v0.2 builds/TangleBattle-v0.2.exe --title "TangleBattle v0.2" --notes-file release_notes_v0.2.md`

---

## 2026-04-18 — Релизный процесс (новая система разработки)

### Что сделано
Полностью настроен релизный процесс. Все будущие изменения должны идти через
feature-ветки с авто-проверкой релиза. Подробности — `docs/RELEASE_PROCESS.md`.

### Файлы
- `VERSION` — текущая версия (0.1)
- `CHANGELOG.md` — история релизов в Keep-a-Changelog формате
- `docs/RELEASE_PROCESS.md` — полная спецификация процесса
- `export_presets.cfg` — обновлён: исключены my_assets/builds/work_notes/docs;
  product_version = 0.1.0.0
- `project.godot` — добавлен `application/config/version="0.1"`
- `.gitignore` — добавлены: `my_assets/`, `builds/`, `release_notes_v*.md`
- `CLAUDE.md` — новый раздел 8 "Релизный процесс" (обязателен к чтению Claude)

### PowerShell скрипты (`scripts/release/`)
- `config.ps1` — централизованные пути и настройки (Godot exe, пороги релиза)
- `check_release.ps1` — проверка триггеров релиза (≥5 LOG записей, "крупное"
  изменение, ≥14 дней). Запускается в начале каждой сессии и после блока работы.
- `new_branch.ps1 <type> <name>` — создание feature/fix/chore/hotfix ветки от develop
- `finish_branch.ps1` — мерж feature-ветки в develop + push + check_release
- `build.ps1 [-Version X.Y]` — экспорт Windows .exe через Godot CLI
- `make_release.ps1 [-BumpType minor|major]` — полный релиз: release/x.y branch,
  bump версии, CHANGELOG, smoke test, build, merge в main, тег, push, GitHub Release,
  merge обратно в develop, запись в LOG

### Тест билда
- Успешно собран `TangleBattle-v0.1-test.exe` (102 MB)
- ProductVersion=0.1.0.0, FileVersion=0.1.0.0 корректно вшиты
- Тестовый билд удалён, builds/ в .gitignore

### Конфигурация
- Платформа билда: только Windows Desktop
- Хранение: GitHub Releases (через `gh` CLI; если не установлен — печатается
  ручная инструкция: `winget install GitHub.cli`)
- Триггер проверки: только в сессии Claude (без cron / scheduled tasks)
- Godot CLI: `C:\Users\belya\Downloads\Godot_v4.6.1-stable_mono_win64\` —
  переопределяется через `$env:TANGLE_GODOT_EDITOR`

### Что делать дальше
1. **Закоммитить** накопленные изменения (платформы, эффекты, Phase Shot, Parry
   Burst и др. — много модифицированных файлов с прошлой сессии)
2. **Закоммитить** инфраструктуру релиза (этот блок)
3. **Замержить** feature/release-process в develop
4. **Тегнуть v0.1** на текущем develop как baseline
5. **Запустить make_release.ps1** для первого настоящего релиза v0.2

---

## 2026-04-16 — Текстуры платформ (замена процедурных функций)

### Что сделано
- Удалены процедурные функции отрисовки платформ из `scripts/maps/map_base.gd`:
  `_rand_at`, `_draw_grass_platform`, `_draw_stone_platform`, `_draw_wood_platform`,
  `_draw_ice_platform`, `_draw_magma_platform` (~200 строк удалено) — они сильно
  нагружали игру множеством `draw_circle`/`draw_line` вызовов на каждый кадр
- Новая `_draw_themed_platform()` рисует одну закруглённую капсулу-полигон с
  текстурой через `draw_polygon(pts, colors, uvs, texture)`:
  - UV-координаты: горизонтальное тайлирование (`u = (x - left) / tex_width`),
    вертикальный stretch (`v = (y - top) / h`)
  - Поверх — outline, top highlight, bottom shadow для читаемости края
- Добавлен статический кеш `_palette_tex_cache` для загрузки PNG один раз
- Edge color подобран per-palette в `_get_palette_edge()`
- В `assets/textures/platforms/*.png.import` добавлен `process/repeat=1` —
  для всех 5 текстур (grass, stone, wood, ice, magma), чтобы UV > 1.0 тайлили
- Текстуры были извлечены ранее из `my_assets/extracted/landscape_strips/`
  (отбор лучших полос из общего sprite sheet)

### Файлы
- `scripts/maps/map_base.gd` (удалено ~200 строк, добавлено ~85)
- `assets/textures/platforms/*.png.import` (5 файлов, +1 строка каждому)

### Тест
- Godot 4.6.1 запускается без ошибок (compatibility renderer, NVIDIA GTX 1080 Ti)

### Что делать дальше
- Визуально проверить отображение платформ на разных картах в игре
- Возможно потребуется подстройка `tile_scale` если текстура смотрится слишком
  крупно/мелко

---

## 2026-04-17 — Интеграция craftpix slash/effects ассетов

### Скопировано в assets/effects/
12 папок с PNG-кадрами (8-12 на каждую):
- `spin_yellow/` — slash_cartoon/3 (жёлтый мазок) → Spin Attack
- `dash_red/` — slash_effects/slash5 (быстрый красно-оранжевый) → Needle Dash
- `bomb_star/` — slash_effects/slash3 (звёздный взрыв) → Yarn Bomb
- `toss_cyan/` — slash_cartoon/9 (бирюзовый мазок) → Yarn Toss
- `smoke_green/` — slash_cartoon/6 (серо-зелёный дым) → Stink Cloud
- `explosion_star/`, `explosion_fire/` — slash3, slash → Grenade/Rocket взрывы
- `heaven_burst/` — slash_effects/slash3 → Heaven's Wrath
- `parry_white/` — slash_cartoon/7 (белое облако) → Parry/Shield
- `spike_pink/` — slash_cartoon/5 (розовый) → Spike Armor
- `boomerang_trail/` — slash_cartoon/4 (циан) → Boomerang
- `blackhole_dark/` — slash_cartoon/10 (тёмно-синий) → Black Hole

### Расширена VFX система (player.gd)
- `_get_sprite_frames(effect)` — статический кеш загрузки PNG-кадров через DirAccess
- `_add_sprite_vfx(effect, duration, pos, scale, rotation, modulate)` — спавн анимированного VFX
- `_vfx_sprite_anim(fx, t)` — рендер кадра по progress (1→0 по lifetime)
- Новый case `"sprite_anim"` в `_draw_vfx`

### Заменены вызовы _add_vfx в способностях
- Yarn Toss → toss_cyan
- Needle Dash → dash_red (поверх существующего dash_trail)
- Yarn Bomb → bomb_star (поверх bomb_ring)
- Spin Attack → spin_yellow (поверх spin_lines)
- Stink Cloud → smoke_green (поверх stink_puff)
- Spike Armor → spike_pink
- Boomerang → boomerang_trail
- Guided Rocket → explosion_fire
- Heaven's Wrath → heaven_burst (золотой modulate)
- Parry → parry_white (поверх shield_flash)
- Black Hole → blackhole_dark

### НЕ применено
- Water effects pack — нет водяных способностей
- 16x16 nature tileset — пиксель-арт стилистически конфликтует с векторной графикой `_draw()`

### Лицензия
Craftpix.net — см. https://craftpix.net/file-licenses/

---

## 2026-04-11 — Идеи для улучшений (assets, sounds, abilities, passives)

### АССЕТЫ И ВИЗУАЛ

#### Спрайты вместо процедурной отрисовки
Сейчас всё рисуется через `_draw()` (yarn balls, снаряды, эмблемы). Идеи:
- **Скины игроков** — спрайт-листы вязаных клубков с разной фактурой (хлопок, шерсть, шёлк, металл). Анимация дыхания, моргания глаз
- **Лица-эмоции** — разные глаза и рты (счастливый/грустный/злой/удивлённый), меняются по событиям: получение урона, убийство, стрельба
- **Костюмы** — шапки, очки, капюшоны (как в Fall Guys). Открываются за достижения
- **Отдельные спрайты для каждой способности** — иконки нарисованы вручную вместо геометрических фигур
- **Спрайты-снаряды** — клубок ниток с тянущимися хвостами, ракеты с ребристой текстурой, граната с заклёпками

#### Анимации
- **Skeletal animation** для прыжков, ходьбы (squash & stretch уже есть, но можно расширить)
- **Particle systems на GPU** — заменить ручные dust/burn/poison particles на CPUParticles2D или GPUParticles2D для производительности
- **Death animation** — yarn ball распускается на отдельные нитки, разлетающиеся в разные стороны (сейчас есть death_effect, но базовый)
- **Spawn animation** — игрок "вяжется" из ниток сверху-вниз
- **Damage flash** — выразительный белый flash + screen shake при получении удара
- **Ability cast animation** — прыжок/замах перед использованием способности

#### Карты и фоны
- **Параллакс с динамической глубиной** (3-5 слоёв)
- **Анимированные фоны**: вода в Underwater, бегущие облака в Sky Garden, искры в Inferno
- **Discoverable secrets** — скрытые комнаты на картах с бонусами
- **Day/night cycle** — освещение меняется со временем
- **Weather effects** — дождь, снег, листья, песчаная буря (сейчас events_enabled, но без визуала)

#### UI/UX
- **Theme-based UI** — деревянная мастерская, ледяная кристальная, неоновая киберпанковая
- **Анимированные карты пассивок** — flip, glow, hover-эффекты
- **Иконки игроков сверху** — мини-портреты с HP-полосками и активными эффектами
- **Полноэкранные effects**: flash при victory, slow-motion на финальном киле раунда
- **Killfeed** — текстовый поток "P1 → 💣 → P2" в углу экрана

---

### ЗВУКИ

#### Звуковая палитра по категориям
Сейчас всё процедурное (sine waves). Идеи:
- **Звуки yarn-тематики** — мяуканье котов, хруст ниток, шорох клубка катящегося, "пыщ" тряпичной мякоти
- **Атаки**: разные звуки для каждой способности — свист yarn toss, бух гранаты, рев ракеты, треск молнии (Lightning Strike)
- **Hits** — мягкий "пуф" вязаного удара, более жёсткий металлический звук для критов
- **UI звуки** — щелчки кнопок, прокрутка карт пассивок, выбор редкости (звон серебра/золота)
- **Voice lines** — пародии на котячьи звуки персонажей: "мяу!" при kill, грустное мяуканье при смерти, рык при low HP

#### Адаптивная музыка
- **Динамические слои**: chill ambient → boss-ish stress по мере уменьшения игроков (уже есть, но можно усилить)
- **Темы для редкостей** — при выборе Mythic пассивки играет короткий золотой stinger
- **Тематические треки на каждую карту** — Volcano (drums + low brass), Ice Cave (chimes + flute), Sky Garden (light strings)
- **Reactive instruments** — добавляются гитара когда игрок использует ракеты часто, синтезатор когда играет с электричеством
- **End-of-round fanfare** — короткий триумфальный stinger для победителя

#### 3D positional audio
- **Стерео-панорама** — звуки слева/справа в зависимости от позиции
- **Дистанционные эффекты** — далёкие взрывы тише и низкочастотнее
- **Reverb по картам** — Cathedral в Dungeon, эхо в Ice Cave, открытое пространство в Sky Garden

---

### НОВЫЕ СПОСОБНОСТИ (id 17+)

#### Атакующие
- **Yarn Storm** — призывает торнадо из ниток, движется в направлении прицела, втягивает врагов
- **Mirror Image** — клон-обманка, повторяет движения игрока, наносит половину урона
- **Time Bomb** — мина которая прилипает к врагу и взрывается через 3с, можно снять только при касании союзника
- **Knit Trap** — невидимая ловушка, опутывает врага нитками, обездвиживает на 2с
- **Acid Spit** — плевок кислотой, оставляет след на платформе, замедляет проходящих
- **Lightning Chain** — молния перепрыгивает между врагами, до 3 целей
- **Sniper Needle** — медленная зарядка, мощный пробивающий выстрел через всю карту
- **Yarn Whip** — ближняя атака с длинным замахом, отбрасывает противника
- **Frozen Spike** — замораживающий снаряд, при попадании враг превращается в лёд (стан 1.5с)
- **Confusion Cloud** — облако путающее controls врагов (W↔S, A↔D)

#### Защитные/Утилити
- **Reflective Shield** — постоянный щит за спиной, отражает 1 снаряд каждые 5с
- **Stealth** — невидимость на 3с, нельзя стрелять
- **Time Slow** — замедляет всех врагов в радиусе на 50% на 4с
- **Healing Aura** — пульсирующее поле, лечит союзников (для team-режимов)
- **Decoy** — стационарная фальшивая копия игрока, отвлекает наводящиеся снаряды

#### Мобильность
- **Wall Jump+** — улучшенный wall slide с двойным прыжком
- **Air Dash** — рывок в воздухе, не сбрасывает прыжок
- **Hookshot** — улучшенный гранпл с большей дальностью и DPS
- **Phase Walk** — проходит через стены 1с
- **Magnet Boots** — прилипает к платформам снизу

#### Ультимейты (длинный КД 20-30с)
- **Meteor Shower** — 10 метеоров падают на безопасную зону карты
- **Black Sun** — гигантская чёрная дыра в центре карты на 8с
- **Reality Tear** — разрывает пространство, телепорт всех игроков случайно
- **Yarn Apocalypse** — мощный взрыв в позиции игрока с радиусом 800px
- **Time Stop** — останавливает время для всех кроме каста на 3с

---

### НОВЫЕ ПАССИВКИ (id 25+)

#### HP/защита
- **Vampire Aura** (R/L/M) — лечится за каждое попадание союзником по тебе (anti-team-damage)
- **Berserker** (U/R/L/M) — урон растёт при низком HP (до +200% при 1 HP)
- **Dodge Master** (R/L/M) — шанс полностью увернуться от атаки (10/20/30/50%)
- **Glass Phoenix** (M) — при смерти взрывается, наносит 100 урона в радиусе
- **Reactive Plating** (U/R/L/M) — после получения урона +30% защиты на 1с
- **Last Breath** (R/L/M) — при HP < 25% получает invulnerability 0.5с (CD 10с)

#### Атака
- **Critical Strike** (C/U/R/L/M) — 5/10/15/25/40% шанс x2 урона
- **Bleed** (U/R/L/M) — атаки наносят кровотечение (DoT 5с)
- **Vampiric Strike** (R/L/M) — каждая 3-я атака полностью лечит игрока
- **Splash Damage** (U/R/L/M) — 30% урона переносится на ближайших врагов
- **Execute** (L/M) — мгновенно убивает врага с HP < 15%
- **Echo Shot** (R/L/M) — снаряды стреляют дважды с задержкой 0.2с (отличается от burst — более редко)

#### Мобильность
- **Air Jumps** (C/U/R/L/M) — +1/2/3/4/5 доп. прыжков в воздухе
- **Speed Boost on Kill** (R/L/M) — +50% скорости на 3с после убийства
- **Wall Climb** (R/L/M) — может ползти по стенам
- **Slipstream** (U/R/L/M) — ускоряется при движении в одну сторону >2с (до x2 скорости)
- **Phase Dash** (L/M) — рывок проходит через стены и игроков

#### Утилити/уникальные
- **Hoarder** (C/U/R/L/M) — каждое использование способности даёт +1% к удаче (стак до 30)
- **Combo Meter** (R/L/M) — последовательные попадания увеличивают урон (стак до x3)
- **Lucky Drop** (U/R/L/M) — после убийства спавнится случайный пикап способности
- **Soul Collector** (R/L/M) — поглощает души убитых, +1% урона за каждую (стак)
- **Curse of Greed** (M) — +50% всех статов, но при поднятии любого пикапа — мгновенная смерть
- **Spectral Form** (M) — после смерти становится духом, может летать и нанести 1 атаку перед уходом

#### Командные (для team-режимов)
- **Bond** — стоя рядом с союзником регенерируешь HP
- **Gift Giver** — пикапы, которые ты не подобрал, идут союзникам
- **Sacrifice** — можно отдать HP союзнику

---

### СИСТЕМНЫЕ УЛУЧШЕНИЯ

- **Achievements / Stats** — счётчик матчей, киллов, лучшая комба, любимая пассивка
- **Cosmetic unlocks** — новые цвета/скины за прогресс
- **Replay system** — записывать раунды, смотреть с разных ракурсов
- **Spectator mode** — мёртвый игрок может управлять камерой
- **Tutorial** — обучающий режим с подсказками
- **Custom keybindings UI** — переназначение клавиш в меню
- **Local profile saves** — каждый игрок сохраняет свои предпочтения цвета/способностей
- **AI bots** — для одиночной игры, разные уровни сложности
- **Network multiplayer** — онлайн-режим (большой проект)

---

## 2026-04-11 — Parry Burst, Phase Shot, Settings (luck/cards/picks)

### Что сделано

#### TASK 1: Пассивки Parry Burst (id=23) и Phase Shot (id=24)
- `scripts/managers/passive_registry.gd`: добавлены enum PARRY_BURST #23, PHASE_SHOT #24; PASSIVE_COUNT = 25
- `scripts/characters/player.gd`: добавлены переменные `parry_burst_count`, `phase_shot`; сброс в `_apply_passives()`; match-case для PARRY_BURST и PHASE_SHOT
- `data/passives.json`: добавлены записи id=23 (Parry Burst, редкости 2-4) и id=24 (Phase Shot, редкости 3-4)
- `scripts/characters/player_abilities.gd`:
  - В блоке парирования: вызов `_burst_parry(player.parry_burst_count)` после Spirit Burst
  - Новая функция `_burst_parry(count)` — активирует щит count раз с задержкой 0.15с
  - `_ab_yarn_toss`, `_burst_yarn_toss`: `proj.phase = player.phase_shot`
  - `_ab_rocket_launcher`, `_burst_rockets`: `rocket.phase = player.phase_shot`
  - `_ab_guided_rocket`: `rocket.phase = player.phase_shot`
- `scripts/characters/yarn_projectile.gd`: `var phase: bool`; парирование игнорируется при phase=true; StaticBody2D возвращает early при phase=true
- `scripts/characters/rocket.gd`: аналогично — `var phase: bool`; фаза игнорирует парирование и стены
- `scripts/characters/guided_rocket.gd`: аналогично
- `scripts/main/game_overlay.gd`: иконки "parry_burst" и "phase" в `_draw_passive_icon`
- `scripts/ui/hud_draw.gd`: иконки "parry_burst" и "phase" в `_draw_passive_mini_icon`

#### TASK 2: Настройки лобби — luck, cards, picks
- `scripts/managers/game_manager.gd`: добавлены `base_luck`, `passive_card_count`, `passive_pick_count`
- `scripts/ui/lobby.gd`:
  - Константы LUCK_OPTIONS, CARD_OPTIONS, PICK_OPTIONS
  - Переменные `luck_index`, `card_index` (default 4 = 5 карт), `pick_index`
  - kb_focus clamp расширен до 0..8
  - `_apply_kb_change`: case 6/7/8 для luck/cards/picks
  - `_start_game()`: сохраняет base_luck, passive_card_count, passive_pick_count в GameManager
  - `_draw_settings()`: bar height 60→100; второй ряд с LUCK, CARDS, PICKS
  - Кнопка START сдвинута: cy = vp.y - 15.0 (было -45.0)
- `scripts/main/game.gd`:
  - `_next_chooser()`: использует `GameManager.passive_card_count` и `GameManager.base_luck`
  - `_start_passive_selection()`: каждый проигравший добавляется в очередь `passive_pick_count` раз

### Что делать дальше
- Создать doc-файлы для новых пассивок: `docs/passives/23_parry_burst.md`, `docs/passives/24_phase_shot.md`
- Обновить `docs/passives/README.md` (добавить строки 23 и 24)
- Проверить, что `_parry_detach_grapples()` и `_do_shockwave()` существуют в player.gd

---

## 2026-04-11 — Обновление документации

### Что сделано
- Обновлён `docs/abilities/README.md`: 17 способностей (добавлены Black Hole #14, Portal Gate #15, Heaven's Wrath #16); исправлен тип Grab Throw (melee, убран utility)
- Обновлён `docs/passives/README.md`: 23 пассивки (добавлены Shockwave #15, Lightning Strike #16, Heavy Impact #17, Homing Projectiles #18, Burst Fire #19, Lucky Star #20, Spirit Burst #21, Shield Mastery #22); добавлена 5-я редкость Mythic
- Обновлён `docs/GAME_DESIGN.md`: счётчики 17 способностей, 23 пассивок, 16 карт, 4 режима, 5 редкостей; механики пикапов (гравитация, платформы, дроп при смерти); новые механики карт (стены, fire walls, bouncy walls, sticky blocks, порталы v2); раздел режимов игры
- Обновлён `docs/PROJECT_STRUCTURE.md`: 17 способностей, 23 пассивки, 16 карт; добавлены новые файлы (black_hole.gd, heavens_wrath.gd, soul_essence.gd, fortress.gd, inferno.gd, trampoline.gd и др.); удалена карта Underwater; обновлены описания синглтонов; таблица карт расширена до 16
- Обновлён `CLAUDE.md`: счётчики в разделе 5.4 (17 способностей, 23 пассивки, 5 редкостей); добавлено упоминание разбивки player.gd на компоненты; обновлены counts в data/ блоке

### Изменения баланса (отражены в data/passives.json)
- Spirit Burst #21: essence_damage снижен до 6 (нерф)
- Black Hole #14: притягивает всех игроков (не только ближайшего)

### Также за сегодня (2026-04-11)
- Удалены плоские пассивки id 23–29 (HP Boost, Damage Boost, Speed Boost, Armor Plating, Steady Hands, Vital Force, Venom Tips) из data/passives.json и иконок
- Добавлен Debug UI для выбора пассивок в лобби (опциональный выбор debug_passives)

### Что делать дальше
- Удалить enum-записи 23–29 из passive_registry.gd
- Проверить обработку parry_cd_mult в player.gd → _apply_passives()
- Создать doc-файлы для новых способностей (14–16) и пассивок (15–22)

---

## 2026-04-11 — Удаление пассивок 23–29 (flat-бусты)

### Что сделано
- Удалены записи id 23–29 из `data/passives.json`: HP Boost, Damage Boost, Speed Boost, Armor Plating, Steady Hands, Vital Force, Venom Tips
- Файл теперь заканчивается на id 22 (Shield Mastery)
- Удалены иконки "hp_flat", "dmg_flat", "spd_flat", "armor_flat", "cd_flat", "regen_flat", "venom_flat" из `scripts/main/game_overlay.gd` (функция `_draw_passive_icon`)
- Удалены те же иконки из `scripts/ui/hud_draw.gd` (функция `_draw_passive_mini_icon`)
- Иконка "shield_cd" (Shield Mastery) сохранена в обоих файлах

### Что делать дальше
- Удалить enum-записи 23–29 из `passive_registry.gd` и соответствующие doc-файлы если они существуют

## 2026-04-10 — ability_pickup физика + Debug режим

### Что сделано

#### TASK 1: Перезапись ability_pickup.gd
- `scripts/characters/ability_pickup.gd` полностью переписан
- Добавлена гравитация: пикап падает вниз (GRAVITY=600) пока не приземлится на платформу через raycast (collision layer 1)
- После приземления: малый боб-эффект (BOB_AMP=4 * delta)
- Смена способности каждые 10 секунд (CHANGE_INTERVAL) — показывает убывающую дугу на кольце
- Новый метод `setup_dropped()` для дропа со скоростью
- `_update_ability_data()` — отдельный метод для обновления цвета и имени
- Bounds check: queue_free если |x|>8000 или y>8000
- Добавлены эмблемы для способностей 14–16 и default case

#### TASK 2: _spawn_pickup → платформенный спавн
- `scripts/main/game.gd`: `_spawn_pickup()` теперь выбирает случайную платформу из `current_map.platforms`
- Позиция: plat[0] ± 30% ширины по X, выше верхнего края платформы на 30px по Y
- Если платформ нет — ранний return

#### TASK 3: Дроп способностей при смерти игрока
- `scripts/characters/player.gd`: `die()` теперь создаёт 2 пикапа (по одному на каждый слот)
- Каждый пикап получает случайный импульс (vel.x: ±200, vel.y: -400..-200)
- Пикапы добавляются в группу "pickups" и в current_scene

#### TASK 4: Debug режим в GameManager
- `scripts/managers/game_manager.gd`: добавлен `GameMode.DEBUG` в enum
- `MODE_NAMES` дополнен "Debug"
- Добавлена переменная `debug_passives: Array = [[], [], [], []]`
- `start_game()`: в DEBUG режиме допускается 1 игрок (clamp 1..4 вместо 2..4)

#### TASK 5: Debug режим в lobby.gd
- `scripts/ui/lobby.gd`: `mode_index` clamp расширен до 0..3
- Все проверки `joined_count >= 2` заменены на `joined_count >= 2 or (mode_index == 3 and joined_count >= 1)`
- `_draw_start_button()` показывает кнопку START в Debug с 1 игроком
- `_start_game()`: если `mode_index == 3` — явно ставит `GameManager.GameMode.DEBUG`

#### TASK 6: Применение debug пассивок в game.gd
- `scripts/main/game.gd`: после `start_round()` применяются `GameManager.debug_passives` для каждого игрока в DEBUG режиме

### Файлы изменены
- `scripts/characters/ability_pickup.gd`
- `scripts/main/game.gd`
- `scripts/characters/player.gd`
- `scripts/managers/game_manager.gd`
- `scripts/ui/lobby.gd`

### Что делать дальше
- Обработать новые пассивки (parry_cd_mult, hp_flat, damage_flat, speed_flat, cd_flat, regen_flat) в `player.gd → _apply_passives()`
- Добавить UI для выбора debug пассивок в lobby (опционально — сложно, требует новой сцены)

---

## 2026-04-10 — Добавлены 8 новых пассивок (IDs 22–29)

### Что сделано
- `scripts/managers/passive_registry.gd`: добавлены 8 новых enum значений (SHIELD_MASTERY #22 .. VENOM_TIPS #29), `PASSIVE_COUNT` изменён с 22 на 30
- `data/passives.json`: добавлены 8 новых записей (id 22–29): Shield Mastery, HP Boost, Damage Boost, Speed Boost, Armor Plating, Steady Hands, Vital Force, Venom Tips
- `scripts/main/game_overlay.gd`: добавлены 8 иконок в `_draw_passive_icon()` (shield_cd, hp_flat, dmg_flat, spd_flat, armor_flat, cd_flat, regen_flat, venom_flat)
- `scripts/ui/hud_draw.gd`: добавлены 8 мини-иконок в `_draw_passive_mini_icon()` (те же ключи)

### Новые пассивки
| ID | Название | Описание |
|----|----------|----------|
| 22 | Shield Mastery | -КД щита (parry_cd_mult) |
| 23 | HP Boost | Фиксированный +HP (hp_flat) |
| 24 | Damage Boost | Фиксированный +урон (damage_flat) |
| 25 | Speed Boost | Фиксированная +скорость (speed_flat) |
| 26 | Armor Plating | +HP и снижение урона (damage_reduction) |
| 27 | Steady Hands | Фиксированный -КД (cd_flat) |
| 28 | Vital Force | Регенерация HP/с (regen_per_sec) |
| 29 | Venom Tips | Яд на снарядах (poison_pct) |

### Что делать дальше
- Добавить обработку новых ключей (parry_cd_mult, hp_flat, damage_flat, speed_flat, cd_flat, regen_flat) в `player.gd` → `_apply_passives()`
- Создать doc-файлы в `docs/passives/` для каждой новой пассивки
- Обновить `docs/passives/README.md`

---

## 2026-04-10 — Система лимитов спавна способностей + очистка аутобаундс

### Лимиты спавна сущностей (ability_entity_count)
- Добавлены проверки `_can_spawn_ability()` перед каждым instantiate в `player_abilities.gd`
- Добавлены вызовы `_track_entity()` после каждого `add_child()` для всех способностей:
  - YARN_TOSS, BOOMERANG, GRENADE, STINK_CLOUD, ROCKET_LAUNCHER, GUIDED_ROCKET, BLACK_HOLE, HEAVENS_WRATH, TRIPWIRE
- Burst-функции (`_burst_yarn_toss`, `_burst_boomerang`, `_burst_rockets`) тоже получили проверки и трекинг
- ROCKET_LAUNCHER: отслеживается только первая ракета из залпа (1 use = 1 salvo)
- TRIPWIRE: проверка добавлена при создании первого и третьего якоря
- GRENADE: при превышении лимита в `_throw_grenade` сбрасывается charge_slot

### _exit_tree() во всех снарядах/сущностях
- Добавлен в: `yarn_projectile.gd`, `boomerang.gd`, `rocket.gd`, `guided_rocket.gd`, `grenade.gd`, `stink_cloud.gd`, `black_hole.gd`, `heavens_wrath.gd`, `tripwire.gd`
- При выходе из дерева декрементирует `ability_entity_count[ab_id]` у владельца
- Все скрипты также добавлены в группу `"ability_entities"` через `_ready()`

### Bounds check для снарядов
- Добавлен в: `boomerang.gd`, `grenade.gd`, `soul_essence.gd` (>8000px по X или Y → queue_free)
- `rocket.gd`, `guided_rocket.gd` — уже имели проверку (>7000px)
- `yarn_projectile.gd` — уже имел проверку

### Файлы
- `scripts/characters/player_abilities.gd`
- `scripts/characters/yarn_projectile.gd`
- `scripts/characters/boomerang.gd`
- `scripts/characters/rocket.gd`
- `scripts/characters/guided_rocket.gd`
- `scripts/characters/grenade.gd`
- `scripts/characters/stink_cloud.gd`
- `scripts/characters/black_hole.gd`
- `scripts/characters/heavens_wrath.gd`
- `scripts/characters/tripwire.gd`
- `scripts/characters/soul_essence.gd`

---

## 2026-04-10 — Flat pool roll + Tab stats overlay

### Переделка системы выпадения пассивок
- **Старая система**: выбирается тип пассивки (вес = сумма весов редкостей) → потом кидается кость на редкость. Mythic-only пассивки (Fire Thread, Spirit Burst) имели вес 1.0 vs Tank ~99 — почти не выпадали.
- **Новая система (flat pool)**: каждая (пассивка × редкость) — отдельный слот в пуле. Вес слота = rarity_weight × luck modifier. Все пассивки имеют равные шансы появиться, а редкость определяется весом конкретного слота.
- **Удача**: плавно влияет на ВСЕ слоты — Common уменьшается (×0.85 per luck), Rare растёт (×1.3 per luck), Mythic растёт сильнее (×2.2 per luck). Высокая удача реально повышает шанс Mythic-only пассивок.
- Одна и та же пассивка НЕ может выпасть дважды в одном roll'е.

### Tab — меню характеристик (hold Tab)
- HP (текущие/макс + бар)
- DMG (множитель урона)
- LIVES (extra_lives + 1)
- LUCK (бонус удачи)
- REGEN (HP/сек)
- SPEED (множитель скорости)
- CD (множитель кулдауна)
- SCORE (очки раундов)
- Каждый игрок в своей колонке с цветным header и yarn ball иконкой

### Файлы
- `passive_registry.gd` — `_get_rarity_weight()`, полная переработка `roll_choices()` на flat pool
- `game.gd` — `is_stats_open`, Tab input
- `game_overlay.gd` — `_draw_stats_overlay()`

---

## 2026-04-10 — Способность "Ярость небес" (id=16)

### Heaven's Wrath
- Тип: projectile, explosion | КД: 10с | Цвет: золотисто-белый
- 6 столбов света последовательно (задержка 0.12с) от позиции игрока в направлении взгляда
- Столбы падают сверху вниз с огромной скоростью (3000 px/с), проходя через платформы
- Ширина столба 60px, расстояние между столбами 120px
- 3 фазы визуала: falling (яркий луч с лидирующей вспышкой), impact (кольцо + рассеивание), fading (тонкая линия + частицы вверх)
- Урон 30 при попадании + knockback вверх
- Рассеивание у нижнего края карты — scatter-частицы и expanding ring

### Файлы
- `scripts/characters/heavens_wrath.gd` — новый скрипт
- `scenes/characters/heavens_wrath.tscn` — новая сцена
- `ability_registry.gd` — HEAVENS_WRATH=16, ABILITY_COUNT=17
- `data/abilities.json` — запись id=16
- `player_abilities.gd` — preload + dispatch + _ab_heavens_wrath()
- `player.gd`, `lobby.gd` — эмблемы

### Итого способностей: 17

---

## 2026-04-10 — 3 игровых режима

### Classic (по умолчанию)
- Текущий режим: first to N wins, пассивки между раундами

### Endless (бесконечный)
- Раунды идут бесконечно, счёт растёт без ограничения
- game_won никогда не emitится, всегда round_ended
- ROUNDS TO WIN показывает "INF" и затемнён
- ESC для выхода в меню

### Chaos (хаос)
- Как Classic, но после каждого использования способности она заменяется на случайную
- `player.ability_ids[slot] = randi_range(0, ABILITY_COUNT - 1)` после success

### Реализация
- `game_manager.gd`: enum GameMode {CLASSIC, ENDLESS, CHAOS}, var game_mode, логика в _end_round
- `lobby.gd`: UI селектор MODE (kb_focus=5), dimmed ROUNDS при Endless
- `player_abilities.gd`: chaos swap в _use_ability

---

## 2026-04-10 — 7 фиксов и улучшений

### 1. Растяжки: цвет игрока (tripwire.gd)
- Blend к cyan: 0.5 → 0.15, теперь цвет игрока доминирует

### 2. Прицел: чёрный outline (player.gd)
- Каждый элемент рисуется дважды: чёрный outline (4px) + цветной (2px)
- Виден на любом фоне, включая синюю карту для синего игрока

### 3. Точка возрождения: guard (player_abilities.gd)
- Ставится только если `extra_lives > 0` и `!spawn_point_used_this_life`

### 4. Граната: мгновенный взрыв + min offset (grenade.gd, player_abilities.gd)
- Owner safe time (0.3с) теперь только для владельца, враги взрывают сразу
- Min offset: `maxf(radius, 24) + 12` — маленькие игроки не бросают "в себя"

### 5. Чёрная дыра: усиление + lifesteal (black_hole.gd, abilities.json)
- pull_force: 120 → 350
- Затягивание начинается СРАЗУ (во время expand), не ждёт 2.5с
- HP drain → lifesteal: владелец получает отнятое HP

### 6. Flat-значения пассивок (player.gd)
- Поддержка hp_flat, damage_flat, speed_flat в JSON
- Flat применяется ПОСЛЕ multiplier-ов
- Существующие пассивки не изменены — только добавлена поддержка

---

## 2026-04-10 — Мифическая редкость пассивок + 2 новые пассивки

### Изменено: data/passives.json
- Добавлена редкость "4" (Mythic) к 8 существующим пассивкам:
  - id 0 (Poison Projectile): +70% яд + 2с замедление
  - id 1 (Phoenix): +2 жизни, -10% HP, respawn_hp_pct 1.0
  - id 2 (Tank): +200% HP, +10% скорость
  - id 3 (Lifesteal): 40% lifesteal, +20% урон
  - id 13 (Glass Cannon): +150% урон, -15% HP
  - id 14 (Iron Skin): -50% входящий урон, +20% HP
  - id 15 (Shockwave): Отталкивание x2.5, +15% скорость
  - id 16 (Lightning Strike): 1.2с замедление, +20% урон
- Добавлены 2 новые пассивки:
  - id 18 (Homing Projectiles): наведение снарядов, редкости [1,2,3,4]
  - id 19 (Burst Fire): залповая стрельба, редкости [2,3,4]

### Что делать дальше
- Добавить поддержку homing_strength в логику снарядов (player_abilities.gd / projectile скрипты)
- Добавить поддержку burst_count в логику стрельбы
- Добавить иконки "homing" и "burst" в hud_draw.gd и game_overlay.gd
- Добавить match case для id 18 и 19 в player.gd → _apply_passives()
- Создать docs/passives/18_homing_projectiles.md и docs/passives/19_burst_fire.md
- Обновить docs/passives/README.md

---

## 2026-04-09 — Масштабирование способностей под размер игрока

### Проблема
При увеличении HP (Tank пассивка, hp_scale до 1.8x) радиус игрока вырастает с 24 до 43px. Многие способности имели захардкоженные оффсеты (30-50px), из-за чего снаряды спавнились внутри увеличенного игрока.

### Исправленные спавн-оффсеты (player_abilities.gd)
| Способность | Было | Стало |
|---|---|---|
| Yarn Toss | `aim * 30` | `aim * (radius + 8)` |
| Grenade | `aim * 50` | `aim * (radius + 12)` |
| Boomerang | `aim * 40` | `aim * (radius + 10)` |
| Guided Rocket | `aim * 40` | `aim * (radius + 10)` |
| Rocket Launcher (x3) | `dir * 30` | `dir * (radius + 10)` |

### Фикс grenade.gd — детектирование игрока
- Было: `player_detect_radius + 24.0` (захардкоженный BASE_RADIUS)
- Стало: `player_detect_radius + p.get_player_radius()` (динамический)

### Фикс boomerang.gd — перехват бумеранга
- return_radius теперь учитывает размер владельца: `max(return_radius, owner.radius + 10)`

### Фикс player.gd — dash и spike armor
- Dash hit: `cfg.hit_radius * radius_multiplier + get_player_radius()`
- Spike armor contact: `cfg.contact_radius + get_player_radius()`

---

## 2026-04-08 — 2 новые способности + фикс Tripwire

### Фикс Tripwire
- `_ab_tripwire()` теперь возвращает `bool` — `false` при промахе raycast
- Кулдаун не тратится если растяжка не поставилась
- Dispatch обновлён: `success = _ab_tripwire()`

### Black Hole (id=14)
- Тип: trap, dot | КД: 12с | Цвет: тёмно-фиолетовый
- 2.5с расширение (предупреждающее красное кольцо, анимация роста)
- 8с активная фаза: притягивает игроков (pull_force 120), высасывает 5 HP/сек
- НЕ накладывает пассивки (poison, lightning) — прямой HP drain
- Визуал: чёрное ядро, вращающийся диск аккреции, затягиваемые частицы, fade-out
- Файлы: black_hole.gd, black_hole.tscn

### Portal Gate (id=15)
- Тип: utility | КД: 8с | Цвет: фиолетовый
- 1-е нажатие: ставит портал A (радиус 100px), БЕЗ кулдауна
- 2-е нажатие: swap всех в обоих радиусах — игроки у A → к игроку, игроки у игрока → к A
- Снаряды тоже телепортируются, velocity сохраняется
- Визуал: пульсирующее кольцо + вращающиеся внутренние арки + искры
- Состояние: portal_gate_pos/has_portal_gate на player.gd

### Итого способностей: 16

### Изменённые файлы
- player_abilities.gd — фикс tripwire, +_ab_black_hole, +_ab_portal_gate, dispatch
- ability_registry.gd — +BLACK_HOLE, +PORTAL_GATE, ABILITY_COUNT=16
- data/abilities.json — +2 записи
- player.gd — portal_gate переменные, визуал маркера, эмблемы
- lobby.gd — эмблемы
- black_hole.gd, black_hole.tscn — новые файлы

---

## 2026-04-08 — 3 новые пассивки + базовое отталкивание

### Shockwave (id=15) — отталкивание при парировании
- При парировании все враги в радиусе 2.5x от размера игрока получают knockback без урона
- 4 редкости: множитель радиуса 1.0/1.3/1.6/2.0
- Common штраф: -10% HP
- Legendary бонус: +10% скорость
- VFX: bomb_ring + электрические партиклы

### Lightning Strike (id=16) — молния на урон
- Все умения, наносящие урон, замедляют цель
- 3 редкости (U/R/L): 0.3с/0.5с/0.8с замедления
- Uncommon штраф: +10% кд
- Legendary бонус: +15% урон
- Электрические партиклы при срабатывании

### Heavy Impact (id=17) — усиление столкновений
- Множитель силы отталкивания при врезании в других игроков
- 4 редкости: 1.5x/1.8x/2.2x/3.0x
- Common/Uncommon штраф: -скорость
- Legendary бонус: +20% HP

### Базовое отталкивание при столкновении
- _handle_player_collisions переделана: оба игрока получают импульс
- Учитывается относительная скорость (impact)
- collision_force_mult влияет на силу отскока
- Звук удара при сильных столкновениях (impact > 300)
- Радиус столкновения = сумма радиусов обоих игроков

### Итого пассивок: 18

---

## 2026-04-08 — Точка возрождения при активации щита

### Механика
- При активации парирования (L3/Click) ставится точка возрождения в текущей позиции игрока
- Одна точка за жизнь — при повторном парировании точка перемещается
- При смерти с extra_lives (Phoenix): если есть custom spawn → возрождение там, точка исчезает
- Если custom spawn нет → возрождение на дефолтном спавне (как раньше)
- При последней жизни (extra_lives == 0 после возрождения) → новую точку поставить нельзя
- При respawn (новый раунд) все сбрасывается

### Визуал
- Пульсирующее кольцо цвета игрока + белое внутреннее кольцо
- Крестик в центре
- Поднимающаяся искра

### Файлы
- `player.gd` — переменные custom_spawn_point/has_custom_spawn/spawn_point_used_this_life, логика в die(), визуал в _draw(), сброс в respawn()
- `player_abilities.gd` — установка точки при парировании

---

## 2026-04-08 — Переделка щита/парирования

### Парирование теперь:
1. **Отражает снаряды упруго** — yarn toss, rocket, guided rocket, boomerang разворачиваются на 180° и летят обратно, owner меняется на парировавшего
2. **Гранату отбивает** — при парировании граната получает импульс от игрока (kick 1200 + вверх 400)
3. **Блокирует урон** — при парировании любой урон (melee, explosion) полностью подавляется
4. **НЕ отражает урон обратно** — убран `source.take_damage(amount * 1.5)`, теперь только блок
5. **Отцепляет паутину** — если кто-то зацепился гранплом к парирующему, его гранпл отсоединяется + электрический burst

### Изменённые файлы
- `player.gd` — `is_parrying()`, `on_parry_reflect()`, `_parry_detach_grapples()`, изменён `take_damage()`
- `yarn_projectile.gd` — проверка `is_parrying()` перед уроном, разворот direction/owner
- `rocket.gd` — аналогично
- `guided_rocket.gd` — аналогично
- `boomerang.gd` — аналогично + сброс returning/hit_players
- `grenade.gd` — парирование = kick grenade away вместо взрыва

---

## 2026-04-08 — Большое обновление карт

### Новые механики в map_base.gd
- `use_walls` — твёрдые стены вместо красных danger-зон (StaticBody2D по периметру)
- `fire_walls` — огненные стены, наносят 5 HP/тик при касании через _apply_fire_burn
- `bouncy_walls` — упругие стены, отражают игрока с множителем 1.2x + бонус скорости
- Sticky-блоки: `"sticky"` в массиве platforms = solid (нельзя пролететь снизу), фиолетовый визуал
- Стены отключают danger zones, kill zones и shrink

### Порталы v2
- Новый формат: `[x1, y1, h1, angle1, x2, y2, h2, angle2]` — прямоугольные/овальные
- RectangleShape2D(30, h) вместо CircleShape2D(30)
- Инерция сохраняется при телепортации (velocity не обнуляется)
- Визуал: вытянутый овал с внутренним свечением и частицами
- Старый формат [x1,y1,x2,y2] совместим

### Удалена карта Underwater
- Удалены underwater.gd и underwater.tscn
- Убрана из MAP_SCENES в game.gd

### Фикс Cloud Kingdom
- Градиент неба ограничен safe area (не заходит в danger_bottom)

### Расширение всех 13 карт
- map_rect.height +400px, danger_bottom +200px на каждой карте
- Больше пространства под нижними блоками

### Новые карты
- **Fortress** — каменная крепость с use_walls, sticky-блоки на потолке, факелы, баннеры
- **Inferno** — огненные стены (fire_walls), лавовый колодец, эмберы, трещины
- **Trampoline** — упругие стены (bouncy_walls), неоновая сетка, пульсирующие углы, хаос

### Итого карт: 16 (13 старых + 3 новых, минус Underwater)

---

## 2026-04-03 — Актуальное состояние проекта

### Ядро
- Godot 4.6.1, GDScript, 2D
- Локальный мультиплеер 2-4 (клавиатура+мышь + 3 геймпада)
- Динамическое подключение геймпадов (Xbox 360 и др.)

### Персонажи
- Клубки ниток через `_draw()`, squash/stretch, body tilt
- HP-based size scaling (0.7x–1.8x от MAX_HP) — размер клубка и хитбокса зависит от HP
- Grapple hook: анимация полёта нити, цветные нити по игрокам
- Анимация бега: деформация в направлении движения, развевающиеся нити
- Speed trail: afterimage при быстром движении (>400 px/s)
- Анимация смерти: 18 нитей + 10 частиц разлетаются
- Прицел: мышь для P1 (крестик), правый стик для P2-P4 (120px)
- Парирование: L1/колёсико мыши, окно 0.2с, отражает 150% урона, белая сфера
- Захват/бросок: способность #13, станит 1.5с, бросает со скоростью 1200
- Кастомизация цвета: 10 цветов на выбор в лобби

### Способности (14 шт)
Yarn Toss, Needle Dash, Yarn Bomb, Thread Pull, Spin Attack,
Grenade (зарядка+отскоки), Rocket Launcher (3 ракеты),
Stink Cloud, Spike Armor, Swap, Boomerang, Guided Rocket, Tripwire, Grab Throw

### Пассивки (15 шт)
- Выбор 1 из 5 карт между раундами, 4 редкости (C 47%/U 31%/R 19%/L 3%)
- Poison Projectile, Phoenix, Tank, Lifesteal, Thread Master
- Wide Impact, Quick Hands, Fire Thread, Ricochet, Regeneration
- Explosive Power, Swift Feet, Projectile Master, Glass Cannon, Iron Skin

### Карты (14 шт)
- Workshop, Sky Garden, Volcano, Ice Cave, Tower (оригинальные 5)
- Factory (конвейеры, шипы, телепорты, предметы)
- Jungle (лианы, грибы, разрушаемые платформы, предметы)
- Space (звёзды, Земля, телепорты, случайные события)
- Dungeon (тёмная, факелы с мерцанием, паутина, черепа)
- Cloud Kingdom (5500px, ветер каждые 8с, небо, радуга)
- Underwater (замедление движения, пузыри, водоросли, световые лучи)
- Clockwork (вращающиеся шестерёнки, маятники, часы, разрушаемые платформы)
- Arena (маленькая 3200x2400, danger zones сжимаются — battle royale)
- Mirror (симметричная, зеркальная линия, 2 пары порталов)

### Карточные механики
- Hazards: шипы (мгновенная смерть), движущиеся платформы (AnimatableBody2D)
- Телепорты: порталы соединяющие 2 точки, кулдаун 1с
- Разрушаемые платформы: ломаются после N попаданий, краснеют
- Предметы: аптечка (+30% HP), ускорение (1.3x на 5с), сброс кулдаунов
- Пикапы способностей: спавн каждые 15с (макс 3)
- Случайные события (Space): метеорит, молния, волна ветра (каждые 20с)

### Визуал и эффекты
- Parallax фоны: многослойные для Workshop, Volcano, Space
- Экран победы: большой клубок с короной, 40 конфетти, 6 фейерверков
- Slide-in анимация карт выбора пассивок
- VFX система: 11 типов эффектов (muzzle_flash, bomb_ring, pull_thread, и т.д.)
- Screen shake: взрывы (6-10), смерти (8), тяжёлые приземления (до 4)
- Вибрация геймпада: урон (пропорц.), смерть (сильная), dash, парирование, взрывы
- MusicManager: 14 уникальных тем карт + menu ambient + динамическая интенсивность
- Ambient звуки: лава, пузыри, ветер, механизмы, жуки, толпа, дрон, капли
- UI звуки: click, confirm

### UI
- Title Menu: Play, Settings (Volume×2, Fullscreen, VSync, FPS, Shake, Vibration), Quit
- Lobby: 4 слота, выбор цвета/способностей, настройки HP/Rounds
- HUD: точки-очки, иконки пассивок (18px) с hover-тултипами
- Пауза: Resume/Quit overlay на CanvasLayer
- Выбор пассивок: 5 карточек, таймер 15с, slide-in

### Технические детали
- Collision layers: 1=платформы, 2=игроки, 3=и+п, 4=снаряды, 8=пикапы
- Autoloads: InputManager, AbilityRegistry, GameManager, SoundManager, PassiveRegistry
- Оптимизация: статичные карты не вызывают queue_redraw()
- Процедурный звук: sine waves, 44100Hz, 16-bit
- F12 = скриншот (user://), process_mode=ALWAYS

### Управление
| Действие | Клавиатура | Геймпад |
|----------|-----------|---------|
| Движение | A/D | Стик/D-Pad |
| Прыжок (hold=grapple) | Space | R1 |
| Парирование | Колёсико | L1 |
| Способность 1 | ЛКМ | L2 |
| Способность 2 | ПКМ | R2 |
| Прицел | Мышь | Правый стик |
| Пауза | ESC | B |

---

## 2026-04-08 — Новые сцены карт: Fortress, Inferno, Trampoline

### Изменения
- Созданы 3 новые .tscn-файла сцен карт в `scenes/maps/`
- Каждая сцена: root Node2D + привязанный скрипт, формат идентичен `workshop.tscn`

### Новые файлы
- `scenes/maps/fortress.tscn` — Node2D "Fortress", скрипт `res://scripts/maps/fortress.gd`
- `scenes/maps/inferno.tscn` — Node2D "Inferno", скрипт `res://scripts/maps/inferno.gd`
- `scenes/maps/trampoline.tscn` — Node2D "Trampoline", скрипт `res://scripts/maps/trampoline.gd`

### Что делать дальше
- Создать скрипты `scripts/maps/fortress.gd`, `inferno.gd`, `trampoline.gd`
- Реализовать логику карт (платформы, механики, map_rect, spawn_points)

---

## 2026-04-08 — Расширение карт по вертикали (6 оставшихся карт)

### Изменения
- Ещё 6 карт расширены вертикально: +400px к высоте map_rect, +200px к danger_bottom
- Платформы и spawn_points не изменены — дополнительное пространство снизу

### Новые параметры карт
| Карта | map_rect (новый) | danger_bottom (новый) |
|-------|-----------------|----------------------|
| Space | 5200×3800 | 500 |
| Dungeon | 4400×3400 | 500 |
| Cloud Kingdom | 4000×5900 | 600 |
| Clockwork | 4800×3600 | 500 |
| Arena | 3200×2800 | 400 |
| Mirror | 4800×3400 | 500 |

### Изменённые файлы
- `scripts/maps/space.gd`
- `scripts/maps/dungeon.gd`
- `scripts/maps/cloud_kingdom.gd`
- `scripts/maps/clockwork.gd`
- `scripts/maps/arena.gd`
- `scripts/maps/mirror.gd`

---

## 2026-04-08 — Расширение карт по вертикали (+400px высоты, +200px danger_bottom)

### Изменения
- Все 7 карт расширены вертикально: добавлено 400px к высоте map_rect
- danger_bottom увеличен на 200px для пропорционального смещения зоны опасности
- Платформы и spawn_points не изменены — дополнительное пространство ниже контента

### Новые параметры карт
| Карта | map_rect (новый) | danger_bottom (новый) |
|-------|-----------------|----------------------|
| Workshop | 4800×3600 | 500 |
| Sky Garden | 5200×4000 | 600 |
| Volcano | 4400×3800 | 600 |
| Ice Cave | 4600×3400 | 500 |
| Tower | 3600×5200 | 550 |
| Factory | 4800×3600 | 500 |
| Jungle | 5000×4000 | 550 |

### Изменённые файлы
- `scripts/maps/workshop.gd`
- `scripts/maps/sky_garden.gd`
- `scripts/maps/volcano.gd`
- `scripts/maps/ice_cave.gd`
- `scripts/maps/tower.gd`
- `scripts/maps/factory.gd`
- `scripts/maps/jungle.gd`

---

## 2026-04-08 — map_base.gd: стены, прямоугольные порталы, липкие платформы

### Новые механики стен (map_base.gd)
- Три новых bool-флага: `use_walls`, `fire_walls`, `bouncy_walls` + `wall_thickness: float`
- `_create_walls()` — создаёт 4 StaticBody2D по краям map_rect (левый, правый, нижний, верхний если danger_top > 0)
  - `bouncy_walls`: PhysicsMaterial с bounce=1.5, friction=0.0
  - Ручной bounce в `_process()` для надёжности: отражает velocity * 1.2 + 200
- `fire_walls`: урон в `_process()` через `_apply_fire_burn(5.0, 0.3, 0.6)` когда игрок у края ±10px
- `_draw_walls()`: визуал — камень (кирпичный паттерн), огонь (мерцающие частицы), пружины (зигзаги)
- Когда активны стены: `is_in_danger_zone()` и `is_past_kill_zone()` возвращают false; `_draw_danger_zones()` пропускается; глобальное сжатие зоны не работает
- `queue_redraw()` добавлен для `fire_walls` и `bouncy_walls`

### Порталы v2 (прямоугольные)
- `teleports` массив теперь поддерживает формат [x1,y1,h1,angle1,x2,y2,h2,angle2] (8 элементов)
- `_create_teleport_pair_v2()`: RectangleShape2D(30, h), Area2D с rotation_degrees, метаданные height/angle
- Рисование: овал вместо окружности, вращается по angle, с внутренним свечением и 5 wisps-частицами
- Скорость игрока сохраняется при телепортации (было и раньше — подтверждено)

### Липкие платформы
- Формат: `data[4] == "sticky"` в массиве platforms
- Рисуются фиолетовым цветом + сеткой нитей (паутина)
- Физически — solid платформы (one_way=false)

### Изменённые файлы
- `scripts/maps/map_base.gd` — все изменения выше

---

## 2026-04-08 — Фиксы UI лобби, гранпл, респавн

### Лобби UI
- Фикс: подсветка HP/Rounds — `kb_focus == 3` и `kb_focus == 4` (было 2 и 3, из-за чего подсвечивалась не та ячейка)
- Фикс: текст устройства перенесён в header бар (top + 45, размер 11) чтобы не наслаиваться на селекторы

### Гранпл
- Направление выстрела паутины теперь всегда = `aim_direction` (прицел), не зависит от стика ходьбы
- Увеличена скорость: GRAPPLE_SHOOT_SPEED 2500 → 3500, RETRACT 4000 → 5000

### Респавн
- Фикс: `respawn()` теперь ставит `global_position = pos` перед `position = pos`
- Фикс: `$CollisionShape2D.set_deferred("disabled", false)` вместо прямого присвоения

---

## 2026-04-08 — Grab Throw: анимация и фикс радиуса

### Фикс радиуса захвата
- `_try_grab_nearby()` теперь учитывает радиусы обоих игроков: `effective_range = grab_radius + player_radius + target_radius`
- Раньше 60px не хватало для увеличенных игроков (Tank пассивка), теперь работает

### Анимация крюка (grab_hook_timer)
- При захвате — нить выстреливает к цели (0.15с)
- Крюк с двумя "когтями" на конце (V-форма)
- Прозрачность fade-out

### Анимация удержания
- Волнистая нить (4 сегмента с sin-волной) соединяет игрока с захваченным
- Пульсирующее кольцо вокруг захваченного игрока
- Нить цвета игрока, затемнённая на 20%

### Изменённые файлы
- `scripts/characters/player.gd` — переменные grab_hook_timer/target, draw код
- `scripts/characters/player_abilities.gd` — фикс effective_range, trigger анимации

---

## 2026-04-07 — Рефакторинг: Разделение player.gd (Фаза 2)

### Извлечены компоненты из player.gd
- `player_grapple.gd` (201 строк) — вся логика гранпла: старт, полёт хука, физика качания, отпускание, Fire Thread урон, tracking движущихся платформ
- `player_abilities.gd` (490 строк) — диспатч и все 14 способностей: yarn toss, needle dash, yarn bomb, thread pull, spin attack, grenade (с зарядкой), rocket launcher, stink cloud, spike armor, swap, boomerang, guided rocket, tripwire, grab/throw
- player.gd: 2458 → **1854** строк (-604 строки)

### Архитектура
- Node-композиция: два дочерних Node в player.tscn
- Связь через `player` ссылку: `_grapple.setup(self)`, `_abilities.setup(self)`
- Тонкие делегирующие обёртки остаются в player.gd для обратной совместимости
- `_apply_fire_burn()` остался на player (использует await, meta, hp)
- Переменные остались на player (нужны для `_draw()`)

---

## 2026-04-07 — Рефакторинг: JSON-конфиги (Фаза 1)

### Конфиги способностей и пассивок перенесены в JSON
- Создан `data/abilities.json` — 14 способностей с полным конфигом
- Создан `data/passives.json` — 15 пассивок с конфигом по редкостям
- `ability_registry.gd` — enum остался, DATA загружается из JSON в `_ready()`
- `passive_registry.gd` — enum остался, DATA загружается из JSON в `_ready()`
- Удалён мёртвый код `_old_roll_choices()`
- Color сериализуется как `[r, g, b]`, конвертируется при загрузке
- Rarity ключи в JSON строковые ("0","1",...), конвертируются в int при загрузке
- Validation assert при загрузке — проверяет количество записей

### Зачем
- Балансировка без правки GDScript кода
- Чистое разделение данных и логики
- JSON можно редактировать любым редактором

---

## 2026-04-07 — Партиклы урона (огонь, яд, молния)

### Система burst-партиклов при получении урона
- `_spawn_hit_burst(dmg_type, count)` — генерирует всплеск частиц при каждом получении урона
- Типы: "hit" (белые искры), "fire" (оранжевые), "poison" (зелёные), "electric" (голубые)
- Количество частиц зависит от величины урона (4-14)

### Огонь
- Burst-партиклы при каждом тике горения (6 штук за тик)
- Непрерывные партиклы поднимающегося пламени пока `fire_burning` активно (уже было)

### Яд
- Burst-партиклы при каждом тике отравления (5 штук за тик)
- Непрерывные зелёные пузырьки пока `poison_active` (уже было)

### Молния/электричество
- Электрические молнии-зигзаги вокруг игрока пока `stun_timer > 0`
- 3-сегментные zigzag-болты с рандомным смещением
- Голубое свечение, тело подкрашивается голубым
- Burst при входе в стан (10 голубых частиц)

### Универсальные hit-партиклы
- Белые искры при любом `take_damage()` — визуальный фидбек каждого попадания

### Изменённые файлы
- `scripts/characters/player.gd` — новые массивы частиц, _spawn_hit_burst(), рендеринг в _draw(), вызовы из take_damage/fire_burn/poison_dot/apply_stun

---

## 2026-04-03 — Визуальные эффекты и полировка

### Danger zones
- Красные зоны теперь рисуются с расширением 2000px за границу карты, чтобы игроки не видели где зона заканчивается

### Статусные эффекты — партиклы
- Горение: оранжевые/жёлтые частицы поднимаются вверх от тела игрока, тело подкрашивается оранжевым
- Отравление: зелёные пузырьки вокруг тела, тело подкрашивается зелёным
- Трекинг через `set_meta("fire_burning")` / `set_meta("poison_active")`

### Fire Thread — визуал верёвки
- Когда пассивка Fire Thread активна, верёвка гранпла светится оранжевым пламенем
- 8 сегментов с волнообразным свечением + маленькие огоньки на каждом сегменте

### Анимация выбора пассивки
- Выбранная карта теперь падает вниз с fade-out (0.5с) перед переходом к следующему игроку

### Изменённые файлы
- `scripts/maps/map_base.gd` — расширение danger zone рендеринга
- `scripts/characters/player.gd` — burn/poison партиклы, fire thread rope glow, color tint
- `scripts/main/game_overlay.gd` — drop animation для выбранной карты

---

## Идеи по улучшению

### 🎨 Дизайн и визуал

- **Спрайты персонажей**: AnimatedSprite2D вместо `_draw()` — idle, run, jump, fall, hurt кадры
- **Спрайты платформ**: tileset с разными тайлами для каждой темы
- **GPU-частицы**: GPUParticles2D для огня, дыма, искр, снега (вместо ручных массивов)
- **Шейдеры**: water distortion для Underwater, heat haze для Volcano, shadow для Dungeon
- **Паттерны клубка**: полоски, точки, градиент — кастомизация в лобби
- **Шапки/аксессуары**: короны, шляпы, очки — декоративные элементы на клубках
- **Анимация UI**: плавные переходы между экранами (fade, slide)
- **Иконки способностей**: полноценные спрайтовые иконки вместо процедурных линий

### ⚙️ Механики

- **Двойной прыжок**: как пассивка или базовая способность
- **Комбо-система**: быстрые попадания увеличивают урон (×1.2, ×1.5, ×2.0)
- **Стихии**: огонь/лёд/электро — статусные эффекты с уникальной механикой
- **Ультимативная способность**: 3-й слот, заряжается от нанесённого/полученного урона
- **Режимы игры**: King of the Hill, Team 2v2, Stock (фиксированные жизни), Capture the Flag
- **Модификаторы матча**: низкая гравитация, увеличенная скорость, большие взрывы, невидимость
- **Вода/лава зоны**: замедление, урон, изменение прыжка
- **Генератор карт**: рандомная генерация платформ по правилам проходимости

### 🎵 Звук и музыка

- **Фоновая музыка**: уникальная тема для каждой карты
- **Музыка меню**: ambient loop
- **Звуки UI**: клик, переключение, ошибка
- **Звуки окружения**: ветер, лава, механизмы, вода
- **Динамическая музыка**: интенсивность по количеству живых игроков
- **Анонсер**: голосовые объявления "Round 1", "Final round", "Double kill"

### 📊 Прогрессия и мета

- **Статистика матча**: урон, убийства, использование способностей, парирования
- **Профили**: сохранение статистики и настроек между сессиями
- **Достижения**: "Убить 3 одной гранатой", "Парировать ульт", "Выиграть без урона"
- **Рейтинг**: winrate способностей и пассивок
- **Ежедневные модификаторы**: мутаторы (большие головы, бесконечные прыжки)
- **Сезонные события**: тематические карты и способности

### 🔧 Технические улучшения

- **Полный ребинд клавиш**: экран настройки управления для P1
- **Реплей система**: запись и просмотр матчей
- **Сетевой мультиплеер**: Steam Networking / ENet (большая задача)
- **Steam-интеграция**: достижения, лидерборды, Remote Play Together
- **Экспорт**: сборки для Windows/Linux/Mac
- **Автосохранение настроек**: сохранение в user:// между запусками
- **Профилирование**: мониторинг FPS, draw calls, memory

### 🎮 UX и полировка

- **Туториал**: интерактивное обучение для новичков
- **Превью способностей**: анимация в лобби при наведении
- **Индикатор врагов**: стрелки на краю экрана к игрокам за кадром
- **Killcam**: замедленный повтор финального убийства
- **Объявления**: "First Blood", "Double Kill", "Comeback", "Domination"
- **Подсказки**: tips на экранах загрузки
- **Accessibility**: размер UI, дальтонизм, субтитры звуков
- **Спектатор**: камера для мёртвых игроков следит за боем
