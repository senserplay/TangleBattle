# Релизный процесс TangleBattle

Этот документ описывает как Claude (и человек, при необходимости) должен
выпускать новые версии игры. Релизами управляет Claude автономно.

---

## 1. Версионирование

- **Формат**: `MAJOR.MINOR` (без патча)
- **Текущая версия** хранится в файле `VERSION` (одна строка) и в
  `project.godot` → `application/config/version`
- **Git-теги** имеют префикс `v`: `v0.1`, `v0.2`, `v1.0`
- **MAJOR** растёт при крупных вехах (новый режим, переработка систем,
  выход в "стабильную" версию)
- **MINOR** растёт при каждом релизе с накопленными улучшениями
- Целевая `1.0` = полный набор фич из MVP.md, отполированный баланс

---

## 2. Ветки

| Ветка | Назначение |
|-------|------------|
| `main` | Стабильная, только мерж релизов, тегается |
| `develop` | Интеграция всех изменений |
| `feature/<name>` | Новая фича от `develop` → в `develop` |
| `fix/<name>` | Багфикс от `develop` → в `develop` |
| `chore/<name>` | Рефакторинг, доки, зависимости |
| `release/x.y` | Подготовка релиза, freeze фичей |
| `hotfix/<name>` | Критфикс от тега → minor bump |

**Именование**: kebab-case, кратко. Примеры:
`feature/phase-shot`, `fix/spirit-no-damage`, `chore/update-claude-md`.

---

## 3. Workflow одного изменения

```
1. ЧИТАТЬ work_notes/LOG.md (правило конституции)
2. git checkout develop && git pull
3. git checkout -b <type>/<name>
4. Реализация + тест через mcp__godot__run_project
5. ОБНОВИТЬ work_notes/LOG.md
6. git commit (с co-author Claude)
7. git checkout develop && git merge --no-ff <type>/<name>
8. git branch -d <type>/<name>
9. git push origin develop
```

Helper: `pwsh scripts/release/new_branch.ps1 feature phase-shot`

---

## 4. Когда делать релиз

Релиз триггерится при выполнении **любого** из:

| Условие | Тип |
|---------|-----|
| ≥ 5 записей в LOG.md с прошлого тега | regular minor |
| ≥ 1 "крупная" запись (новая способность/пассивка/карта/режим/система) | regular minor |
| ≥ 14 дней с прошлого релиза при наличии любых изменений | regular minor |
| Явный запрос пользователя | по запросу |
| Критфикс (краш, ломающий баг) | hotfix minor |

Проверка автоматизирована: `pwsh scripts/release/check_release.ps1`

Claude **обязательно** запускает `check_release.ps1`:
- В начале каждой сессии (см. CLAUDE.md раздел "Релизный процесс")
- После завершения любого блока работы (когда обновлён LOG.md)

Если скрипт сообщает "release recommended" — Claude уведомляет
пользователя и спрашивает подтверждение перед запуском релиза.

---

## 5. Процесс релиза (полная автоматизация)

Команда: `pwsh scripts/release/make_release.ps1 -BumpType minor`

Шаги, которые делает скрипт:

1. **Проверки**: текущая ветка `develop`, нет несохранённых изменений
2. **Bump версии**: `VERSION` и `project.godot/application/config/version`
3. **Создание `release/x.y`** от `develop`
4. **Генерация CHANGELOG**: новый раздел из LOG.md записей с прошлого тега
5. **Smoke test** (опционально, ключ `-SkipSmokeTest` для пропуска):
   запуск `godot --headless --quit-after 100` для проверки парсинга
6. **Билд**: `godot --headless --export-release "Windows Desktop"
   builds/TangleBattle-vX.Y.exe`
7. **Commit + merge** в `main`, **тег** `vX.Y`
8. **Push** `main`, `develop`, тегов
9. **GitHub Release** через `gh release create vX.Y` с прикреплённым `.exe`
   (если `gh` не установлен — печатается ручная инструкция)
10. **Merge `release/x.y` обратно в `develop`** (чтобы dev оставался впереди)
11. **Удаление `release/x.y`**
12. **Запись в LOG.md**: "RELEASE vX.Y"

---

## 6. Hotfix процесс

Если после релиза найден критбаг:

```
git checkout vX.Y
git checkout -b hotfix/<name>
# фикс + тест
pwsh scripts/release/make_release.ps1 -BumpType minor -FromHotfix
```

В `make_release.ps1` ветка `hotfix/*` обрабатывается особо: мерж в
`main` И в `develop`, тег `vX.(Y+1)`.

---

## 7. GitHub Release notes

Берутся из соответствующего раздела `CHANGELOG.md` (между `## [vX.Y]` и
следующим `## [`). Перед публикацией копируются в `release_notes_vX.Y.md`
(в .gitignore) для передачи в `gh release create --notes-file`.

---

## 8. Билды

- **Платформа**: только Windows Desktop (по запросу пользователя)
- **Расположение**: `builds/TangleBattle-vX.Y.exe` (в .gitignore)
- **Хранение**: GitHub Releases — НЕ в Git, НЕ в LFS
- **Export preset**: `export_presets.cfg`, имя preset = `Windows Desktop`

---

## 9. Что Claude обязан помнить

См. также: `CLAUDE.md` раздел 8 ("Релизный процесс").

1. Всё новое — в новой ветке от `develop`
2. После каждого блока работы — `check_release.ps1`
3. При триггере релиза — спросить пользователя, не делать без подтверждения
4. Проверять что `gh` установлен; если нет — выдать инструкцию
5. Никогда не пушить force в `main`
6. Никогда не делать commit без обновления LOG.md в той же фиче

---

## 10. Зависимости

- **Godot 4.6.1 mono** в `C:\Users\belya\Downloads\Godot_v4.6.1-stable_mono_win64\`
  Путь конфигурируется в `scripts/release/config.ps1`
- **gh CLI** (опционально, для автозалива на GitHub Releases):
  `winget install GitHub.cli`
- **PowerShell 5.1+** (есть на любой Win10/11)
- **Git LFS** (уже настроен)

---

## 11. Откат релиза

Если релиз сломан и нужно откатить:

```powershell
git tag -d vX.Y
git push origin :refs/tags/vX.Y
gh release delete vX.Y --yes
git revert <merge-commit>
```

После — выпустить `vX.(Y+1)` с фиксом.
