# Промты для генерации персонажа TangleBattle через nanobanana 2

Файл содержит готовые промты для Google nanobanana 2 (Gemini 2.5 Flash Image)
для генерации персонажа-клубка и его поз/эмоций.

---

## Философия

Персонаж = **настоящий клубок ниток, нарисованный для игры**. Не cartoon
mascot а-ля Kirby/Fall Guys (получается AI-плоско), а текстурный клубок
который выглядит как реальный кусок пряжи, но стилизован для использования
как игровой спрайт.

Образцы стиля для нейронки (упомянуть в промте):
- Hand-painted 2D game illustration (Cuphead inanimate objects, Hollow Knight props)
- Children's book illustration with visible texture
- Soft digital painting (Procreate / Clip Studio Paint look)
- НЕ flat vector cartoon, НЕ photorealistic 3D рендер

**Один персонаж → 4 цвета через тинт в Godot** (`Sprite2D.modulate = player_color`).
Базовый спрайт — кремово-белый. WHITE × player_color = чистый цвет игрока.

**Персонаж — БЕЗ рук, БЕЗ ног, БЕЗ конечностей.** Это буквально шар из ниток.
Единственные допустимые "отростки" — кончики ниток (loose strands), которые
естественны для клубка пряжи.

---

## 1. Цветовая схема для чистого тинта

| Элемент | Цвет | После тинта в RED |
|---------|------|-------------------|
| Основные нитки | Кремово-белый `#F5F0E5` | Красный с лёгким тёплым оттенком |
| Тени между нитками | Светло-серый `#B5B0A8` | Тёмно-красный (естественная глубина) |
| Глубокие тени снизу | Средний серый `#807870` | Очень тёмный красный (контактные тени) |
| Контур (тонкий, 1-2px) | Тёмно-серый `#3A352F` | Почти чёрный (контур читаемости) |
| Лицо | Отдельный спрайт, не тинтуется | Остаётся тёмным на любом цвете |

**Критично**: цвета шара должны быть в диапазоне светло-кремового → серого.
Никаких насыщенных цветов, никакой коричневой пряжи, никакой синевы — только
нейтральные тоны, чтобы тинт работал чисто.

---

## 2. Технические требования

| Параметр | Значение |
|----------|----------|
| Размер генерации | 1024×1024 px (даунскейл до 256 в игре) |
| Формат | PNG с альфа-каналом |
| Центр | Геометрический центр клубка = центр изображения |
| Поле вокруг | 12-15% padding (хохолок и стрэнды требуют места) |
| Контур | Мягкий тонкий (1-2px), НЕ жирный cartoon outline |
| **Лица** | НА ТЕЛЕ ЛИЦА НЕТ — только отдельные face-overlay спрайты |

---

## 3. Общий стилевой блок (вставлять в начало каждого промта тела)

```
STYLE: Hand-painted 2D game illustration of a soft realistic ball
of yarn, stylized for use as a game sprite. Think Cuphead-era
inanimate object art or hand-painted children's book illustration —
NOT flat vector cartoon, NOT 3D render, NOT slick AI art. The yarn
should look tactile and soft, like real wool or cotton fiber that
you could touch.

YARN APPEARANCE: The ball is made of many criss-crossing strands of
fluffy cream-white yarn (#F5F0E5) wound and knit together. The
weave is irregular and organic — not a perfect spiral, but a real
tangle of overlapping threads going in many directions. Individual
strands are visible. Slight stray fibers stick out from the
silhouette edge giving a soft fuzzy appearance. One or two loose
yarn ends ("tails") trail off the ball — these are the start/end of
the yarn strand.

SHADING: Soft natural shadows in the deeper gaps between thread
layers (light gray #B5B0A8). A medium gray (#807870) shadow under
the ball where it would meet the ground (but no actual ground
visible — just a soft contact shadow on the bottom of the ball
itself). NO gradients fading into colors. NO highlights other than
small soft white spots on the topmost threads from natural
top-light.

OUTLINE: Optional thin (1-2px) dark gray (#3A352F) outline only on
the inner thread shapes for definition — NOT a thick cartoon outline
around the whole silhouette. The ball's silhouette boundary is
defined by the natural fluffy yarn edge fading into transparency.

NO LIMBS RULE: The character is a PURE BALL OF YARN. Absolutely no
arms, no legs, no hands, no feet, no mittens, no paws, no stumps,
no anthropomorphic protrusions of any kind. The ONLY allowed
protrusions are: (a) loose yarn ends/tails trailing from the wind,
(b) stray fluff fibers. Nothing else.

NO FACE RULE: Do NOT draw eyes, mouth, or any face features on the
ball. The ball is just yarn texture — face will be added separately
as a transparent overlay sprite in the game engine. Just generate a
faceless yarn ball.

BACKGROUND: Fully transparent. Only the yarn ball is visible.
Checkerboard transparency pattern around the character. No ground,
no shadow on ground, no border, no background color, no scenery.

COMPOSITION: Yarn ball centered in 1024x1024 frame with 12-15%
padding around all edges (extra padding because loose strands
extend beyond the main ball). Ball takes up about 70-75% of image
height (smaller than the previous version because we need room for
trailing yarn strands).
```

