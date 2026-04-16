# Glass Cannon — Стеклянная пушка

## Описание
Сильно увеличивает весь наносимый урон, но сильно уменьшает максимальное здоровье.

## Редкости
| Редкость | Урон | HP |
|----------|------|------|
| Common | +40% урон | -40% HP |
| Uncommon | +60% урон | -35% HP |
| Rare | +80% урон | -30% HP |
| Legendary | +100% урон | -20% HP |

```toml
[config]
id = 13
name = "Glass Cannon"
description = "Больше урон, меньше HP"
icon = "glass_cannon"

[rarities.common]
positive = "+40% урон"
negative = "-40% HP"
damage_multiplier = 1.4
hp_multiplier = 0.6

[rarities.uncommon]
positive = "+60% урон"
negative = "-35% HP"
damage_multiplier = 1.6
hp_multiplier = 0.65

[rarities.rare]
positive = "+80% урон"
negative = "-30% HP"
damage_multiplier = 1.8
hp_multiplier = 0.7

[rarities.legendary]
positive = "+100% урон"
negative = "-20% HP"
damage_multiplier = 2.0
hp_multiplier = 0.8
```
