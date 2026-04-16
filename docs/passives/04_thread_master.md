# Thread Master — Мастер нити

## Описание
Увеличивает дальность и скорость grapple-нити.
Позволяет цепляться за более далёкие платформы и быстрее добираться до точки зацепа.

## Редкости

| Редкость | Дальность нити | Скорость нити | Штраф |
|----------|---------------|---------------|-------|
| Common | +30% дальность | +20% скорость | -15% HP |
| Uncommon | +50% дальность | +30% скорость | -10% HP |
| Rare | +75% дальность | +50% скорость | без штрафа |
| Legendary | +100% дальность | +80% скорость | +20% скорость движения |

```toml
[config]
id = 4
name = "Thread Master"
description = "Увеличивает дальность и скорость нити"
icon = "thread"

[rarities.common]
positive = "+30% дальность, +20% скорость нити"
negative = "-15% HP"
grapple_range_mult = 1.3
grapple_speed_mult = 1.2
hp_multiplier = 0.85

[rarities.uncommon]
positive = "+50% дальность, +30% скорость нити"
negative = "-10% HP"
grapple_range_mult = 1.5
grapple_speed_mult = 1.3
hp_multiplier = 0.9

[rarities.rare]
positive = "+75% дальность, +50% скорость нити"
negative = ""
grapple_range_mult = 1.75
grapple_speed_mult = 1.5
hp_multiplier = 1.0

[rarities.legendary]
positive = "+100% дальность, +80% скорость нити, +20% скорость"
negative = ""
grapple_range_mult = 2.0
grapple_speed_mult = 1.8
hp_multiplier = 1.0
speed_multiplier = 1.2
```
