# Промты для генерации персонажа TangleBattle через nanobanana 2

Файл содержит готовые промты для Google nanobanana 2 (Gemini 2.5 Flash Image)
для генерации персонажа-клубка и его поз/эмоций.

**Философия**: генерируем **ОДНОГО** персонажа в нейтрально-белом цвете, затем
в Godot через `Sprite2D.modulate = player_color` получаем 4 цветных варианта
(красный/синий/зелёный/жёлтый) без перегенерации.

**Ключевой принцип**: персонаж — **чистый клубок ниток БЕЗ рук, ног и каких-либо
конечностей**. Никаких стоби-ручек, никаких ножек, никаких митенок. Это
буквально шарик из ниток. Все действия передаются через:
- Деформацию самого шарика (squash / stretch)
- Движение хохолка ниток сверху
- Motion-lines и частицы вокруг
- Наклон/поворот всего клубка
- Расползающиеся/торчащие нитки при уроне

---

## 1. Цветовая схема для чистого тинта

| Элемент | Цвет | Почему |
|---------|------|--------|
| **Тело (нитки)** | Чистый белый `#FFFFFF` | `WHITE × player_color = player_color` — точный тинт |
| **Тени** | Светло-серый `#D0D0D0` | `GRAY × RED = тёмно-красный` — естественная тень игрока |
| **Контур** | Чистый чёрный `#000000` | `BLACK × anything = BLACK` — контур сохраняется при любом тинте |
| **Фон** | **Полностью прозрачный** | Требование для спрайта в Godot |

Лицо — **отдельный спрайт** (не тинтуется), чтобы глаза/рот остались
чёрными на теле любого цвета.

---

## 2. Технические требования

| Параметр | Значение |
|----------|----------|
| Размер генерации | 1024×1024 px (выше качество, даунскейл до 256 в игре) |
| Формат | PNG с альфа-каналом |
| Центр | Геометрический центр клубка = центр изображения |
| Поле вокруг | 10% padding по краям (чтобы не резать при кропе) |
| Антиалиасинг контура | Минимальный (резкие края для игрового стиля) |

---

## 3. Общий шаблон (повторять в каждом промте для консистентности)

Эта часть **добавляется в начало** каждого промта ниже:

```
STYLE: Flat cartoon mascot illustration, clean vector-art aesthetic
in the style of Kirby or a Rovio/Angry Birds mascot. Bold 3-pixel-thick
pure BLACK (#000000) outline around the entire silhouette. Body
filled with pure WHITE (#FFFFFF). Visible spiral yarn-thread pattern
wrapping around the ball as fine thin gray (#C0C0C0) curves showing
the knitted/woven structure. Subtle cell-shading using ONE light
gray tone (#D0D0D0) for shadows on the bottom-right side of the ball.
NO gradients. NO colored fills. NO realistic rendering.

CRITICAL CHARACTER RULE: The character is a PURE YARN BALL ONLY.
It has NO arms, NO legs, NO hands, NO feet, NO limbs of any kind.
It is a complete round ball. Do not add any mittens, paws, stubs,
protrusions-as-limbs, or anything resembling arms or legs. The only
protrusion allowed is a short loose yarn TUFT at the top of the ball
(3-4 strands sticking up like a pompom) and occasional loose yarn
STRANDS that may trail off when the character moves or is hurt.

BACKGROUND: Fully transparent. Only the character is visible. No
ground, no ground shadow, no border, no color fill behind character.

COMPOSITION: Character centered in frame, 10% padding around all
edges. Character takes up about 80% of image height. PNG 1024x1024.
```

---

## 4. Главный промт — `body_idle.png` (ГЕНЕРИРУЕТСЯ ПЕРВЫМ)

Этот спрайт — **референс** для всех остальных. Сначала генерим его, потом
используем как image reference для поз и эмоций.

