# Промты для генерации персонажа TangleBattle через nanobanana 2

Файл содержит готовые промты для Google nanobanana 2 (Gemini 2.5 Flash Image)
для генерации **полноценных анимаций** персонажа-клубка.

---

## Философия

Персонаж = **настоящий клубок ниток, нарисованный для игры**. Hand-painted
2D game illustration (Cuphead inanimate objects, Hollow Knight props), не
Flat AI-cartoon.

**Каждое действие = несколько кадров анимации**, не одна картинка. Без
многих кадров персонаж выглядит как картонный stamp, который просто меняет
картинку — нужна реальная анимация motion.

**Один персонаж → 4 цвета через тинт в Godot** (`AnimatedSprite2D.modulate
= player_color`). Базовый спрайт — кремово-белый.

**Персонаж — БЕЗ рук, БЕЗ ног, БЕЗ конечностей.** Только клубок и кончики
пряжи (loose strand tails).

**Тело — БЕЗ ЛИЦА**. Лицо рендерится как отдельный спрайт-оверлей.

---

## 1. Цветовая схема для чистого тинта

| Элемент | Цвет | После тинта в RED |
|---------|------|-------------------|
| Основные нитки | Кремово-белый `#F5F0E5` | Красный с тёплым оттенком |
| Тени между нитками | Светло-серый `#B5B0A8` | Тёмно-красный (глубина) |
| Глубокие тени снизу | Средний серый `#807870` | Контактная тень |
| Внутренние линии | Тёмно-серый `#3A352F` | Почти чёрный |
| Лицо (отдельно) | Тёмно-тёплый `#2A2520` | Не тинтуется |

---

## 2. Технические требования

| Параметр | Значение |
|----------|----------|
| Разрешение генерации | 1024×1024 px (даунскейл до 256 в игре) |
| Формат | PNG с альфа-каналом |
| Центр | Геометрический центр клубка = центр изображения |
| Padding | 12-15% по краям (для loose strands) |
| Контур | Тонкий (1-2px), мягкий, не cartoon |

### Конвенция именования файлов
```
body_<action>_<frame>.png    # body_run_01.png, body_run_02.png ...
face_<emotion>_<frame>.png   # face_happy_01.png, face_happy_02.png
```

Кадры нумеруются с `01`, двузначно — для правильной сортировки.

### Количество кадров на действие

| Действие | Кадров | Темп в игре | Комментарий |
|----------|--------|-------------|-------------|
| `body_idle` | 4 | 3 fps | Медленное "дыхание" клубка |
| `body_run` | 6 | 12 fps | Цикл "катится" |
| `body_jump` | 3 | по событию | Anticipation → launch → apex |
| `body_fall` | 2 | 4 fps | Стабильное падение |
| `body_hurt` | 2 | по событию | Импакт → recoil |
| `body_dead` | 5 | 8 fps | Прогрессия размотки |
| `face_happy` | 2 | 0.3 fps | Моргание |
| `face_focus` | 1 | — | Статика |
| `face_pain` | 2 | по событию | Peak → fading |
| `face_angry` | 2 | по событию | Snarl flash |
| `face_scared` | 2 | 6 fps | Дрожание |
| `face_dead` | 1 | — | Статика |

**Тело: 22 кадра. Лицо: 10 кадров. Всего: 32 кадра.**

---

## 3. Общий стилевой блок (вставлять в начало каждого промта тела)

