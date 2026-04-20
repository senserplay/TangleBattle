# Lightning Strike — Удар молнии

## Описание
Каждый нанесённый урон накладывает на жертву **замедление** (slow effect)
на `slow_duration` секунд. Эффект работает на любой источник урона —
снаряды, ближний бой, взрывы, контакт.

## Редкости
| Редкость | Замедление | Бонус | Штраф |
|----------|-----------|-------|-------|
| Uncommon | 0.3с | — | +10% КД |
| Rare | 0.5с | — | — |
| Legendary | 0.8с | +15% урон | — |
| Mythic | 1.2с | +20% урон | — |

```toml
[config]
id = 16
name = "Lightning Strike"
description = "Урон накладывает замедление молнией"
icon = "lightning"
available_rarities = [1, 2, 3, 4]

[rarities.uncommon]
positive = "0.3с замедление при ударе"
negative = "+10% кд"
slow_duration = 0.3
cd_multiplier = 1.1

[rarities.rare]
slow_duration = 0.5

[rarities.legendary]
slow_duration = 0.8
damage_multiplier = 1.15

[rarities.mythic]
slow_duration = 1.2
damage_multiplier = 1.2
```