```
Generate a cute cartoon yarn-ball game character, idle pose, no limbs.

[вставить STYLE + CRITICAL CHARACTER RULE + BACKGROUND + COMPOSITION блок сверху]

SUBJECT: A round soft plush ball character made entirely of visible
woven yarn threads. Pure white (#FFFFFF) body. Thin gray (#C0C0C0)
curves on the body surface show the spiral knitted pattern wrapping
around the sphere. The ball is slightly taller than wide (1:1.05
ratio) from gentle breathing. A short loose yarn TUFT (4 separate
strands, 2px black outlined, white-filled) sticks up from the top of
the ball like a pompom — this is the ONLY thing protruding from the
ball, no arms, no legs, no other protrusions.

FACE: Large expressive round black eyes (#000000) with tiny WHITE
highlight dots inside each pupil for sparkle. Eyes positioned in the
upper-center of the ball. Simple closed upturned smile in solid
black between them — friendly, confident mascot. NO eyebrows, NO nose,
NO mouth interior details.

LIGHTING: Flat top-light. Soft light gray (#D0D0D0) shadow crescent
along the bottom-right curve of the ball (bottom 30%). That is the
only shading.

REMINDER: The entire character silhouette is ONE BALL + tuft on top.
Nothing else. Check: no arms sticking out sides, no legs at bottom,
no hands, no feet. If you are about to add any of those — don't.
```

---

## 5. Промты для остальных поз (с image reference)

**Важно**: для каждого промта ниже — **прикрепи `body_idle.png` как reference
image** в nanobanana и добавь этот префикс:

> `REFERENCE IMAGE: Keep the EXACT same character — same ball shape, same yarn-thread pattern, same eye size and style, same tuft style, same outline thickness, same size. Same yarn BALL with NO limbs. Only change the pose as described below.`

### `body_run.png` — "бег" (катится / скачет)
```
Pose change: Running/rolling pose. The ball has NO legs, so motion is
shown by: (1) body horizontally squashed (1.2:1 aspect, wider than
tall), (2) body tilted 25° forward to the right in direction of
motion, (3) five short dark motion-blur streaks trailing from the
left (back) side of the ball (2px black, curved), (4) small puff of
white cartoon dust (2-3 tiny soft clouds with black outlines) behind
the ball on the ground line (but still transparent background),
(5) yarn tuft on top streams backwards to the left from speed.
Eyes show focused excited expression with the same smile — mouth
slightly open in a small determined "haa".

REMINDER: No legs, no arms. Just a rolling/bouncing ball with
deformation and motion lines.
```

### `body_jump.png` — прыжок вверх
```
Pose change: Jumping upward pose. The ball has NO legs to push off
with, so jump is shown by: (1) body vertically stretched (1:1.2
aspect, taller than wide), (2) yarn tuft on top stretched upward
(strands pointing straight up from upward acceleration), (3) three
small upward-curving motion arcs below the ball (2px black lines,
short) suggesting it was launched, (4) eyes wide open excited,
(5) mouth in an open happy "whee!" curve.

REMINDER: Do not add any limbs. Pure stretched ball with tuft up
and motion arcs below.
```

### `body_fall.png` — падение
```
Pose change: Falling pose. The ball has NO limbs, so falling is
shown by: (1) body slightly vertically stretched (1:1.1 aspect) with
downward momentum, (2) yarn tuft on top trailing UPward and
backward (air resistance pulling it up), (3) two small wind-lines on
either side of the ball (short 2px dark streaks pointing upward from
the falling motion), (4) eyes widened with smaller pupils showing
concentration, (5) mouth in a small worried "o".

REMINDER: Pure ball with deformation and wind streaks, no limbs.
```

### `body_hurt.png` — получил урон
```
Pose change: Hit-reaction pose. The ball has NO limbs. Damage is
shown by: (1) body horizontally squashed and deformed (1.3:1 aspect,
as if punched from the side), asymmetric — slightly flattened on the
right side where the "hit" landed, (2) six to eight LOOSE YARN
STRANDS popping out from random spots on the ball surface (2px
black outline, white-filled curved lines) — the ball is getting
frayed, (3) yarn tuft on top is displaced sideways (bent right),
(4) four small impact stars (4-point sparkle shapes, black outline
only) around the body edges on the right side, (5) eyes scrunched
closed into tight >_< curve shapes (2px black lines), (6) mouth in
a small downturned grimace.

REMINDER: No limbs. Damage is shown through ball deformation and
frayed yarn strands popping out of the surface.
```

