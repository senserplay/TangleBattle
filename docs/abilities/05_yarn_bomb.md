# Yarn Bomb — Клубок-бомба

## Тип: `explosion`

## Описание
Мгновенный взрыв на расстоянии `explosion_range` от игрока в направлении прицела.
Все враги в радиусе `explosion_radius` от точки взрыва получают `damage` урона и отбрасываются с силой `knockback` + подброс `knockback_up`.

## Визуал
Вспышка визуала удара нитью в направлении прицела (длительность `visual_duration`).

```toml
[config]
id = 5
name = "Yarn Bomb"
types = ["explosion"]
cooldown = 2.5
color = [1.0, 0.4, 0.6]
damage = 35.0
knockback = 900.0
knockback_up = 500.0
explosion_range = 250.0
explosion_radius = 150.0
visual_duration = 0.3
```