---

## 4. Главный промт — `body_idle.png` (ГЕНЕРИРУЕТСЯ ПЕРВЫМ)

Этот спрайт — **референс** для всех остальных. Сначала генерим его, потом
используем как image reference для поз и эмоций.

```
Generate a soft hand-painted ball of cream-white yarn for use as a
game sprite. No face, no limbs.

[вставить полностью STYLE + YARN + SHADING + OUTLINE + NO LIMBS +
NO FACE + BACKGROUND + COMPOSITION блок из раздела 3]

POSE: Idle resting pose. The ball is roughly spherical but with the
natural slight irregularity of a real yarn ball — not perfectly
round, slightly squashed at the bottom from its own weight, slightly
oval (1:1.05 ratio, very subtle). Two loose yarn tails: one short
2-3cm tail sticking up from the top of the ball (slightly curling,
the "starting end"), one longer 5-6cm tail trailing down and to the
right from the lower-right side of the ball (the "current working
end" — the loose strand that would be unraveling).

DETAIL FOCUS: The viewer should be able to count individual visible
threads on the ball surface. The criss-crossing weave is the
character's main visual. Show the texture clearly.

REMINDER: NO FACE on the ball. NO arms, NO legs, NO limbs. Only the
yarn ball with two loose strand tails (top short, bottom-right
longer) and natural fuzzy fibers around the silhouette.
```

---

## 5. Промты для остальных поз (с image reference)

**Важно**: для каждого промта ниже — **прикрепи `body_idle.png` как reference
image** в nanobanana и добавь этот префикс:

> `REFERENCE IMAGE: Use the attached image as the EXACT character to modify. Keep the same yarn texture, same cream-white color, same thread weave style, same outline thickness, same loose strand style. Same faceless yarn ball with no limbs. Only change the pose and any deformation/strand-behavior as described below.`

### `body_run.png` — катится / прыгает вперёд
```
Pose change: Rolling/bouncing forward motion (the ball has no legs,
so movement is shown through deformation and trails). Changes:
1. Body horizontally squashed (1.2:1 aspect, wider than tall)
2. Body tilted 25° forward to the right (in motion direction)
3. The longer bottom-right loose yarn tail now trails far behind
   to the LEFT (5-6 strand-curves), as if dragging from speed
4. The short top tail is bent backward (to the left)
5. Three to four soft yarn-fiber motion streaks trailing behind the
   ball on the left side (made of the same cream-white fiber, very
   soft, fading into transparency — like motion trails of fluff)
6. A soft gray dust puff (no hard outline, just soft cream-gray
   smudges) below the ball where it would have just bounced
7. A few extra stray fibers fluffed out on the back-left side from
   the wind
NO FACE. NO LIMBS. Just a deformed rolling yarn ball with trailing
strands and motion fluff.
```

