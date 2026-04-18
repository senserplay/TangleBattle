# Конституция проекта TangleBattle

## 1. Общие принципы

- **Язык кода**: GDScript (Godot 4.x)
- **Язык комментариев в коде**: английский
- **Язык документации и заметок**: русский
- **Движок**: Godot 4.6.1 (2D)
- **Жанр**: Локальный мультиплеер PVP платформер, вид сбоку

## 2. Структура проекта

Полная структура описана в `docs/PROJECT_STRUCTURE.md`.

```
TangleBattle/
├── CLAUDE.md                 # Этот файл — конституция
├── project.godot             # Файл проекта Godot
├── data/                     # JSON-конфиги данных
│   ├── abilities.json        # Конфиги 17 способностей
│   └── passives.json         # Конфиги 23 пассивок
├── docs/                     # Документация
│   ├── PROJECT_STRUCTURE.md  # Полная структура проекта
│   ├── MVP.md                # MVP план
│   ├── REQUIREMENTS.md       # Требования
│   ├── GAME_DESIGN.md        # Геймдизайн
│   ├── DAMAGE_TYPES.md       # Типы урона
│   ├── abilities/            # Конфиги способностей (по файлу)
│   └── passives/             # Конфиги пассивок (по файлу)
├── work_notes/               # Рабочие заметки
│   └── LOG.md                # Лог работы (ОБЯЗАТЕЛЕН)
├── scenes/                   # Godot сцены (.tscn)
├── scripts/                  # GDScript файлы (.gd)
└── assets/                   # Ресурсы
```

## 3. ОБЯЗАТЕЛЬНЫЕ ПРАВИЛА РАБОЧИХ ЗАМЕТОК

### ЭТО САМОЕ ВАЖНОЕ ПРАВИЛО КОНСТИТУЦИИ

- **ПЕРЕД началом ЛЮБОЙ работы** — ОБЯЗАТЕЛЬНО прочитать `work_notes/LOG.md`
- **ПОСЛЕ завершения ЛЮБОГО блока работы** — ОБЯЗАТЕЛЬНО обновить `work_notes/LOG.md`
- Лог должен содержать: дату, что сделано, что изменено, что делать дальше
- **НИКОГДА** не пропускать обновление лога — это критически важно

## 4. ОБЯЗАТЕЛЬНЫЕ ПРАВИЛА ПРИ ИЗМЕНЕНИИ СПОСОБНОСТЕЙ/ПАССИВОК

### При ДОБАВЛЕНИИ способности:
1. Создать `docs/abilities/XX_name.md` с описанием, типами, конфигом
2. Добавить enum в `ability_registry.gd` + запись в `data/abilities.json`
3. Добавить match case в `player_abilities.gd` → `_use_ability()`
4. Написать функцию `_ab_name()` в `player_abilities.gd`
5. Добавить VFX анимацию
6. Добавить эмблему в `player.gd` и `lobby.gd`
7. Обновить `docs/abilities/README.md`
8. Обновить `work_notes/LOG.md`

### При ИЗМЕНЕНИИ способности:
1. Обновить `docs/abilities/XX_name.md`
2. Обновить значения в `data/abilities.json`
3. Обновить `work_notes/LOG.md`

### При УДАЛЕНИИ способности:
1. Удалить `docs/abilities/XX_name.md`
2. Удалить из enum в `ability_registry.gd`, из `data/abilities.json`, match case, функции, эмблемы
3. Обновить `docs/abilities/README.md`
4. Обновить `work_notes/LOG.md`

### При ДОБАВЛЕНИИ пассивки:
1. Создать `docs/passives/XX_name.md` с описанием и конфигом
2. Добавить enum в `passive_registry.gd` + запись в `data/passives.json`
3. Добавить match case в `player.gd` → `_apply_passives()`
4. Добавить иконку в `hud_draw.gd` и `game_overlay.gd`
5. Обновить `docs/passives/README.md`
6. Обновить `work_notes/LOG.md`

### При ИЗМЕНЕНИИ/УДАЛЕНИИ пассивки:
- Аналогично способностям — обновить все связанные файлы, `data/passives.json` и лог

## 5. Правила разработки

### 5.1 Код
- Следовать GDScript style guide от Godot
- Имена переменных и функций — snake_case
- Имена классов — PascalCase
- Максимальная длина строки: 100 символов
- Не создавать лишних абстракций
- Не добавлять фичи, которые не запрошены
- Явно типизировать переменные при получении из Dictionary (Godot Variant)

### 5.2 Сцены
- Одна сцена = одна ответственность
- Переиспользовать сцены через композицию
- UI через CanvasLayer + Control-ноды

### 5.3 Ввод (Input)
- InputManager (autoload) для маппинга
- Поддержка клавиатуры+мыши (P1) и до 3 геймпадов (P2-P4)
- Каждый игрок имеет свой префикс в Input Map (p1_, p2_, p3_, p4_)

### 5.4 Архитектура
- GameManager — синглтон: состояние, раунды, очки, настройки, режим игры (Classic/Endless/Chaos/Debug)
- AbilityRegistry — синглтон: конфиги 17 способностей (JSON: `data/abilities.json`)
- PassiveRegistry — синглтон: конфиги 23 пассивок с 5 редкостями (JSON: `data/passives.json`)
- SoundManager — синглтон: процедурные звуки
- InputManager — синглтон: маппинг устройств
- Сигналы Godot для коммуникации между нодами
- Физика через CharacterBody2D
- player.gd разбит на компоненты: player.gd + player_grapple.gd + player_abilities.gd

