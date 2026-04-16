# Структура проекта TangleBattle

## Обзор
Локальный мультиплеер PVP 2D платформер на Godot 4.6.1.
До 4 игроков (клавиатура + мышь + до 3 геймпадов).
Персонажи — клубки ниток. 17 способностей, 23 пассивки, 16 карт, grapple hook.

## Поток игры
```
Title Menu ──► Lobby (подключение, выбор способностей, настройки)
    │
    ▼
  Game ──► Round loop:
    │         Бой → Смерти → Очко победителю
    │         → Проигравшие выбирают пассивки
    │         → Новая случайная карта → Респавн
    │         → Победа при N очков
    │
    ▼
  Title Menu
```

## Автозагрузки (Singletons)
| Порядок | Имя | Файл | Назначение |
|---------|-----|------|------------|
| 1 | InputManager | managers/input_manager.gd | Маппинг устройств ввода |
| 2 | AbilityRegistry | managers/ability_registry.gd | Конфиги 17 способностей (из data/abilities.json) |
| 3 | GameManager | managers/game_manager.gd | Состояние, раунды, очки, режим игры (Classic/Endless/Chaos/Debug) |
| 4 | SoundManager | managers/sound_manager.gd | Процедурные звуки |
| 5 | PassiveRegistry | managers/passive_registry.gd | Конфиги 23 пассивок с 5 редкостями (из data/passives.json) |

## Дерево файлов
```
TangleBattle/
├── CLAUDE.md
├── project.godot
│
├── data/
│   ├── abilities.json            # Конфиги 17 способностей
│   └── passives.json             # Конфиги 23 пассивок
│
├── docs/
│   ├── PROJECT_STRUCTURE.md      # Этот файл
│   ├── MVP.md
│   ├── REQUIREMENTS.md
│   ├── GAME_DESIGN.md
│   ├── DAMAGE_TYPES.md           # 8 типов урона
│   ├── abilities/                # 17 способностей
│   │   ├── README.md
│   │   ├── 00_yarn_toss.md ... 16_heavens_wrath.md
│   └── passives/                 # 23 пассивки
│       ├── README.md
│       ├── 00_poison_projectile.md ... 22_shield_mastery.md
│
├── work_notes/
│   └── LOG.md                    # Рабочий лог
│
├── scripts/
│   ├── managers/
│   │   ├── ability_registry.gd   # Реестр 14 способностей (загружает data/abilities.json)
│   │   ├── game_manager.gd       # Состояние игры, раунды, F12 скриншот
│   │   ├── input_manager.gd      # Маппинг клавиатура+мышь / геймпады
│   │   ├── passive_registry.gd   # Реестр 15 пассивок (загружает data/passives.json)
│   │   └── sound_manager.gd      # Процедурный синтез звуков
│   │
│   ├── characters/
│   │   ├── player.gd             # Игрок: физика, пассивки, VFX, смерть (роняет пикапы)
│   │   ├── player_grapple.gd     # Компонент: логика grapple hook
│   │   ├── player_abilities.gd   # Компонент: 17 способностей
│   │   ├── yarn_projectile.gd    # Снаряд Yarn Toss (с трейлом)
│   │   ├── grenade.gd            # Граната (зарядка, отскоки, взрыв)
│   │   ├── rocket.gd             # Ракета (с огненным трейлом)
│   │   ├── tangle_trap.gd        # Ловушка (урон + замедление)
│   │   ├── stink_cloud.gd        # Ядовитое облако (DoT)
│   │   ├── black_hole.gd         # Чёрная дыра (притягивает всех игроков, DoT)
│   │   ├── heavens_wrath.gd      # Небесная кара (столбы урона сверху)
│   │   ├── soul_essence.gd       # Эссенция (Spirit Burst — наводящийся снаряд)
│   │   ├── death_effect.gd       # Анимация смерти (нити разлетаются)
│   │   └── ability_pickup.gd     # Пикап: гравитация, спавн на платформах, смена каждые 10с
│   │
│   ├── maps/
│   │   ├── map_base.gd           # Базовый класс: платформы, danger zones, стены, порталы
│   │   ├── workshop.gd           # Мастерская (4800×3200, закрытая)
│   │   ├── sky_garden.gd         # Небесный сад (5200×3600, открытый верх)
│   │   ├── volcano.gd            # Вулкан (4400×3400, открытый верх, лава)
│   │   ├── ice_cave.gd           # Ледяная пещера (4600×3000, закрытая)
│   │   ├── tower.gd              # Башня (3600×4800, вертикальная, открытый верх)
│   │   ├── factory.gd            # Фабрика
│   │   ├── jungle.gd             # Джунгли
│   │   ├── space.gd              # Космос
│   │   ├── dungeon.gd            # Подземелье
│   │   ├── cloud_kingdom.gd      # Царство облаков
│   │   ├── clockwork.gd          # Механизм
│   │   ├── arena.gd              # Арена
│   │   ├── mirror.gd             # Зеркало
│   │   ├── fortress.gd           # Крепость
│   │   ├── inferno.gd            # Инферно
│   │   └── trampoline.gd         # Батутная (всего 16 карт)
│   │
│   ├── main/
│   │   ├── game.gd               # Игровая сцена: раунды, пикапы, пауза, пассивки
│   │   ├── game_camera.gd        # Динамическая камера (зум по игрокам)
│   │   └── game_overlay.gd       # Overlay: пауза + выбор пассивок (CanvasLayer)
│   │
│   └── ui/
│       ├── title_menu.gd         # Главное меню + настройки (видео/аудио)
│       ├── lobby.gd              # Лобби: подключение, способности, HP/раунды
│       ├── hud.gd                # HUD: логика hover пассивок
│       ├── hud_draw.gd           # HUD: отрисовка точек очков, пассивок, тултипы
│       └── main_menu.gd          # (legacy, не используется)
│
├── scenes/
│   ├── characters/               # player, projectiles, effects, pickup
│   ├── maps/                     # 14 карт
│   ├── main/                     # title_menu, lobby, game
│   └── ui/                       # hud
│
└── assets/ (пока пусто)
```

