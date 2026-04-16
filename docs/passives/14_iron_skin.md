# Iron Skin — Железная кожа

## Описание
Уменьшает весь получаемый урон на `damage_reduction` процентов.

## Редкости
| Редкость | Снижение урона | Штраф |
|----------|---------------|-------|
| Common | -15% входящий урон | -20% скорость |
| Uncommon | -25% входящий урон | -12% скорость |
| Rare | -30% входящий урон | — |
| Legendary | -40% входящий урон | +10% HP |

```toml
[config]
id = 14
name = "Iron Skin"
description = "Снижение получаемого урона"
icon = "iron_skin"

[rarities.common]
positive = "-15% входящий урон"
negative = "-20% скорость"
damage_reduction = 0.15
speed_multiplier = 0.8

[rarities.uncommon]
positive = "-25% входящий урон"
negative = "-12% скорость"
damage_reduction = 0.25
speed_multiplier = 0.88

[rarities.rare]
positive = "-30% входящий урон"
negative = ""
damage_reduction = 0.3

[rarities.legendary]
positive = "-40% входящий урон, +10% HP"
negative = ""
damage_reduction = 0.4
hp_multiplier = 1.1
```
