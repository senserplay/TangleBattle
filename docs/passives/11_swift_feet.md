# Swift Feet — Быстрые ноги

## Описание
Увеличивает скорость передвижения игрока.
Нить (grapple) больше не зависит от этой пассивки — её скорость
автоматически масштабируется от дальности (см. Thread Master).

## Редкости
| Редкость | Скорость | Штраф |
|----------|---------|-------|
| Common | +20% | -15% HP |
| Uncommon | +30% | -8% HP |
| Rare | +40% | — |
| Legendary | +50%, +10% урон | — |

```toml
[config]
id = 11
name = "Swift Feet"
description = "Увеличение скорости движения"
icon = "swift"

[rarities.common]
positive = "+20% скорость"
negative = "-15% HP"
speed_multiplier = 1.2
hp_multiplier = 0.85

[rarities.uncommon]
positive = "+30% скорость"
negative = "-8% HP"
speed_multiplier = 1.3
hp_multiplier = 0.92

[rarities.rare]
positive = "+40% скорость"
negative = ""
speed_multiplier = 1.4

[rarities.legendary]
positive = "+50% скорость, +10% урон"
negative = ""
speed_multiplier = 1.5
damage_multiplier = 1.1
```
