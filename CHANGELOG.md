# Changelog — TangleBattle

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версии следуют схеме `MAJOR.MINOR` (без патча).
Подробный рабочий лог: `work_notes/LOG.md`.

## [Unreleased]

### Added
_будущие изменения здесь_

---

## [0.7] � 2026-04-21

### Changed
- Merge tweak/stink-cloud-transparency into develop - tweak(vfx): add transparency + fade-in/out to stink cloud - Merge feature/stink-cloud-red-3phase into develop - feat(vfx): stink_cloud ��� red-BG extract + 3-phase grow/hold/shrink - Merge fix/portal-marker-follows-player into develop - fix(vfx): portal marker stayed glued to the player after placement - Merge feature/portal-gate-opening-anim into develop - feat(vfx): portal gate opening animation + purple particle emission - Merge tweak/black-hole-transparency into develop - tweak(vfx): make the black hole semi-transparent with fade-in/out - Merge fix/black-hole-6-edge-crop into develop - fix(vfx): let black_hole_6 extend to the source right edge - Merge fix/black-hole-peak-detection into develop - fix(vfx): black_hole extraction ��� peak-detect true vortex centers - Merge feature/black-hole-7frame-anim into develop - feat(vfx): 7-frame black hole ��� grow ��� hold ��� shrink 3-phase animation - Merge feature/grapple-rope-texture into develop - feat(vfx): textured grapple rope ��� chroma-keyed PNG stretched along direction - Merge fix/yarn-toss-chromakey into develop - fix(vfx): chroma-key + desaturate yarn_toss for clean player-color tint - Merge fix/heavens-wrath-chromakey into develop - fix(vfx): clean chroma-key heavens_wrath beam with hard despill - Merge feature/grenade-chromakey-spin into develop - feat(vfx): chroma-key grenade + velocity-based spin - Merge tweak/boomerang-grayscale-tint into develop - tweak(vfx): desaturate boomerang to grayscale so player-color tint reads - Merge fix/boomerang-chromakey into develop - fix(vfx): clean chroma-key boomerang from the green reference PNG - Merge fix/per-frame-vfx-center into develop - fix(vfx): per-frame PNG with centered content + world-anchored teleport VFX - Merge fix/projectile-sprites-get-name into develop - fix(vfx): rename projectile_sprites._get ��� _get_tex (Object._get conflict) - Merge feature/texture-projectiles into develop - feat(vfx): texture-based projectiles & ability effects - Merge tweak/ability-icons-bigger into develop - tweak(ui): bigger ability icons above the player head - Merge feature/event-vfx into develop - feat(events): visible meteor/lightning/wind VFX + editor canvas clipping - Merge feature/editor-events-polish into develop - feat(editor): events dropdown + banners, slippery water, default one-way - Merge fix/editor-collisions-import into develop - fix(editor): custom-map collisions, import built-in maps, clarify events - Merge feature/map-editor into develop - feat(editor): in-game map editor with Test Play + custom_map runtime loader - Merge release/0.6 into develop

---

## [0.6] � 2026-04-20

### Changed
- Merge feature/maps-rebuild-parallax into develop - chore: reimport refresh + new map .uid files - fix(characters): death VFX + dropped pickup now spawn at actual death spot - fix(assets): trim 56px alpha=0 padding from platform textures - fix(maps): single UV-wrap polygon + solid base fill, drop split-polygon - fix(maps): split-polygon platform tiles, drop broken shader, bg cap 4x - fix(maps): wrap-aware 4-tap bilinear shader kills the platform tile seam - fix(maps): shader-based fract() UV wrap for truly seamless platform tiling - fix(maps): aspect-preserve bg scale cap, transform+tile platforms, wavy water, drop winter_valley - fix(maps): seamless platform tiling, stretch bg layers, plain water floor - fix(maps): auto-scale bg layers + tile platform textures without stretch - feat(maps): full rebuild ��� parallax backgrounds + unified water/vignette borders - Merge feature/ability-icons-textured into develop - feat(ui): textured ability icons replace procedural emblems + docs actualization - Merge release/0.5 into develop

---

## [0.5] � 2026-04-19

