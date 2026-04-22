# Shockwave — Ударная волна

## Описание
При **активации щита** (парирование) выпускает круговую ударную волну,
которая отталкивает врагов в радиусе. Срабатывает независимо от того,
был ли заблокирован удар в этот момент.

**Перезарядка 5 секунд** — жёсткая константа `SHOCKWAVE_CD` в
`player.gd`. Никакие пассивки не могут её сократить или удлинить.
Повторное нажатие щита до истечения 5 с срабатывает как обычный щит,
но ударную волну не запускает. Parry Burst (id 23) тоже подчиняется
этому кулдауну.

## Редкости
| Редкость | Эффект | Штраф |
|----------|--------|-------|
| Common | Отталкивание ×1.0 | -10% HP |
| Uncommon | Отталкивание ×1.3 | — |
| Rare | Отталкивание ×1.6 | — |
| Legendary | Отталкивание ×2.0 + 10% скорость | — |
| Mythic | Отталкивание ×2.5 + 15% скорость | — |

```toml
[config]
id = 15
name = "Shockwave"
description = "Парирование отталкивает врагов"
icon = "shockwave"
available_rarities = [0, 1, 2, 3, 4]

[rarities.common]
positive = "Отталкивание x1.0 при парировании"
negative = "-10% HP"
radius_mult = 1.0
hp_multiplier = 0.9

[rarities.uncommon]
radius_mult = 1.3

[rarities.rare]
radius_mult = 1.6

[rarities.legendary]
radius_mult = 2.0
speed_multiplier = 1.1

[rarities.mythic]
radius_mult = 2.5
speed_multiplier = 1.15
```
