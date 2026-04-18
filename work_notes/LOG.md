# TangleBattle — Рабочий лог

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
