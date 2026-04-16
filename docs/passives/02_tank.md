# Tank — Танк

## Описание
Сильно увеличивается здоровье, но снижается скорость передвижения (включая полёт и grapple).

## Редкости

| Редкость | HP бонус | Штраф скорости |
|----------|----------|----------------|
| Common | +50% HP | -50% скорость |
| Uncommon | +75% HP | -30% скорость |
| Rare | +100% HP | -15% скорость |
| Legendary | +150% HP | без штрафа |

```toml
[config]
id = 2
name = "Tank"
description = "Увеличение здоровья"

[rarities.common]
hp_multiplier = 1.5
speed_multiplier = 0.5

[rarities.uncommon]
hp_multiplier = 1.75
speed_multiplier = 0.7

[rarities.rare]
hp_multiplier = 2.0
speed_multiplier = 0.85

[rarities.legendary]
hp_multiplier = 2.5
speed_multiplier = 1.0
```