```
STYLE: Hand-painted 2D game illustration of a soft realistic ball
of yarn, stylized for use as a game sprite. Think Cuphead-era
inanimate object art or hand-painted children's book illustration —
NOT flat vector cartoon, NOT 3D render, NOT slick AI art. The yarn
should look tactile and soft, like real wool or cotton fiber.

YARN APPEARANCE: The ball is made of many criss-crossing strands of
fluffy cream-white yarn (#F5F0E5) wound and knit together. Irregular
organic weave with overlapping threads going in many directions.
Individual strands are visible. Slight stray fibers stick out from
the silhouette edge giving a soft fuzzy appearance. Loose yarn ends
("tails") trail off the ball — start/end of the yarn strand.

SHADING: Soft natural shadows in deeper gaps between thread layers
(light gray #B5B0A8). Medium gray (#807870) shadow under the ball.
NO gradients fading into colors. NO highlights other than small soft
white spots on the topmost threads from natural top-light.

OUTLINE: Optional thin (1-2px) dark gray (#3A352F) ONLY on inner
thread shapes — NOT a thick cartoon outline around the silhouette.
Silhouette boundary is defined by the natural fluffy yarn edge.

NO LIMBS RULE: PURE BALL OF YARN. Absolutely no arms, no legs, no
hands, no feet, no anthropomorphic protrusions. ONLY allowed
protrusions: loose yarn ends/tails and stray fluff fibers.

NO FACE RULE: Do NOT draw eyes, mouth, or any face features. Just
generate a faceless yarn ball — face is added separately as an
overlay sprite in the game engine.

BACKGROUND: Fully transparent. Checkerboard transparency around
character. No ground, no shadow on ground, no border.

COMPOSITION: Yarn ball centered in 1024x1024 frame with 12-15%
padding around all edges. Ball takes up about 70-75% of image
height (room for trailing strands).
```

---

## 4. BODY — Главный референс `body_idle_01.png` (ГЕНЕРИРУЕТСЯ ПЕРВЫМ)

Все остальные кадры тела используют этот как **image reference**.

```
Generate a soft hand-painted ball of cream-white yarn for use as a
game sprite. No face, no limbs. This is FRAME 1 of the IDLE
breathing animation cycle (4 frames total) — the neutral resting
state.

[вставить полностью STYLE + YARN + SHADING + OUTLINE + NO LIMBS +
NO FACE + BACKGROUND + COMPOSITION блок из раздела 3]

POSE — IDLE FRAME 1 (NEUTRAL): The ball is roughly spherical with
slight irregularity (not perfectly round, slightly squashed at the
bottom from its weight). Aspect ratio 1:1 (perfectly neutral). Two
loose yarn tails: one short 2-3cm tail sticking up from the top of
the ball (slightly curling, the "starting end"), one longer 5-6cm
tail trailing down and to the right from the lower-right side (the
"working end"). Tails hang relaxed.

DETAIL FOCUS: Show many individual visible threads on the ball
surface. The criss-crossing weave is the character's main visual.
Texture should be clearly readable.

REMINDER: NO FACE on the ball. NO arms, NO legs. Only the yarn
ball with two loose strand tails and natural fuzzy fibers.
```

---

## 5. BODY ANIMATIONS — кадры с image reference

**Префикс к каждому промту ниже** (с `body_idle_01.png` как reference image):

> `REFERENCE IMAGE: Use the attached image as the EXACT character. Keep the same yarn texture, cream-white color, thread weave, outline thickness, loose strand style. Same faceless yarn ball with no limbs. Only change the pose/deformation/strand-behavior as described. Maintain the same image center for consistent animation playback.`

### 5.1 IDLE — 4 кадра дыхания (3 fps цикл)

#### `body_idle_02.png` — слегка сжат (выдох)
```
ANIMATION FRAME — IDLE 2/4 (slight compress on exhale): Same
character but ball is slightly horizontally compressed and lower:
aspect ratio 1.05:0.95 (very subtle, wider and shorter than neutral).
The ball appears to sink ~3% lower in the frame. Both loose strand
tails hang slightly lower (gravity from compression). All other
details identical to reference.
```

#### `body_idle_03.png` — нейтрал (как frame 1, но кадр в цикле)
```
ANIMATION FRAME — IDLE 3/4 (back to neutral, transitioning to
inhale): IDENTICAL to the reference image (idle frame 1). 1:1
aspect ratio, neutral position, same strand positions. This frame
matches the reference exactly — it's the recovery point in the
breathing cycle. Output 1024x1024.
```
*(в Godot можно просто переиспользовать body_idle_01 — но если хотите
отдельный кадр для micro-variation, генерим)*

#### `body_idle_04.png` — слегка раздут (вдох)
```
ANIMATION FRAME — IDLE 4/4 (slight expand on inhale): Same character
but ball is slightly vertically stretched: aspect ratio 0.97:1.03
(very subtle, taller and narrower than neutral). The ball appears to
rise ~2% higher in the frame. Top loose strand tail lifts slightly
upward. Bottom strand tail lifts slightly. All other details
identical to reference.
```