### `body_jump.png` — прыжок вверх
```
Pose change: Jumping/launching upward (ball has no legs to push off
with, so jump is shown through stretch and trails below). Changes:
1. Body vertically stretched (1:1.2 aspect, taller than wide)
2. Both loose yarn tails trail STRAIGHT DOWN below the ball as if
   pulled by gravity / the take-off force (long curving strands
   pointing toward bottom of frame)
3. Three to five faint upward-curving cream-fiber motion trails
   below the ball (soft fluff trails, not hard lines) — implying
   the ball was just launched from below
4. Extra stray fibers on the bottom of the ball (more fuzz than
   idle) from the launch
5. Top of the ball slightly more compressed than bottom (acceleration
   stretching the bottom)
NO FACE. NO LIMBS. Just a stretched yarn ball with trailing strands
pointing down and fluff trails below.
```

### `body_fall.png` — падение
```
Pose change: Falling downward (ball has no limbs, falling is shown
through subtle stretch and air-resistance behavior of strands).
Changes:
1. Body slightly vertically stretched (1:1.08 aspect — less than
   jump because falling is more passive)
2. Both loose yarn tails trail STRAIGHT UP above the ball, as if
   air resistance is pulling them upward (the ball is falling, the
   strands lag behind)
3. Some stray fibers around the upper edge of the ball are pushed
   upward by air resistance (subtle "hair-up" effect)
4. Two faint vertical wind-streak fibers on either side of the ball
   (very soft, fading)
5. Slight blurring at the bottom of the ball from downward motion
NO FACE. NO LIMBS. Just a yarn ball with strands trailing UPWARD
showing it's falling down.
```

### `body_hurt.png` — получил урон
```
Pose change: Hit reaction (the ball is a yarn ball, so damage shows
as the yarn getting frayed/disrupted). Changes:
1. Body horizontally squashed and asymmetric (1.3:1 aspect, with the
   right side more flattened — as if struck from the right)
2. Six to eight loose yarn strands suddenly POPPED OUT of the ball
   surface (medium-length 3-4cm cream-white strands at random angles,
   each with the same hand-painted style as the main yarn — these are
   threads that got pulled loose from the impact)
3. The original two loose tails are now displaced — top tail is bent
   to the left, bottom-right tail is twisted/kinked
4. A burst of stray fluff fibers around the impacted side (right)
5. Four small impact stars around the ball (4-point sparkle marks,
   thin dark gray outline only, no fill — like a comic book "hit"
   indicator)
6. The yarn texture is slightly more disheveled than idle — some
   threads visibly out of place, weave looking messier
NO FACE. NO LIMBS. Just a fraying, deformed yarn ball with popped
strands and impact marks.
```

### `body_dead.png` — размотан (смерть)
```
Pose change: Defeated / unraveled. The yarn ball is coming undone.
Changes:
1. The main ball has shrunk to about 50% of its original volume — a
   smaller, looser, less tightly wound version
2. The ball is tilted 35° to the side (rolled over)
3. Approximately 12-15 long loose yarn strands trail out from the
   ball forming chaotic loops, curls, and tangles in the bottom-right
   half of the image. These should look like real unraveled yarn —
   long curving lines with natural sag and curl, not straight lines.
4. Two or three small detached yarn loops floating near the ball
   (loose loops that came completely off)
5. The remaining ball weave is much looser — gaps visible between
   threads, you can see the inner structure
6. A couple of single stray thread fibers floating in the air around
   the unraveled tangle
7. Soft contact shadow under the unraveled mess
NO FACE. NO LIMBS. Just a smaller deflated yarn ball with massive
unraveled tangle of strands beside it.
```

---

## 6. Промты для лиц (отдельные спрайты 512×512)

Лицо рендерится как **отдельный Sprite2D** поверх тела, без тинта. Поскольку
тело теперь без лица, лицевой оверлей **всегда виден** в игре (включая
default happy в idle).

Стиль лица должен соответствовать "hand-painted yarn ball" эстетике —
не slick anime kawaii, а будто лицо нарисовано/вышито на клубке.

