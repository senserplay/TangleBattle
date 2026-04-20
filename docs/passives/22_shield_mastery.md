# Shield Mastery — Мастерство щита

## Описание
Уменьшает кулдаун парирования (щита). Базовый КД щита умножается на
`parry_cd_mult`. Стакается с другими источниками сокращения КД.

Особенно силён в комбо с **Parry Burst** (несколько парирований за раз) и
**Spirit Burst** (Mythic essences при каждом парировании).

## Редкости
| Редкость | КД щита | Бонус |
|----------|---------|-------|
| Common | -15% | — |
| Uncommon | -25% | — |
| Rare | -40% | — |
| Legendary | -55% | +5% скорость |
| Mythic | -70% | +10% скорость, +10% урон |

```toml
[config]
id = 22
name = "Shield Mastery"
description = "Уменьшает кулдаун щита"
icon = "shield_cd"
available_rarities = [0, 1, 2, 3, 4]

[rarities.common]
parry_cd_mult = 0.85

[rarities.uncommon]
parry_cd_mult = 0.75

[rarities.rare]
parry_cd_mult = 0.6

[rarities.legendary]
parry_cd_mult = 0.45
speed_multiplier = 1.05

[rarities.mythic]
parry_cd_mult = 0.3
speed_multiplier = 1.1
damage_multiplier = 1.1
```