### 5.2 RUN — 6 кадров цикла "катится" (12 fps)

Поскольку у клубка нет ног, "бег" = bouncing/rolling. Цикл из 6 кадров
показывает один полный bounce + roll.

#### `body_run_01.png` — момент удара о землю (max squash)
```
ANIMATION FRAME — RUN 1/6 (ground impact, max squash): Ball just
landed from a small bounce. Body horizontally squashed strongly:
aspect ratio 1.3:0.85 (much wider than tall). Tilted 20° forward to
the right (motion direction). The longer bottom-right loose strand
tail trails far behind to the LEFT (curling 5-6 strand-curves) from
forward momentum. Top short tail bent backward to the left. Two soft
cream-fiber motion streaks trailing behind on the left side. A small
soft cream-gray dust puff below the ball where it landed. Stray
fibers slightly fluffed on the back-left. NO FACE, NO LIMBS.
```

#### `body_run_02.png` — рикошет, начало подъёма
```
ANIMATION FRAME — RUN 2/6 (rebounding upward, mid-squash): Body
still squashed but starting to recover: aspect 1.15:0.95. Tilt 20°
forward. Strands still trailing behind but slightly less extreme
(catching up). Dust puff slightly more dispersed (fading). Two
motion streaks. Maintain strand positions consistent with reference
flow. NO FACE, NO LIMBS.
```

#### `body_run_03.png` — в воздухе, нейтральная форма
```
ANIMATION FRAME — RUN 3/6 (airborne apex, neutral shape): Body has
recovered to neutral aspect 1:1. Tilt 25° forward (more pronounced —
ball is leaning into next bounce). Strands trailing behind but more
relaxed. NO dust puff visible (ball is in air). Single faint motion
streak behind. Position in frame is slightly higher than ground
position. NO FACE, NO LIMBS.
```

#### `body_run_04.png` — пик, лёгкий vertical stretch
```
ANIMATION FRAME — RUN 4/6 (peak of bounce, slight stretch): Body
slightly vertically stretched: aspect 0.95:1.05. Still tilted ~25°
forward. This is the topmost point of the bounce. Strands flow
backward but slightly relaxed (no extreme momentum at apex). NO
motion streaks (peak moment). NO FACE, NO LIMBS.
```

#### `body_run_05.png` — начало падения
```
ANIMATION FRAME — RUN 5/6 (descending toward next bounce): Body
recovering from stretch back to neutral: aspect 1:1. Tilt 22°
forward. Strands starting to lift up slightly (air resistance from
descent). Faint downward motion lines on either side of the ball
(2-3 short fiber streaks). NO FACE, NO LIMBS.
```

#### `body_run_06.png` — почти приземлился, начало squash
```
ANIMATION FRAME — RUN 6/6 (approaching ground, beginning to squash):
Body slightly horizontally squashing as it approaches landing:
aspect 1.1:0.95. Tilt 20° forward. Strands now trailing more as
forward speed dominates. A faint hint of dust beginning to form
below. Almost ready to loop back to frame 1. NO FACE, NO LIMBS.
```

### 5.3 JUMP — 3 кадра (anticipation → launch → apex)

Прыжок — событийная анимация (играется один раз по триггеру). 3 кадра
покрывают полную дугу.

#### `body_jump_01.png` — anticipation (приседание перед прыжком)
```
ANIMATION FRAME — JUMP 1/3 (anticipation, squash down): The ball
compresses downward in preparation for jumping: aspect 1.15:0.85
(wider and much shorter than neutral). Tilt 0° (straight up). Both
loose strand tails hang DOWN limply (gravity, no upward force yet).
Stray fibers compressed tightly. Position slightly LOWER in frame
than neutral. NO motion lines. NO FACE, NO LIMBS.
```

#### `body_jump_02.png` — launch (рывок вверх)
```
ANIMATION FRAME — JUMP 2/3 (launching, vertical stretch): The ball
shoots upward with strong vertical stretch: aspect 0.85:1.3 (much
taller than wide, "rocket" shape). Tilt 0°. Both loose strand tails
trail STRAIGHT DOWN below the ball (pulled by acceleration). Three
to five faint upward-curving cream-fiber motion trails BELOW the
ball (soft fluff trails). Stray fibers stretched upward on top.
Position HIGHER in frame than neutral. NO FACE, NO LIMBS.
```