**Стилевой блок для всех лиц:**
```
STYLE: Minimalist hand-drawn cartoon face elements ONLY — eyes and
mouth, nothing else. The features should look hand-painted with
slight irregularity (not perfect digital strokes), as if drawn or
stitched onto the yarn surface. Solid dark color (#2A2520 — very
dark warm brown, almost black but warmer to fit the yarn theme).
Tiny soft white highlight dots inside eye pupils for life.

LAYOUT: Features positioned to overlay a round face. Eyes in the
upper-center area (~38% from top edge of image), spaced about 38%
of image width apart (so eye centers are ~24% image width from
center). Mouth centered horizontally, ~20% below the eye centerline.

NO HEAD SHAPE. NO BODY. NO OUTLINE around face area. NO ball, NO
yarn, NO silhouette. ONLY the eyes and mouth lines.

BACKGROUND: Fully transparent. PNG 512x512 with alpha channel.

REMINDER: Only draw the eyes and mouth strokes — nothing else.
```

### `face_happy.png` (генерить первым, использовать как reference для остальных)
```
Subject: Two medium-sized round dark-brown eyes, each with a small
white highlight dot in the upper-left of the pupil for sparkle. Eyes
have very slight irregularity in their roundness (hand-drawn feel,
not perfect circles). Small upturned crescent smile (curved arc, 3px
hand-painted stroke) centered between and below the eyes. Friendly
calm expression, not aggressively happy — confident mascot.
```

### `face_focus.png` — прицеливание
```
Same hand-drawn style as face_happy reference. Change: Eyes are
narrowed into determined focused horizontal squints (lens/leaf
shape, ~60% width of original eye, ~40% height). Each squint is
solid dark brown with a tiny highlight. Mouth is a slightly downward-
slanted straight horizontal line (3px) — serious concentrated
expression, not angry, just focused.
```

### `face_pain.png` — боль
```
Same hand-drawn style as face_happy reference. Change: Eyes are
closed tight into scrunched >_< shapes (two small inverted V
curves, 3px thick, hand-drawn feel). No highlight dots since eyes
are closed. Mouth is a small downturned frowny U-shape with a tiny
triangular gap inside showing an "ow" expression.
```

### `face_angry.png` — ярость (после килла)
```
Same hand-drawn style as face_happy reference. Change: Eyes are
angry narrowed slits (similar to focus but more extreme — only ~30%
height of normal eyes) with sharp angled angry EYEBROWS above each
(V-shape wedges, 3px thick, tilted inward toward the nose, hand-
painted with slight irregularity). Pupils visible inside the slits.
NO highlight dots. Mouth is a snarl showing 2-3 small sharp pointed
"teeth" (triangular shapes pointing downward from upper lip line) in
an upward-curving growl. Menacing but still cute (not horror).
```

### `face_scared.png` — страх (HP < 30%)
```
Same hand-drawn style as face_happy reference. Change: Eyes are
WIDE OPEN (larger than idle by ~20%), with TINY pupils as small
dots in the center (showing fear-shrink). Three small motion-wobble
arcs around the OUTSIDE of each eye (short 2px curves, 3 per eye,
suggesting trembling). Mouth is a tiny worried "o" shape (small
vertical oval). Add one small teardrop/sweat shape next to the
left eye (outside the eye, below it, dark color matching the eyes).
```

### `face_dead.png` — мёртвый (X-eyes)
```
Same hand-drawn style as face_happy reference. Change: Eyes are
simple X-shapes made from two crossed diagonal lines each (3px
hand-painted strokes, crossing at the center, ~40% size of normal
eyes). No highlight dots. Mouth is a slightly open small vertical
oval (just a short outlined oval, 3px stroke) showing
unconsciousness.
```

---

## 7. После генерации — обязательные шаги

### 7.1 Очистить фон до полной прозрачности
1. Открыть PNG в Photopea
2. Если nanobanana оставила любой фон — `Magic Wand` (threshold 5-15) на
   углу, удалить
3. Для тела: **аккуратно** не удалить кремовые/серые пиксели самого клубка
   (использовать selection с порогом, не Color to Alpha)
