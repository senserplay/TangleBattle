# Ricochet — Отскоки

## Описание
Снаряды (тип `projectile`) могут отскочить от платформ `bounce_count` раз вместо уничтожения при столкновении с ними. При каждом отскоке снаряд теряет часть скорости.

## Редкости

| Редкость | Отскоки | Штраф |
|----------|---------|-------|
| Uncommon | 1 отскок | -15% скорость снарядов |
| Rare | 2 отскока | без штрафа |
| Legendary | 3 отскока | +20% скорость снарядов |

```toml
[config]
id = 8
name = "Ricochet"
description = "Снаряды отскакивают от платформ"
icon = "ricochet"

[rarities.uncommon]
positive = "+1 отскок"
negative = "-15% скорость снарядов"
bounce_count = 1
projectile_speed_mult = 0.85

[rarities.rare]
positive = "+2 отскока"
negative = ""
bounce_count = 2
projectile_speed_mult = 1.0

[rarities.legendary]
positive = "+3 отскока, +20% скорость"
negative = ""
bounce_count = 3
projectile_speed_mult = 1.2
```