#### `body_jump_03.png` — apex (пиковая точка прыжка)
```
ANIMATION FRAME — JUMP 3/3 (apex, neutral shape with hover): Ball
has reached its highest point and is momentarily neutral: aspect
1:1.05 (very slightly stretched still). Tilt 0°. Both strands
RECOVERING from straight-down position — they curl slightly upward
again as gravity hasn't yet started pulling them. Single faint
motion line below. NO FACE, NO LIMBS.
```

После apex включается анимация `body_fall`.

### 5.4 FALL — 2 кадра (стабильное падение, цикл 4 fps)

#### `body_fall_01.png` — начальное падение
```
ANIMATION FRAME — FALL 1/2 (early descent): Body slightly vertically
stretched downward: aspect 0.95:1.08. Tilt 0°. Both loose strand
tails trail UPWARD above the ball (air resistance pulls them up).
Stray fibers around the upper edge of the ball pushed UP. Two faint
vertical wind-streak fibers on either side (very soft). NO FACE, NO
LIMBS.
```

#### `body_fall_02.png` — устойчивое падение
```
ANIMATION FRAME — FALL 2/2 (stable terminal descent): Body
maintains stretch from frame 1 but slight wobble: aspect 0.93:1.10
(marginally more stretched). Strand tails trail UP, slightly waving
to one side (subtle motion). Wind-streaks on sides slightly longer
than frame 1. Stray fibers blown upward. NO FACE, NO LIMBS.
```

### 5.5 HURT — 2 кадра (импакт + recoil)

Событийная анимация при получении урона.

#### `body_hurt_01.png` — момент удара
```
ANIMATION FRAME — HURT 1/2 (impact moment): The ball is being
struck. Body horizontally squashed and asymmetric: aspect 1.4:0.8
(very wide, very short, with the right side flatter — struck from
the right). Eight loose yarn strands suddenly POPPED OUT from
random spots on the ball (3-4cm cream-white strands at angles, hand-
painted). Both original loose tails violently displaced (top tail
bent left, bottom-right tail twisted/kinked). Burst of stray fluff
fibers around the impacted side. Five small impact stars (4-point
sparkle marks, thin dark gray outline only). The yarn texture
visibly disheveled. NO FACE, NO LIMBS.
```

#### `body_hurt_02.png` — recoil (откат)
```
ANIMATION FRAME — HURT 2/2 (recoil bounce-back): Ball recovering
from impact, slightly less deformed: aspect 1.2:0.9. Asymmetry
reduced. The 8 popped strands still visible but slightly relaxed
(curled less aggressively). Impact stars are now smaller and fewer
(2-3 sparkles, fading). Tail strands recovering position. Yarn
texture still slightly disheveled. NO FACE, NO LIMBS.
```

После hurt анимации возвращается к idle.

### 5.6 DEAD — 5 кадров размотки (8 fps)

Прогрессия unraveling. Играется один раз при смерти.

#### `body_dead_01.png` — начало размотки
```
ANIMATION FRAME — DEAD 1/5 (start of unravel): Ball intact at full
size but the FIRST loose strands are beginning to come undone.
Aspect 1:1 (still spherical). Three or four extra strands have come
loose from the surface (in addition to the original two tails).
Some weave looks slightly looser. Tilt 5° to one side. NO FACE, NO
LIMBS.
```

#### `body_dead_02.png` — заметная размотка
```
ANIMATION FRAME — DEAD 2/5 (visible unraveling): Ball has shrunk
to ~85% original size. Eight to ten strands now visibly loose,
trailing toward the bottom-right. Weave gaps more visible. Tilt
15° to the side. NO FACE, NO LIMBS.
```

#### `body_dead_03.png` — половина клубка ушла в нити
```
ANIMATION FRAME — DEAD 3/5 (half undone): Ball at ~70% original
size. Twelve or so strands loose, forming early tangle in bottom-
right of frame. The remaining ball is noticeably less tightly
wound. Tilt 25° to side. One small detached yarn loop floating
nearby. NO FACE, NO LIMBS.
```

