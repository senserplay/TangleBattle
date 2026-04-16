# Projectile Master — Мастер снарядов

## Описание
Увеличивает урон и скорость всех снарядов (тип `projectile`).

## Редкости
| Редкость | Урон снарядов | Скорость снарядов | Штраф |
|----------|-------------|-----------------|-------|
| Common | +20% урон | +15% скорость | +15% кд |
| Uncommon | +30% урон | +25% скорость | +8% кд |
| Rare | +40% урон | +30% скорость | — |
| Legendary | +50% урон | +40% скорость | -10% кд |

```toml
[config]
id = 12
name = "Projectile Master"
description = "Усиление снарядов"
icon = "proj_master"

[rarities.common]
positive = "+20% урон, +15% скорость снарядов"
negative = "+15% кд"
damage_multiplier = 1.2
projectile_speed_mult = 1.15
cd_multiplier = 1.15

[rarities.uncommon]
positive = "+30% урон, +25% скорость снарядов"
negative = "+8% кд"
damage_multiplier = 1.3
projectile_speed_mult = 1.25
cd_multiplier = 1.08

[rarities.rare]
positive = "+40% урон, +30% скорость"
negative = ""
damage_multiplier = 1.4
projectile_speed_mult = 1.3

[rarities.legendary]
positive = "+50% урон, +40% скорость, -10% кд"
negative = ""
damage_multiplier = 1.5
projectile_speed_mult = 1.4
cd_multiplier = 0.9
```
