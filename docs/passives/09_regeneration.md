# Regeneration — Регенерация

## Описание
Игрок восстанавливает `regen_per_sec` здоровья в секунду. Не превышает максимальное HP.

## Редкости

| Редкость | Реген/сек | Штраф |
|----------|----------|-------|
| Rare | 3 HP/сек | -10% макс HP |
| Legendary | 5 HP/сек | без штрафа |

```toml
[config]
id = 9
name = "Regeneration"
description = "Восстановление здоровья"
icon = "regen"

[rarities.rare]
positive = "+3 HP/сек"
negative = "-10% макс HP"
regen_per_sec = 3.0
hp_multiplier = 0.9

[rarities.legendary]
positive = "+5 HP/сек"
negative = ""
regen_per_sec = 5.0
hp_multiplier = 1.0
```