#### `body_dead_04.png` — ball только сердцевина
```
ANIMATION FRAME — DEAD 4/5 (mostly unraveled): Ball at ~55%
original size. Approximately 14 strands form a chaotic tangle of
loops and curls in the bottom-right. Remaining ball weave is loose,
showing inner structure. Tilt 35° to the side. Two small detached
yarn loops floating near the tangle. Couple of single strand fibers
floating. NO FACE, NO LIMBS.
```

#### `body_dead_05.png` — финальное состояние
```
ANIMATION FRAME — DEAD 5/5 (final defeated state): Ball at ~50%
original size, settled. Approximately 15 strands form a static
chaotic tangle in the bottom-right. A few detached loops settled
nearby. Soft contact shadow under the unraveled mess. The remaining
ball is loose and droopy, no longer holding its shape tightly.
Tilt 35° (matching frame 4, no further movement). NO FACE, NO
LIMBS.
```

После dead frame 5 — статика (труп остаётся до респавна).

---

## 6. FACE — спрайты-оверлеи

Лицо рендерится как **отдельный Sprite2D** поверх тела. Тело без лица —
оверлей всегда виден.

**Стилевой блок для всех лиц:**
```
STYLE: Minimalist hand-drawn cartoon face elements ONLY — eyes and
mouth, nothing else. Hand-painted slight irregularity (not perfect
digital strokes), as if drawn or stitched onto yarn surface. Solid
dark warm color (#2A2520 — very dark warm brown, almost black but
warmer). Tiny soft white highlight dots inside eye pupils for life
(except where noted).

LAYOUT: Features overlay a round face. Eyes upper-center area
(~38% from top edge), spaced ~38% of image width apart (eye centers
~24% image width from frame center). Mouth centered horizontally,
~20% below eye centerline.

NO HEAD SHAPE. NO BODY. NO OUTLINE around face area. NO ball, NO
yarn, NO silhouette. ONLY the eyes and mouth strokes.

BACKGROUND: Fully transparent. PNG 512x512 with alpha channel.
```

### 6.1 HAPPY — 2 кадра (моргание)

#### `face_happy_01.png` (главный референс — без image reference)
```
Subject: Two medium round dark-brown eyes, each with small white
highlight dot upper-left of pupil for sparkle. Eyes have very slight
hand-drawn irregularity (not perfect circles). Small upturned
crescent smile (curved arc, 3px hand-painted stroke) centered
between and below eyes. Friendly calm confident expression.
```

#### `face_happy_02.png` — моргание (eyes closed)
With `face_happy_01.png` as reference image:
```
ANIMATION FRAME — HAPPY 2/2 (blink): Same character. Change: eyes
are CLOSED into small downward arcs (curved 3px hand-painted
strokes, like sleepy/blinking eyes — gentle U-shapes pointing
upward). NO highlight dots since eyes closed. Mouth UNCHANGED —
same upturned crescent smile from frame 1.
```

В Godot: `face_happy_01` показывается ~3 секунды, `face_happy_02` — ~0.15с
(моргание), затем обратно. Цикл с randomization для природности.

### 6.2 FOCUS — 1 кадр (статика)

#### `face_focus_01.png`
With `face_happy_01.png` as reference:
```
Same hand-drawn style. Change: Eyes narrowed into determined
focused horizontal squints (lens/leaf shape, ~60% width of original
eye, ~40% height). Each squint solid dark brown with tiny
highlight. Mouth slightly downward-slanted straight horizontal line
(3px) — serious concentrated, not angry.
```

### 6.3 PAIN — 2 кадра (peak → fading)

#### `face_pain_01.png` — пик боли
With `face_happy_01.png` as reference:
```
ANIMATION FRAME — PAIN 1/2 (peak hurt): Eyes scrunched tightly
closed into hard >_< shapes (two small inverted V curves, 3px thick,
hand-drawn). NO highlight dots. Mouth a small downturned frowny
U-shape with tiny triangular gap inside showing "ow" expression.
```