### `body_dead.png` — размотан (смерть)
```
Pose change: Defeated/unraveled pose. The ball has NO limbs. Death
is shown by UNRAVELING: (1) the main ball has shrunk to 50% of its
original size and is tilted 35° to the side, (2) roughly 12 long
loose yarn strands (2px black outline, white-filled curves) trail
out to the bottom-right of the image forming chaotic loops and
tangled curves — the ball is coming apart, (3) 2-3 small yarn loops
are visible detached from the main ball floating near it, (4) yarn
tuft on top is gone or barely visible, (5) X-shaped eyes made of two
crossed 3px black lines each (classic dead expression), (6) mouth
is a flat straight horizontal short line.

REMINDER: No limbs — death is pure unraveling yarn. Main ball
smaller, many loose strands trailing away.
```

---

## 6. Промты для лиц (отдельные спрайты 512×512)

Лицо рендерится как **отдельный Sprite2D** поверх тела, без тинта.
Лицо содержит ТОЛЬКО глаза и рот — без головы, без контура, без тела.

**Стилевой блок для всех лиц:**
```
STYLE: Minimalist cartoon face elements ONLY — just eyes and mouth,
nothing else. Pure black (#000000) for all features, with tiny white
dots inside eye pupils for sparkle highlights (except where noted).
No head shape, no body, no outline around face area, no ball, no
silhouette. Transparent background. PNG 512x512.

LAYOUT: Features positioned as if they would overlay a round face.
Eyes in the upper center area (~35% from top edge of image), spaced
about 40% of image width apart (so ~25% image width from center to
each eye center). Mouth centered horizontally, ~18% below the eye
centerline.

REMINDER: Only draw the eyes and mouth, nothing else. No hair, no
head, no outline, no extras.
```

### `face_happy.png` (генерить первым, использовать как reference для остальных)
```
Subject: Two large round solid-black eyes, each with a tiny WHITE
highlight dot (small circle in upper-left of each pupil) for
sparkle. Eyes are perfect circles. Small upturned crescent smile
(curved arc, 3px stroke) centered between and below the eyes.
Classic cute mascot face expression.
```

### `face_focus.png` — прицеливание
```
Same style as face_happy reference. Change: eyes are narrowed into
sharp determined horizontal squints (thick lens/leaf shape, 60%
width of original eye, 40% height — like determined focused eyes).
Each squint has a tiny white highlight. Mouth is a straight
horizontal line (3px) showing serious concentration. No smile.
```

### `face_pain.png` — боль
```
Same style as face_happy reference. Change: eyes are closed tight
into scrunched >_< shapes (two small inverted V curves, 3px thick)
— no highlights since eyes are closed. Mouth is a small downturned
frowny U-shape (inverted arc) with a small triangular "ow" gap
inside showing upper lip.
```

### `face_angry.png` — ярость (после килла)
```
Same style as face_happy reference. Change: eyes are angry narrowed
slits with sharp angled ANGRY EYEBROWS above each (V-shape wedges,
3px thick, tilted inward toward the nose). Pupils visible but
smaller and more intense, NO highlight dots. Mouth is a snarl
showing 2-3 small sharp pointed teeth (triangular shapes, pointing
downward from upper lip) in an upward-curving growl. Menacing.
```

### `face_scared.png` — страх (HP < 30%)
```
Same style as face_happy reference. Change: eyes are WIDE open in
shock — larger circles than idle, with TINY pupils (small dots in
the center, showing fear-shrink). Three small motion-wobble curves
around the outside of each eye (short 2px arcs, 3 per eye,
suggesting shaking). Mouth is a tiny worried "o" (small vertical
oval). Add one small teardrop sweat shape next to the left eye
(outside the eye, below it).
```

### `face_dead.png` — мёртвый (X-eyes)
```
Same style as face_happy reference. Change: eyes are simple X-shapes
made from two crossed diagonal lines each (3px thick strokes,
crossing at the center, 40% of normal eye size). No white dots.
Mouth is a slightly open small vertical oval (just a short 3px
outlined oval) showing unconsciousness.
```

---

## 7. После генерации — обязательные шаги

