# Промты для генерации персонажа TangleBattle через nanobanana 2

Файл содержит готовые промты для Google nanobanana 2 (Gemini 2.5 Flash Image)
для генерации персонажа-клубка и его поз/эмоций.

**Философия**: генерируем **ОДНОГО** персонажа в нейтрально-белом цвете, затем
в Godot через `Sprite2D.modulate = player_color` получаем 4 цветных варианта
(красный/синий/зелёный/жёлтый) без перегенерации.

---

## 1. Цветовая схема для чистого тинта

| Элемент | Цвет | Почему |
|---------|------|--------|
| **Тело (нитки)** | Чистый белый `#FFFFFF` | `WHITE × player_color = player_color` — точный тинт |
| **Тени** | Светло-серый `#D0D0D0` | `GRAY × RED = ДТЁМНО-КРАСНЫЙ` — естественная тень игрока |
| **Контур** | Чистый чёрный `#000000` | `BLACK × anything = BLACK` — контур сохраняется при любом тинте |
| **Фон** | **Полностью прозрачный** | Требование для спрайта в Godot |

Лицо — **отдельный спрайт** (не тинтуется), чтобы глаза/рот остались
чёрными на тело любого цвета.

---

## 2. Технические требования

| Параметр | Значение |
|----------|----------|
| Размер генерации | 1024×1024 px (выше качество, даунскейл до 256 в игре) |
| Формат | PNG с альфа-каналом |
| Центр | Геометрический центр персонажа = центр изображения |
| Поле вокруг | 10% padding по краям (чтобы не резать при кропе) |
| Антиалиасинг контура | Минимальный (резкие края для pixel-game стиля) |

---

## 3. Общий шаблон (повторять в каждом промте для консистентности)

Эта часть **добавляется в начало** каждого промта ниже:

```
STYLE: Flat cartoon mascot illustration, in the style of Fall Guys or
Kirby. Bold 3-pixel-thick pure BLACK (#000000) outline. Body filled
with pure WHITE (#FFFFFF) yarn texture — visible spiral woven thread
pattern wrapping around the ball. Subtle cell-shading using ONE light
gray tone (#D0D0D0) for shadows under belly and behind limbs. NO
gradients. NO colored fills on body. NO realistic rendering.

BACKGROUND: Fully transparent. Only the character is visible. No
ground, no shadow, no border, no color fill behind the character.

COMPOSITION: Character centered in frame, 10% padding around all
edges. Character takes up about 80% of image height. PNG 1024x1024.
```

---

## 4. Главный промт — `body_idle.png` (ГЕНЕРИРУЕТСЯ ПЕРВЫМ)

Этот спрайт — **референс** для всех остальных. Сначала генерим его, потом
используем как image reference для поз и эмоций.

```
Generate a cute cartoon yarn-ball game character, idle standing pose.

[вставить STYLE+BACKGROUND+COMPOSITION блок сверху]

SUBJECT: A round soft plush ball character made of visible woven yarn
threads (pure white #FFFFFF body with spiral-wrapped thread pattern).
The ball is slightly taller than wide (1:1.05 ratio) from gentle
breathing. A short loose yarn tuft (3 strands) dangles from the top
of the head like a pompom. Two tiny stubby round arms with simple
mitten hands (no fingers) hanging relaxed at its sides. Two tiny
stubby legs with rounded feet standing flat. The character is facing
the camera slightly turned 15° to its right (3/4 view).

FACE: Large expressive round black eyes (#000000) with tiny WHITE
highlight dots inside each pupil for sparkle. Eyes take up about 25%
of the upper body. Simple closed upturned smile in solid black —
friendly but with character, like a confident mascot. NO eyebrows.
NO nose. NO mouth interior details.

LIGHTING: Flat top-light. Soft gray shadow under the belly curve
(bottom 25% of ball). Tiny gray shadow patches behind each arm and
behind the far-side leg for depth.

IMPORTANT: Fully transparent PNG background. Character must read
clearly against any background color.
```

---

## 5. Промты для остальных поз (с image reference)

**Важно**: для каждого промта ниже — **прикрепи `body_idle.png` как reference
image** в nanobanana и добавь этот префикс:

> `REFERENCE IMAGE: Keep the EXACT same character — same body shape, same yarn-thread pattern, same eye size and style, same mitten-hand shape, same foot shape, same outline thickness. Only change the pose as described. Do not change any colors.`

### `body_run.png` — бег
```
Pose change: Running pose. Body tilted forward 20° in the direction
of motion (to the right). Body horizontally squashed (1.15:1 aspect).
Legs stretched apart mid-stride: right leg forward and up (bent knee),
left leg back and down (stretching). Arms slightly swung back for
momentum. Three short dark motion-blur streaks trailing behind the
back leg (same black outline color, 2px thick). Happy focused
expression — same smile as idle.
```

### `body_jump.png` — прыжок вверх
```
Pose change: Jumping upward pose. Body vertically stretched (1:1.15
aspect, taller than wide). Both arms raised diagonally up and
outward in excitement like "whee!". Both legs tucked slightly bent
below the body. Small yarn tuft on top is flying upward from wind.
Eyes wide open excited. Smile is an open happy curve.
```

