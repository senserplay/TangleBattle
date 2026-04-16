# Fire Thread — Огненная нить

## Описание
Grapple-нить игрока становится огненной. Враги, пересекающие нить во время полёта на ней, получают `burn_damage` урона огнём каждые `burn_tick` секунд в течение `burn_duration` секунд.

## Редкости

| Редкость | Урон огнём | Длительность | Штраф |
|----------|-----------|-------------|-------|
| Legendary | 12 за тик | 2с (4 тика) | — |

Общий урон: 12 * 4 = 48 HP.

```toml
[config]
id = 7
name = "Fire Thread"
description = "Нить наносит урон огнём"
icon = "fire_thread"

[rarities.legendary]
positive = "Огненная нить: 48 урон"
negative = ""
burn_damage = 12.0
burn_tick = 0.5
burn_duration = 2.0
```
