# Swift Feet — Быстрые ноги

## Описание
Увеличивает скорость передвижения и скорость полёта (grapple swing, air control).

## Редкости
| Редкость | Скорость | Скорость полёта | Штраф |
|----------|---------|----------------|-------|
| Common | +20% скорость | +15% нить | -15% HP |
| Uncommon | +30% скорость | +25% нить | -8% HP |
| Rare | +40% скорость | +35% нить | — |
| Legendary | +50% скорость | +50% нить | +10% урон |

```toml
[config]
id = 11
name = "Swift Feet"
description = "Увеличение скорости"
icon = "swift"

[rarities.common]
positive = "+20% скорость, +15% нить"
negative = "-15% HP"
speed_multiplier = 1.2
grapple_speed_mult = 1.15
hp_multiplier = 0.85

[rarities.uncommon]
positive = "+30% скорость, +25% нить"
negative = "-8% HP"
speed_multiplier = 1.3
grapple_speed_mult = 1.25
hp_multiplier = 0.92

[rarities.rare]
positive = "+40% скорость, +35% нить"
negative = ""
speed_multiplier = 1.4
grapple_speed_mult = 1.35

[rarities.legendary]
positive = "+50% скорость, +50% нить, +10% урон"
negative = ""
speed_multiplier = 1.5
grapple_speed_mult = 1.5
damage_multiplier = 1.1
```