#### `face_pain_02.png` — затухание (transitioning to neutral)
With `face_pain_01.png` as reference:
```
ANIMATION FRAME — PAIN 2/2 (fading hurt): Same character. Change:
Eyes still closed but the >_< shape is SOFTER (less aggressive
curve, more like ^_^ but down — gentler scrunch). Mouth still
downturned but smaller and less open (just a small curve, no inner
triangular gap). The expression is "wincing recovery", less
intense.
```

### 6.4 ANGRY — 2 кадра (snarl flash)

#### `face_angry_01.png` — пиковый snarl
With `face_happy_01.png` as reference:
```
ANIMATION FRAME — ANGRY 1/2 (peak snarl): Eyes angry narrowed slits
with sharp angled angry EYEBROWS above each (V-shape wedges, 3px,
tilted inward, hand-painted slight irregularity). Pupils visible
inside slits. NO highlight dots. Mouth a snarl showing 2-3 small
sharp pointed "teeth" (triangular shapes pointing down from upper
lip line) in upward-curving growl. Menacing but cute (not horror).
```

#### `face_angry_02.png` — релакс (fading)
With `face_angry_01.png` as reference:
```
ANIMATION FRAME — ANGRY 2/2 (relaxing): Same character. Change:
Eyebrows slightly less tilted (less angry, just stern). Eye slits
slightly more open (more like focus eyes, ~50% open). Mouth still
upturned but teeth are smaller / fewer (1-2 visible) and the snarl
is less aggressive. Transitioning back toward neutral.
```

### 6.5 SCARED — 2 кадра (дрожание, 6 fps цикл)

#### `face_scared_01.png` — wide eyes basic
With `face_happy_01.png` as reference:
```
ANIMATION FRAME — SCARED 1/2 (wide-eyed fear): Eyes WIDE OPEN
(larger than idle by ~20%) with TINY pupils as small dots in center
(fear-shrink). Three small motion-wobble arcs around OUTSIDE of
each eye (short 2px curves, 3 per eye, suggesting trembling).
Mouth a tiny worried "o" (small vertical oval). One small
teardrop/sweat shape next to LEFT eye (outside, below).
```

#### `face_scared_02.png` — тряска (eyes shifted)
With `face_scared_01.png` as reference:
```
ANIMATION FRAME — SCARED 2/2 (trembling shift): Same character.
Change: Pupils have shifted slightly to the LEFT inside the wide
eyes (looking at threat). Wobble arcs are slightly different
positions (suggesting a vibration frame). Sweat drop is slightly
lower (about to fall). Mouth slightly more open "o".
```

### 6.6 DEAD — 1 кадр (X-eyes static)

#### `face_dead_01.png`
With `face_happy_01.png` as reference:
```
Same hand-drawn style. Change: Eyes simple X-shapes from two
crossed diagonal lines each (3px hand-painted strokes, crossing at
center, ~40% size of normal eyes). NO highlight dots. Mouth
slightly open small vertical oval (short outlined oval, 3px stroke)
showing unconsciousness.
```

---

## 7. После генерации — обязательные шаги

### 7.1 Очистить фон до полной прозрачности
1. Открыть PNG в Photopea
2. Magic Wand (threshold 5-15) на углу, удалить
3. Для тела: **аккуратно** не удалить кремовые/серые пиксели клубка
4. Для лиц: можно жёстко — `Threshold` на 128, всё тёмное оставить

### 7.2 КРИТИЧНО — выровнять центры между всеми кадрами одной анимации
Все кадры одного действия (например, все 6 `body_run_*.png`) должны иметь
**одинаковый центр клубка**, иначе при проигрывании персонаж "прыгает":

1. Открыть все кадры действия как слои в Photopea
2. Включить полупрозрачность каждого слоя (50%)
3. Использовать **самый широкий/статичный кадр как baseline** (для run —
   frame 3 — apex airborne)
4. Подвинуть остальные кадры так, чтобы центры клубков совпадали с baseline
5. Сохранить каждый отдельно как 1024×1024 PNG с тем же центром

**Onion skin mode** в Photopea / Krita сильно облегчает эту задачу.

### 7.3 Проверка анимации в превью
Перед импортом в Godot — собрать GIF из кадров (например, в EZGif.com):
- Загрузить кадры по порядку
- Установить FPS из таблицы раздела 2
- Посмотреть анимацию

