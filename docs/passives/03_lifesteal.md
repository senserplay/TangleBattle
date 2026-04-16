# Lifesteal — Похищение здоровья

## Описание
Добавляет к снарядам (`projectile`) и ближнему бою (`melee`) похищение здоровья.
При нанесении урона игрок восстанавливает `lifesteal_pct` от нанесённого урона.

## Редкости

| Редкость | Lifesteal | Штраф урона |
|----------|-----------|-------------|
| Common | 10% lifesteal | -30% урон |
| Uncommon | 15% lifesteal | -15% урон |
| Rare | 20% lifesteal | без штрафа |
| Legendary | 30% lifesteal | +10% урон бонус |

```toml
[config]
id = 3
name = "Lifesteal"
description = "Похищение здоровья"
affects_types = ["projectile", "melee"]

[rarities.common]
lifesteal_pct = 0.1
damage_multiplier = 0.7

[rarities.uncommon]
lifesteal_pct = 0.15
damage_multiplier = 0.85

[rarities.rare]
lifesteal_pct = 0.2
damage_multiplier = 1.0

[rarities.legendary]
lifesteal_pct = 0.3
damage_multiplier = 1.1
```
