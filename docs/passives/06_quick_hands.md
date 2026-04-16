# Quick Hands — Быстрые руки

## Описание
Уменьшает кулдаун всех способностей.
Позволяет использовать способности значительно чаще.

## Редкости

| Редкость | Уменьшение КД | Штраф |
|----------|---------------|-------|
| Common | -15% КД | -20% HP |
| Uncommon | -25% КД | -10% HP |
| Rare | -35% КД | без штрафа |
| Legendary | -50% КД | +10% скорость |

```toml
[config]
id = 6
name = "Quick Hands"
description = "Уменьшает кулдаун способностей"
icon = "clock"

[rarities.common]
positive = "-15% кулдаун"
negative = "-20% HP"
cd_multiplier = 0.85
hp_multiplier = 0.8

[rarities.uncommon]
positive = "-25% кулдаун"
negative = "-10% HP"
cd_multiplier = 0.75
hp_multiplier = 0.9

[rarities.rare]
positive = "-35% кулдаун"
negative = ""
cd_multiplier = 0.65
hp_multiplier = 1.0

[rarities.legendary]
positive = "-50% кулдаун"
negative = "+10% скорость"
cd_multiplier = 0.5
hp_multiplier = 1.0
speed_multiplier = 1.1
```
