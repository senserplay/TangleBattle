# Explosive Power — Взрывная сила

## Описание
Увеличивает радиус и урон всех взрывных способностей (тип `explosion`).

## Редкости
| Редкость | Радиус взрывов | Урон взрывов | Штраф |
|----------|---------------|-------------|-------|
| Common | +20% радиус | +15% урон | -10% скорость |
| Uncommon | +30% радиус | +25% урон | -5% скорость |
| Rare | +40% радиус | +35% урон | — |
| Legendary | +60% радиус | +50% урон | +10% скорость |

```toml
[config]
id = 10
name = "Explosive Power"
description = "Усиление взрывов"
icon = "explosive"

[rarities.common]
positive = "+20% радиус, +15% урон взрывов"
negative = "-10% скорость"
radius_multiplier = 1.2
damage_multiplier = 1.15
speed_multiplier = 0.9

[rarities.uncommon]
positive = "+30% радиус, +25% урон"
negative = "-5% скорость"
radius_multiplier = 1.3
damage_multiplier = 1.25
speed_multiplier = 0.95

[rarities.rare]
positive = "+40% радиус, +35% урон"
negative = ""
radius_multiplier = 1.4
damage_multiplier = 1.35

[rarities.legendary]
positive = "+60% радиус, +50% урон, +10% скорость"
negative = ""
radius_multiplier = 1.6
damage_multiplier = 1.5
speed_multiplier = 1.1
```
