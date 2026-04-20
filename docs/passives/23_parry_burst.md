# Parry Burst — Серия парирований

## Описание
Позволяет щиту срабатывать **несколько раз подряд**. После основного
парирования игрок получает +`burst_count` дополнительных авто-парирований
с минимальной задержкой между ними.

Сочетается с Shield Mastery (короткий КД → быстрая регенерация серии) и
Spirit Burst (каждое парирование выпускает эссенции).

## Редкости
| Редкость | Доп. парирования | Штраф |
|----------|------------------|-------|
| Rare | +1 | +15% КД способностей |
| Legendary | +2 | — |
| Mythic | +3 | -10% КД щита |

```toml
[config]
id = 23
name = "Parry Burst"
description = "Щит активируется несколько раз подряд"
icon = "parry_burst"
available_rarities = [2, 3, 4]

[rarities.rare]
burst_count = 1
cd_multiplier = 1.15

[rarities.legendary]
burst_count = 2

[rarities.mythic]
burst_count = 3
parry_cd_mult = 0.9
```
