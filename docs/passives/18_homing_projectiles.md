# Homing Projectiles — Самонаводящиеся снаряды

## Описание
Снаряды (`projectile`-типа) приобретают **наведение** на ближайшего врага.
Сила корректировки траектории = `homing_strength`. Эффект работает на
Yarn Toss, Grenade, Rocket Launcher, Boomerang, Yarn Bomb (взрыв-снаряд).

## Редкости
| Редкость | Сила наведения | Скорость снарядов | Доп. урон | Штраф |
|----------|----------------|-------------------|-----------|-------|
| Uncommon | 1.5× | -10% | — | — |
| Rare | 2.5× | — | — | — |
| Legendary | 3.5× | +10% | — | — |
| Mythic | 5.0× | +20% | +15% | — |

```toml
[config]
id = 18
name = "Homing Projectiles"
description = "Снаряды наводятся на врагов"
icon = "homing"
affects_types = ["projectile"]
available_rarities = [1, 2, 3, 4]

[rarities.uncommon]
positive = "Наведение 1.5x"
negative = "-10% скорость снарядов"
homing_strength = 1.5
projectile_speed_mult = 0.9

[rarities.rare]
homing_strength = 2.5

[rarities.legendary]
homing_strength = 3.5
projectile_speed_mult = 1.1

[rarities.mythic]
homing_strength = 5.0
projectile_speed_mult = 1.2
damage_multiplier = 1.15
```