Если кадры "прыгают" — вернуться к 7.2.
Если движение неестественное — пере-генерить проблемный кадр.

### 7.4 Даунскейл до 256×256
- Photopea: `Image → Image Size → 256×256, Bicubic Sharper`
- Применить ко всем кадрам

### 7.5 Файлы в проект
```
assets/characters/body/
    body_idle_01.png ... body_idle_04.png
    body_run_01.png ... body_run_06.png
    body_jump_01.png ... body_jump_03.png
    body_fall_01.png ... body_fall_02.png
    body_hurt_01.png ... body_hurt_02.png
    body_dead_01.png ... body_dead_05.png

assets/characters/face/
    face_happy_01.png, face_happy_02.png
    face_focus_01.png
    face_pain_01.png, face_pain_02.png
    face_angry_01.png, face_angry_02.png
    face_scared_01.png, face_scared_02.png
    face_dead_01.png
```

---

## 8. Минимальный тест (8 кадров вместо 32)

Для быстрой проверки подхода:
- `body_idle_01.png`, `body_idle_02.png` (2 кадра дыхания)
- `body_run_01.png`, `body_run_03.png`, `body_run_05.png` (3 кадра — упрощённый бег)
- `body_hurt_01.png` (1 кадр)
- `face_happy_01.png` (без моргания)
- `face_pain_01.png` (без затухания)

Этого хватит для базовой проверки тинта, anim consistency и общего
ощущения. Остальные кадры — после положительной оценки.

---

## 9. Что Claude сделает после генерации

1. `feature/character-sprites` ветка
2. Заменит `_draw_ball` на:
   - `AnimatedSprite2D` "Body" с `SpriteFrames` ресурсом
   - `AnimatedSprite2D` "Face" (child of Body) с `SpriteFrames`
3. `body.modulate = player_color` — тинт цветом игрока
4. `face.modulate = Color.WHITE` — лицо не тинтуется
5. `SpriteFrames` ресурс с анимациями: `idle`, `run`, `jump`, `fall`, `hurt`, `dead`
6. State machine `_update_animation()`:
   ```
   if not is_alive: play("dead")
   elif hurt_flash_timer > 0: play("hurt")
   elif velocity.y < -50: play("jump")
   elif velocity.y > 50: play("fall")
   elif abs(velocity.x) > 20: play("run")
   else: play("idle")
   ```
7. Аналогично для emotions: `play("happy")`, `play("pain")`, `play("angry")`, и т.д.
8. FPS из таблицы раздела 2
9. Эмблемы способностей остаются процедурными в `_draw()` поверх
10. Smoke test в Godot + LOG + finish_branch

---

## 10. Если nanobanana не выдаёт нужное

### Кадр выходит другого размера/центрировки
Добавить в промт: `Output exactly 1024x1024 with the yarn ball
geometric center positioned at exactly (512, 512) pixel coordinates
in the image.`

### Между кадрами теряется консистентность стиля
Всегда прикреплять предыдущий или master frame как reference. Если
nanobanana всё равно дрейфует — генерить кадр с двумя референсами
одновременно (master + previous frame).

### Получается AI-cartoon вместо hand-painted yarn
Усиливать в промте: "hand-painted natural texture, NOT generic
vector cartoon. Show individual yarn fibers and weave structure.
NO smooth gradients, NO perfect shapes."

Negative prompt (если поддерживается): `vector art, flat cartoon,
smooth shading, perfect circle, mascot logo, generic AI art`

### Кадр получается с лицом или конечностями
Пере-генерить, добавив в самый конец промта:
"FINAL REMINDER: NO face features (no eyes, no mouth), NO arms, NO
legs. Only the yarn ball with strands."

---

## 11. Итого

| Категория | Файлы | Кадров | "С нуля" | "С reference" |
|-----------|-------|--------|----------|---------------|
| Body | 6 анимаций | 22 кадра | 1 (idle_01) | 21 |
| Face | 6 эмоций | 10 кадров | 1 (happy_01) | 9 |
| **Всего** | 12 анимаций | **32 кадра** | **2** | **30** |

Минимум для теста: **8 кадров** (см. раздел 8).
