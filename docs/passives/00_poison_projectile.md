# Poison Projectile — Ядовитые снаряды

## Описание
Ваши снаряды отравляют врагов. Действует на тип атаки `projectile`.
После попадания снарядом враг получает дополнительный урон ядом (`poison_pct` от нанесённого урона) каждые `poison_tick` секунд в течение `poison_duration` секунд.

## Редкости

| Редкость | Яд | Штраф | Доп. эффект |
|----------|-----|-------|-------------|
| Common | `poison_pct` = 10% от урона | `cd_multiplier` = 1.2 (+20% кд) | — |
| Uncommon | `poison_pct` = 20% | `cd_multiplier` = 1.1 (+10% кд) | — |
| Rare | `poison_pct` = 30% | без штрафа | — |
| Legendary | `poison_pct` = 50% | без штрафа | `slow_duration` = 1.0с |

```toml
[config]
id = 0
name = "Poison Projectile"
description = "Снаряды отравляют врагов"
affects_types = ["projectile"]
poison_tick = 0.5
poison_duration = 2.0

[rarities.common]
poison_pct = 0.1
cd_multiplier = 1.2
slow_duration = 0.0

[rarities.uncommon]
poison_pct = 0.2
cd_multiplier = 1.1
slow_duration = 0.0

[rarities.rare]
poison_pct = 0.3
cd_multiplier = 1.0
slow_duration = 0.0

[rarities.legendary]
poison_pct = 0.5
cd_multiplier = 1.0
slow_duration = 1.0
```
