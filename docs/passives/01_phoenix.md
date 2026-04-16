# Phoenix — Феникс

## Описание
После смерти вы единожды возрождаетесь на месте с `respawn_hp_pct` от максимального здоровья.
Максимальное HP уменьшается на `hp_penalty` от базового.

## Редкости

| Редкость | Жизни | Штраф HP | HP при возрождении |
|----------|-------|----------|-------------------|
| Rare | +1 жизнь | -60% макс HP | 50% от нового макс |
| Legendary | +1 жизнь | -20% макс HP | 100% от нового макс |

```toml
[config]
id = 1
name = "Phoenix"
description = "Возрождение после смерти"

[rarities.rare]
extra_lives = 1
hp_penalty = 0.6
respawn_hp_pct = 0.5

[rarities.legendary]
extra_lives = 1
hp_penalty = 0.2
respawn_hp_pct = 1.0
```
