# Thread Master — Мастер нити

## Описание
Увеличивает дальность grapple-нити.
Скорость выстрела и возврата нити автоматически масштабируется
пропорционально дальности — время полного круговорота (вылет + возврат)
остаётся примерно одинаковым при любом множителе.

Дальность жёстко ограничена сверху константой
`GRAPPLE_RANGE_MULT_CAP = 2.5` в `player.gd` (совокупный множитель не
может превысить x2.5), чтобы нить не улетала за экран при стеке
нескольких копий.

## Редкости

| Редкость | Дальность нити | Штраф |
|----------|---------------|-------|
| Common | +30% | -15% HP |
| Uncommon | +50% | -10% HP |
| Rare | +75% | без штрафа |
| Legendary | +100% | +20% скорость движения |

```toml
[config]
id = 4
name = "Thread Master"
description = "Увеличивает дальность нити (скорость растёт пропорционально)"
icon = "thread"

[rarities.common]
positive = "+30% дальность нити"
negative = "-15% HP"
grapple_range_mult = 1.3
hp_multiplier = 0.85

[rarities.uncommon]
positive = "+50% дальность нити"
negative = "-10% HP"
grapple_range_mult = 1.5
hp_multiplier = 0.9

[rarities.rare]
positive = "+75% дальность нити"
negative = ""
grapple_range_mult = 1.75
hp_multiplier = 1.0

[rarities.legendary]
positive = "+100% дальность нити, +20% скорость движения"
negative = ""
grapple_range_mult = 2.0
hp_multiplier = 1.0
speed_multiplier = 1.2
```