### 5.5 Тестирование
- После написания кода — тестировать через Godot MCP (`mcp__godot__run_project`)
- Запускать и основную сцену, и game.tscn напрямую
- Проверять вывод через `mcp__godot__get_debug_output`
- Скриншоты через F12 в игре (сохраняются в user://)

## 6. Приоритеты

1. Работающий геймплей > красивая графика
2. Простота > сложные системы
3. Играбельность > количество фич
4. Стабильность > новый функционал

## 7. Таблица обновления документов

| Когда | Что обновлять |
|-------|---------------|
| **Любое изменение** | `work_notes/LOG.md` |
| Новая способность | `docs/abilities/XX.md`, `abilities/README.md`, `ability_registry.gd`, `data/abilities.json`, `player_abilities.gd`, `lobby.gd`, `LOG.md` |
| Изменение способности | `docs/abilities/XX.md`, `data/abilities.json`, `LOG.md` |
| Удаление способности | Все файлы способности + `README.md` + `data/abilities.json` + `LOG.md` |
| Новая пассивка | `docs/passives/XX.md`, `passives/README.md`, `passive_registry.gd`, `data/passives.json`, `player.gd`, `hud_draw.gd`, `game_overlay.gd`, `LOG.md` |
| Изменение пассивки | `docs/passives/XX.md`, `data/passives.json`, `LOG.md` |
| Удаление пассивки | Все файлы пассивки + `README.md` + `data/passives.json` + `LOG.md` |
| Новая карта | `docs/PROJECT_STRUCTURE.md`, `LOG.md` |
| Новая фича | `LOG.md`, `PROJECT_STRUCTURE.md` |
| Баг-фикс | `LOG.md` |
| Изменение управления | `PROJECT_STRUCTURE.md`, `LOG.md` |
| Изменение баланса | Конфиг-файл + `LOG.md` |

## 8. Релизный процесс — ОБЯЗАТЕЛЬНО ДЛЯ КАЖДОЙ СЕССИИ

Полная спецификация: `docs/RELEASE_PROCESS.md`

### 8.1 Версионирование
- Формат: `MAJOR.MINOR` (без патча)
- Текущая версия: файл `VERSION` + `project.godot/application/config/version`
- Git-теги: `v0.1`, `v0.2`, ..., `v1.0`
- Релизы публикуются на **GitHub Releases** (Windows билд `.exe`)

### 8.2 Ветки — каждое изменение в новой ветке
```
feature/<name>   — новые фичи
fix/<name>       — багфиксы
chore/<name>     — рефакторинг, доки
hotfix/<name>    — критфиксы от тега
release/x.y      — подготовка релиза (создаётся make_release.ps1 автоматически)
```
Helper создания: `pwsh scripts/release/new_branch.ps1 <type> <name>`
Helper мержа в develop: `pwsh scripts/release/finish_branch.ps1`

**НИКОГДА** не коммитить напрямую в `develop` или `main`. Только через мердж feature-веток.

### 8.3 Workflow одного изменения
1. ОБЯЗАТЕЛЬНО прочитать `work_notes/LOG.md`
2. `pwsh scripts/release/new_branch.ps1 feature my-feature`
3. Реализация + тест через `mcp__godot__run_project`
4. ОБЯЗАТЕЛЬНО обновить `work_notes/LOG.md`
5. Коммит (с co-author Claude)
6. `pwsh scripts/release/finish_branch.ps1` — мерж в develop, push, авто-проверка релиза

### 8.4 Когда делать релиз — Claude сам решает
Запускать `pwsh scripts/release/check_release.ps1`:
- **В НАЧАЛЕ КАЖДОЙ СЕССИИ** (после прочтения LOG.md)
- **ПОСЛЕ ЗАВЕРШЕНИЯ КАЖДОГО БЛОКА РАБОТЫ**

Скрипт сообщит "release recommended" если:
- ≥ 5 записей в LOG.md с прошлого тега, ИЛИ
- ≥ 1 крупная запись (новая способность/пассивка/карта/режим), ИЛИ
- ≥ 14 дней с прошлого релиза при наличии изменений

При триггере: **сообщить пользователю** и запросить подтверждение перед запуском
`pwsh scripts/release/make_release.ps1`. Не делать релиз без явного "ок".

### 8.5 Запуск релиза
```
pwsh scripts/release/make_release.ps1               # minor bump
pwsh scripts/release/make_release.ps1 -BumpType major
pwsh scripts/release/make_release.ps1 -DryRun       # план без выполнения
```
Скрипт сам: создаст release/x.y → bump VERSION + project.godot → CHANGELOG →
smoke test → билд .exe → merge в main → tag → push → GitHub Release → merge
обратно в develop → запись в LOG.md.

### 8.6 Зависимости
- Godot: `C:\Users\belya\Downloads\Godot_v4.6.1-stable_mono_win64\` (config.ps1)
- gh CLI (опционально): `winget install GitHub.cli` для автозалива на GitHub
- PowerShell 5.1+ (есть на Win10/11)