### Changed
- Merge feature/gameplay-fixes-physics into develop - feat+fix(gameplay): grapple/teleport/death cleanup; dash momentum; zero-G; ice - Revert "Merge fix/bg-no-parallax-seam into develop" - Merge fix/bg-no-parallax-seam into develop - fix(maps): lock bg to world coords ��� no parallax ��� no split-screen seam - Merge fix/remove-floor-strip into develop - fix(maps): remove floor_strip ��� palette textures already are landscape strips - Merge fix/strip-alpha into develop - fix(maps): strip textures had no alpha ��� black bg rendered as opaque band - Merge fix/map-visuals-polish into develop - chore: add strip texture .import files (godot-generated) - fix(maps): strip-overlay shows top-only deco; ancient_ruins blocks; space lag - Merge feature/map-rewrite-8 into develop - feat(maps): full pool rewrite ��� 18 ��� 8 unique themed maps - Merge release/0.4 into develop

---

## [0.4] � 2026-04-19

### Changed
- Merge fix/vfx-export into develop - fix(effects): ability VFX missing in exported build (DirAccess���ResourceLoader) - Merge release/0.3 into develop

---

## [0.3] � 2026-04-19

### Changed
- Merge feature/map-backgrounds into develop - feat(maps): textured parallax backgrounds + themed death zones on all 16 maps + 2 new maps - Merge feature/character-icon-everywhere into develop - chore: add YarnBallIcon .uid (godot-generated) - feat(ui): use yarn-ball texture asset for character icons everywhere - Merge fix/character-new-ball-emotions into develop - feat(characters): new clean ball + larger face + event-driven emotions - Merge fix/character-sprites-bugs into develop - fix(characters): body z-index + face white interiors - chore: add character .import files (autogenerated) - Merge feature/character-sprites into develop - feat(characters): sprite-based yarn ball + face overlay with transform animation - Merge fix/character-prompts-multiframe-anim into develop - fix(characters): multi-frame animation prompts (32 frames total) - Merge fix/character-prompts-realistic-yarn into develop - fix(characters): rewrite prompts ��� real yarn ball, not AI-cartoon - Merge fix/character-prompts-no-limbs into develop - fix(characters): rewrite prompts ��� character is a pure ball, no limbs - Merge chore/character-prompts into develop - docs(characters): add nanobanana 2 generation prompts for yarn-ball character - Merge fix/platform-textures-render into develop - fix(platforms): remove residual black bg + stretch-to-fit UVs - Merge feature/lofi-music-system into develop - feat(music): lo-fi playlist with smooth crossfade, map-independent - Merge chore/last-tag-by-version into develop - chore(release): Get-LastReleaseTag uses version sort, not ancestry - Merge fix/make-release-crlf-guard into develop - fix(release): discard transient .import changes before checkout main - docs: v0.2 release notes and LOG entry - Merge release/0.2 into develop

---

## [0.2] — 2026-04-18

Первый релиз через новый автоматизированный процесс. Включает весь контент v0.1
плюс инфраструктуру релизов.

### Added
- **Релизный процесс**: версионирование MAJOR.MINOR, ветки feature/fix/chore/hotfix,
  автоматизация через PowerShell-скрипты в `scripts/release/`
- `scripts/release/check_release.ps1` — проверка триггеров релиза
- `scripts/release/build.ps1` — экспорт Windows .exe через Godot CLI
- `scripts/release/make_release.ps1` — полный релизный pipeline
- `scripts/release/new_branch.ps1` / `finish_branch.ps1` — управление ветками
- `docs/RELEASE_PROCESS.md` — полная спецификация процесса
- `CHANGELOG.md` (этот файл) — история релизов
- `VERSION` — файл версии

### Changed
- `CLAUDE.md` раздел 8: обязательные правила релизного процесса для Claude
- `export_presets.cfg`: Windows Desktop preset с product_version синхронизируется
  при bump-ах; исключены `my_assets/`, `builds/`, `work_notes/`, `docs/`
- `project.godot`: добавлен `application/config/version`
- `.gitignore`: добавлены `my_assets/` (447MB source assets), `builds/`,
  `release_notes_v*.md`

### Infrastructure
- GitHub Releases для хранения Windows билдов (.exe ~102 MB)
- Автопроверка критериев релиза при старте сессии Claude и после каждого блока работы

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


[0.2]: https://github.com/senserplay/TangleBattle/releases/tag/v0.2

[0.3]: https://github.com/senserplay/TangleBattle/releases/tag/v0.3

[0.4]: https://github.com/senserplay/TangleBattle/releases/tag/v0.4

[0.5]: https://github.com/senserplay/TangleBattle/releases/tag/v0.5

[0.6]: https://github.com/senserplay/TangleBattle/releases/tag/v0.6

[0.7]: https://github.com/senserplay/TangleBattle/releases/tag/v0.7