### `body_fall.png` — падение
```
Pose change: Falling pose. Body slightly vertically squashed (1:0.95
aspect). Both arms spread wide horizontally for balance. Both legs
pointing straight down ready to land. Yarn tuft on top droops
slightly. Mouth is a small "o" of mild concern. Eyes slightly
widened with small pupils (showing concentration, not fear).
```

### `body_hurt.png` — получил урон
```
Pose change: Hit-reaction pose. Body horizontally squashed and
deformed (1.2:1 aspect, as if struck from the side). Several
(5-6) loose yarn threads pop out from random spots on the body
(getting frayed). Arms splayed outward in surprise. Eyes scrunched
closed into two small tight curve shapes (black lines, like >_<).
Mouth is a small downturned grimace showing a triangular "ow" shape.
Four small impact stars (4-point sparkle shapes, black outline only)
around the body edges.
```

### `body_dead.png` — размотан (смерть)
```
Pose change: Defeated unraveled pose. The ball is partially unraveled
— the main body is now 60% its original size and tilted 30° to the
side. Loose yarn threads (8-10 of them) trail out to the bottom-right
forming chaotic loops and curves. X-shaped eyes made of two crossed
2px black lines each (dead expression). Mouth is a flat straight
horizontal line. Arms hanging limp. One leg visible, the other
tangled in the unraveled yarn. No motion lines, no stars.
```

---

## 6. Промты для лиц (отдельные спрайты 512×512)

Лицо рендерится как **отдельный Sprite2D** поверх тела, без тинта. Тело
содержит базовое "счастливое" лицо; при событиях (урон/killed/low HP)
поверх тела накладывается face-overlay с другой эмоцией.

**Стилевой блок для всех лиц:**
```
STYLE: Minimalist cartoon face elements ONLY — just eyes and mouth.
No head shape, no body, no outline around face area. Pure black
(#000000) for all features. Transparent background. PNG 512x512.
Features positioned as if overlaying a round face: eyes in the upper
center area ~35% from top, spaced about 40% of image width apart.
Mouth centered horizontally, ~20% below the eyes.
```

### `face_happy.png` (генерить первым, использовать как reference для остальных)
```
Subject: Two large round black eyes, each with a tiny white highlight
dot (small circle in upper-left of each pupil). Small upturned
crescent smile (curved arc) between the eyes. Classic cute mascot
face. No eyebrows.
```

### `face_focus.png` — прицеливание
```
Same style as face_happy reference. Change: eyes are narrowed into
sharp determined horizontal squints (thick lens shape, not round
circles). Mouth is a straight horizontal line (serious concentration).
No highlight dots in eyes (too narrow to show).
```

### `face_pain.png` — боль
```
Same style as face_happy reference. Change: eyes are closed into
tight scrunched >_< shapes (two small inverted V curves, 3px thick).
Mouth is a small downturned frowny U-shape showing a tiny triangular
tongue or "ow" gap.
```

### `face_angry.png` — ярость (после килла)
```
Same style as face_happy reference. Change: eyes are angry narrowed
with sharp angled eyebrows (V-shape wedges above them, 3px thick).
Pupils are smaller and more intense. Mouth is a snarl showing 2-3
small sharp pointed teeth (triangular shapes) in an upward-curving
growl.
```

### `face_scared.png` — страх (HP < 30%)
```
Same style as face_happy reference. Change: eyes are WIDE open in
shock (larger circles than idle), pupils are TINY dots (showing
shrunken from fear). Small motion-wobble lines around each eye edge
(2-3 short curved strokes). Mouth is a tiny worried "o" (small
vertical oval). Optional: one small teardrop sweat shape next to one
eye.
```

### `face_dead.png` — мёртвый (X-eyes)
```
Same style as face_happy reference. Change: eyes are simple X-shapes
made from two crossed diagonal lines (3px thick, 40% of eye area
size). Mouth is a slightly open oval (vertical, small) showing
unconsciousness.
```

---

## 7. После генерации — обязательные шаги

### 7.1 Проверить прозрачность фона
Если nanobanana оставила светлый фон (встречается) — прогнать через GIMP:
```
Layer → Transparency → Color to Alpha → выбрать белый цвет → OK
```
Но **только для лиц**. Для тела нельзя — там нужен WHITE как цвет тела.
Для тела: открыть в Photopea/GIMP, проверить что в углах прозрачность, при
наличии белого фона — использовать magic wand с threshold 5 на углу и удалить.

### 7.2 Кроп + единый канвас для всех 6 поз тела
Все 6 PNG должны иметь **одинаковый центр персонажа**. Минимум:
- Открыть все 6 в Photopea
- Наложить все 6 слоями, выровнять по центру визуально (центр глаз или центр живота)
- Сохранить каждый на канвасе 1024×1024 с одним центром
- Иначе персонаж будет "прыгать" при смене позы

### 7.3 Даунскейл до рабочего размера
1024 — для генерации (максимум деталей).
Для игры достаточно **256×256** (Godot сам масштабирует под радиус игрока).
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
без остальных поз (они будут падать в idle). Потом дженеришь остальные.

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

## 10. Итого промтов

- **1 главный** (body_idle — без референса)
- **5 вариаций поз** (с body_idle как reference image)
- **1 главный лицевой** (face_happy — без референса)
- **5 вариаций эмоций** (с face_happy как reference)

**Всего**: 12 генераций, из них 2 — "с нуля", 10 — "с reference".
