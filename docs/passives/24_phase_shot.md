# Phase Shot — Призрачный выстрел

## Описание
Снаряды (`projectile`-типа) **проходят сквозь стены** карты и **сквозь
вражеский щит**. То есть никакая преграда — кроме самой жертвы — не может
их остановить.

Особенно силён против карт с walls (use_walls / fire_walls / bouncy_walls)
и против игроков-парировщиков с Shield Mastery.

## Редкости
| Редкость | Эффект | Бонус | Штраф |
|----------|--------|-------|-------|
| Legendary | Проход через стены | — | -15% урон |
| Mythic | Проход через стены | +10% скорость снарядов | — |

```toml
[config]
id = 24
name = "Phase Shot"
description = "Снаряды проходят через стены и щит"
icon = "phase"
affects_types = ["projectile"]
available_rarities = [3, 4]

[rarities.legendary]
positive = "Снаряды проходят через стены"
negative = "-15% урон"
damage_multiplier = 0.85

[rarities.mythic]
positive = "Снаряды через стены, +10% скорость"
speed_multiplier = 1.1
```