### 7.1 Проверить прозрачность фона
Если nanobanana оставила светлый фон (встречается) — прогнать через GIMP:
```
Layer → Transparency → Color to Alpha → выбрать фон → OK
```
Но **осторожно с телом**: там нужен WHITE как цвет тела, нельзя просто
удалить весь белый. Лучше:
- Использовать magic wand с threshold 5-10 по углу канваса
- Или Quick Mask вокруг силуэта → inverse → delete

Для **лиц** проще: все пиксели кроме чёрных — прозрачные. Можно даже
`Colors → Threshold` сразу на 128, потом `Color to Alpha` белый.

### 7.2 Кроп + единый канвас для всех 6 поз тела
Все 6 PNG должны иметь **одинаковый центр клубка**. Минимум:
- Открыть все 6 в Photopea
- Наложить все 6 слоями, выровнять по центру клубка (не по центру bounding
  box, а именно по геометрическому центру шара)
- Сохранить каждый на канвасе 1024×1024 с единым центром
- Иначе клубок будет "прыгать" при смене позы в игре

### 7.3 Даунскейл до рабочего размера
1024 — для генерации (максимум деталей).
Для игры достаточно **256×256** (Godot сам масштабирует под радиус игрока):
```
Image → Scale → 256×256, Cubic resampling
```

### 7.4 Сохранить в проект
```
assets/characters/body/
    body_idle.png
    body_run.png
    body_jump.png
    body_fall.png
    body_hurt.png
    body_dead.png
assets/characters/face/
    face_happy.png
    face_focus.png
    face_pain.png
    face_angry.png
    face_scared.png
    face_dead.png
```

---

## 8. Минимальный тест (3 спрайта вместо 12)

Если хочешь быстро проверить подход, начни с минимума:
1. `body_idle.png` — главный промт из раздела 4
2. `face_happy.png` — промт из раздела 6.1
3. `face_pain.png` — промт из раздела 6

Подложи в `assets/characters/` и Claude сделает интеграцию в `player.gd`
без остальных поз (они упадут в idle). Потом дженеришь остальные.

---

## 9. Что Claude сделает после генерации

1. `feature/character-sprites` ветка
2. Заменит `_draw_ball` в `player.gd` на `Sprite2D` (body) + `Sprite2D` (face)
3. `body_sprite.modulate = player_color` для тинта
4. State machine: idle/run/jump/fall/hurt/dead → body_texture swap
5. Emotion machine: happy/focus/pain/angry/scared/dead → face_texture swap
6. Сохранит эмблемы способностей поверх (они уже процедурные)
7. Анимация дыхания/squash-stretch останется (scale tween поверх спрайта)
8. Smoke test в Godot + LOG + finish_branch

---

## 10. Частые ошибки nanobanana и как их обходить

### Проблема: модель добавляет руки/ноги несмотря на запрет
**Решение**: повторить "no limbs, pure ball only" в самом конце промта, после
всей субъектной части. Последние токены имеют больший вес на генерации.

Если первая генерация всё равно с руками/ногами:
- Пере-генерить с более категоричным "The character is LITERALLY just a
  sphere-shaped yarn ball. Period. No protrusions except the tuft."
- Или использовать negative prompt (если доступен): "arms, legs, hands,
  feet, limbs, mittens, paws, stumps, protrusions"

### Проблема: фон не полностью прозрачный
**Решение**: в промте жёстко требовать "FULLY TRANSPARENT PNG BACKGROUND,
checkerboard pattern around character". После — пост-обработка (раздел 7.1).

### Проблема: позы между спрайтами не консистентные
**Решение**: всегда прикреплять `body_idle.png` как reference image, и в
промте писать "keep EXACT same character". Если nanobanana игнорирует
референс — сказать в промте "use the attached image as the character to
modify, only change the described pose".

### Проблема: контур не чёрный а цветной
**Решение**: "solid pure black (#000000) outline, not brown, not dark
gray, pure hex 000000 black".

---

## 11. Итого промтов

- **1 главный** (body_idle — без референса)
- **5 вариаций поз** (с body_idle как reference image)
- **1 главный лицевой** (face_happy — без референса)
- **5 вариаций эмоций** (с face_happy как reference)

**Всего**: 12 генераций, из них 2 — "с нуля", 10 — "с reference image".
