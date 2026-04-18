# Changelog — TangleBattle

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии следуют схеме `MAJOR.MINOR` (без патча).
Подробный рабочий лог: `work_notes/LOG.md`.

## [Unreleased]

### Added
_будущие изменения здесь_

---

## [0.1] — 2026-04-18

Первый baseline-тег. Весь контент, накопленный до внедрения релизного процесса.

### Added
- **17 способностей**: Yarn Toss, Needle Dash, Yarn Bomb, Thread Pull, Spin Attack,
  Grenade, Rocket Launcher, Stink Cloud, Spike Armor, Swap, Boomerang, Guided Rocket,
  Tripwire, Grab Throw, Black Hole, Portal Gate, Heaven's Wrath
- **25 пассивок** с 5 редкостями (Common/Uncommon/Rare/Legendary/Mythic), в т.ч.
  Phase Shot (#24), Parry Burst (#23), Shield Mastery (#22), Spirit Burst (#21),
  Lucky Star (#20), Burst Fire (#19), Homing Projectiles (#18), Heavy Impact (#17),
  Lightning Strike (#16), Shockwave (#15)
- **16 карт**: Workshop, Sky Garden, Dungeon, Volcano, Ice Cave, Tower, Jungle,
  Space, Cloud Kingdom, Mirror, Factory, Arena, Clockwork, Inferno, Fortress,
  Trampoline
- **4 игровых режима**: Classic (до 7 побед), Endless, Chaos, Debug
- **Локальный мультиплеер** до 4 игроков (клавиатура+мышь + 3 геймпада)
- **Динамическая музыка** с реакцией на количество живых игроков
- **VFX-система** с PNG-анимацией (craftpix slash/effects)
- **Механика пикапов** с гравитацией и дропом способности при смерти
- **Настройки лобби**: luck, количество карт пассивок, пиков за раунд

### Changed
- Процедурная отрисовка платформ заменена на текстуры с закруглённой капсулой-полигоном
  (5 палитр: grass, stone, wood, ice, magma) — значительно меньше draw-calls
- Spirit Burst: проходит через `take_damage()` (учитывает Phoenix/parry/invincibility),
  ограничение 15 одновременных эссенций на игрока
- Swap: убран лишний invuln (был `+0.5s`, теперь строго `swap_invuln` из конфига)
- Phoenix: очистка всех отрицательных эффектов при воскрешении
- Hold-parry: щит автоповторяется при удержании кнопки

### Fixed
- Множество багов баланса способностей и пассивок
- Эффекты огня/яда корректно очищаются при респавне

### Infrastructure
- Git LFS для бинарных ассетов (PNG, WAV, EXE)
- Git-репозиторий на `git@github.com:senserplay/TangleBattle.git`
- Ветки `main` / `develop`

---

[Unreleased]: https://github.com/senserplay/TangleBattle/compare/v0.1...HEAD
[0.1]: https://github.com/senserplay/TangleBattle/releases/tag/v0.1
