# Heavy Impact — Тяжёлый удар

## Описание
Усиливает физическое отталкивание при **столкновении** игрока с врагом
(тело-в-тело). Не влияет на урон, только на knockback.

## Редкости
| Редкость | Сила столкновений | Доп. эффект | Штраф |
|----------|-------------------|-------------|-------|
| Common | +50% | — | -15% скорость |
| Uncommon | +80% | — | -8% скорость |
| Rare | +120% | — | — |
| Legendary | +200% | +20% HP | — |

```toml
[config]
id = 17
name = "Heavy Impact"
description = "Сильнее отталкивание при столкновении"
icon = "heavy"
available_rarities = [0, 1, 2, 3]

[rarities.common]
positive = "+50% сила столкновений"
negative = "-15% скорость"
collision_mult = 1.5
speed_multiplier = 0.85

[rarities.uncommon]
collision_mult = 1.8
speed_multiplier = 0.92

[rarities.rare]
collision_mult = 2.2

[rarities.legendary]
collision_mult = 3.0
hp_multiplier = 1.2
```