4. Для лиц: можно жёстко — `Image → Adjustments → Threshold` на 128, всё
   тёмное оставить, всё светлое в прозрачность

### 7.2 Выровнять центры всех 6 поз тела
Все 6 PNG должны иметь одинаковый **центр клубка** (не bounding box):
- Открыть все 6 как слои в Photopea
- Включить полупрозрачность каждого слоя (50%)
- Подвинуть каждый так, чтобы центры клубков совпадали (не края, не центр
  bbox — именно геометрический центр шара)
- Сохранить каждый отдельно как 1024×1024 PNG с тем же центром
- Иначе клубок будет "прыгать" при смене позы в игре

### 7.3 Даунскейл до рабочего размера
- Генерация: 1024×1024 (для деталей)
- Игра: **256×256** (Godot скейлит под радиус игрока)
- В Photopea: `Image → Image Size → 256×256, Bicubic Sharper`

### 7.4 Файлы в проект
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

## 8. Минимальный тест (3 спрайта)

Для быстрой проверки подхода до генерации всех 12:
1. `body_idle.png` — главный промт (раздел 4)
2. `face_happy.png` — главный лицевой промт (раздел 6.1)
3. `face_pain.png` — для проверки смены эмоции

Положи в `assets/characters/`. Claude интегрирует в `player.gd` без
остальных поз/эмоций (они будут падать в idle/happy fallback). Если выглядит
хорошо в игре — генерим остальные 9.

---

## 9. Что Claude сделает после генерации

1. `feature/character-sprites` ветка (новая)
2. Заменит `_draw_ball` в `player.gd` на:
   - `Sprite2D` "Body" с `texture = body_textures[current_pose]`
   - `Sprite2D` "Face" (child of Body) с `texture = face_textures[current_emotion]`
3. `body_sprite.modulate = player_color` — тинт цветом игрока
4. `face_sprite.modulate = Color.WHITE` — лицо не тинтуется
5. Pose state machine в `_physics_process`:
   - `velocity.y < -50` → `jump`
   - `velocity.y > 50` → `fall`
   - `abs(velocity.x) > 20` → `run`
   - `hurt_flash_timer > 0` → `hurt`
   - `not is_alive` → `dead`
   - иначе → `idle`
6. Emotion state machine:
   - `not is_alive` → `dead`
   - `hurt_flash_timer > 0` → `pain`
   - `kill_glow_timer > 0` → `angry`
   - `hp < MAX_HP * 0.3` → `scared`
   - `is_aiming or attacking` → `focus`
   - иначе → `happy`
7. Squash/stretch анимация дыхания через scale tween на Body Sprite2D
8. Эмблемы способностей остаются процедурными в `_draw()` поверх спрайтов
9. Smoke test в Godot + LOG + finish_branch

---

## 10. Если nanobanana всё-таки рисует AI-стиль

Признаки "AI cartoon vector":
- Идеально круглый ball, симметричный
- Гладкая заливка без видимой текстуры ниток
- Жирный 5px чёрный контур
- Slick shading с градиентами
- Generic anime eyes

Если получилось так — пере-генерить с усилением:
- Добавить в начало: `IMPORTANT: hand-painted natural texture, NOT
  generic vector cartoon. Show individual yarn fibers and weave structure.
  NO smooth gradients, NO perfect shapes, NO thick outline.`
- Добавить негативный промт (если поддерживается): `vector art, flat
  cartoon, smooth shading, perfect circle, mascot logo, generic AI art`
- Указать конкретные референсы: `art style of Cuphead inanimate objects,
  or hand-painted Studio MDHR background props`

---

## 11. Итого промтов

- **1 главный** (body_idle — без референса)
- **5 вариаций поз тела** (с body_idle как reference image)
- **1 главный лицевой** (face_happy — без референса)
- **5 вариаций эмоций** (с face_happy как reference)

**Всего**: 12 генераций, из них 2 — "с нуля", 10 — "с reference image".

Минимум для теста: **3 спрайта** (см. раздел 8).