## Карты (16 штук)
| Карта | Файл | Размер | Открытый верх | Особенность |
|-------|------|--------|---------------|-------------|
| Workshop | workshop.gd | 4800×3200 | Нет | Тёплая, закрытая |
| Sky Garden | sky_garden.gd | 5200×3600 | Да | Нет пола, облака |
| Volcano | volcano.gd | 4400×3400 | Да | Лава, узкие платформы |
| Ice Cave | ice_cave.gd | 4600×3000 | Нет | Ледяная, симметричная |
| Tower | tower.gd | 3600×4800 | Да | Вертикальная, зигзаг |
| Factory | factory.gd | — | — | — |
| Jungle | jungle.gd | — | — | — |
| Space | space.gd | — | — | — |
| Dungeon | dungeon.gd | — | — | — |
| Cloud Kingdom | cloud_kingdom.gd | — | — | — |
| Clockwork | clockwork.gd | — | — | — |
| Arena | arena.gd | — | — | — |
| Mirror | mirror.gd | — | — | — |
| Fortress | fortress.gd | — | — | — |
| Inferno | inferno.gd | — | — | Огненные стены |
| Trampoline | trampoline.gd | — | — | Упругие стены/блоки |

Платформы: capsule (скруглённый прямоугольник), ball (круг), arc (дуга).
Новые механики карт: стены, огненные стены (fire walls), упругие стены (bouncy walls), липкие блоки (sticky blocks), порталы v2.

## Collision Layers
| Layer | Что |
|-------|-----|
| 1 | Платформы (StaticBody2D) |
| 2 | Игроки |
| 3 | Игроки + платформы (player collision_layer) |
| 4 | Снаряды |
| 8 | Пикапы способностей |

## Управление
| Действие | Клавиатура (P1) | Геймпад (P2-P4) |
|----------|-----------------|------------------|
| Движение | A/D | Левый стик / D-Pad |
| Прыжок (зажать = grapple) | Space | L1/R1 |
| Способность 1 | ЛКМ | L2 |
| Способность 2 | ПКМ | R2 |
| Прицел | Мышь | Правый стик |
| Пауза | ESC | B |
| Скриншот | F12 | — |
