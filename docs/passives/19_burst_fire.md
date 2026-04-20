# Burst Fire — Залповая стрельба

## Описание
При использовании `projectile`-способности запускает дополнительные снаряды
(всего 1 + `burst_count`). Доп. снаряды летят с небольшим разбросом по углу
для веера.

## Редкости
| Редкость | Доп. снаряды | Эффект на КД |
|----------|--------------|--------------|
| Rare | +1 | +20% КД |
| Legendary | +2 | +10% КД |
| Mythic | +3 | -10% КД |

```toml
[config]
id = 19
name = "Burst Fire"
description = "Залповая стрельба"
icon = "burst"
affects_types = ["projectile"]
available_rarities = [2, 3, 4]

[rarities.rare]
positive = "+1 доп. выстрел"
negative = "+20% кд"
burst_count = 1
cd_multiplier = 1.2

[rarities.legendary]
burst_count = 2
cd_multiplier = 1.1

[rarities.mythic]
burst_count = 3
cd_multiplier = 0.9
```
