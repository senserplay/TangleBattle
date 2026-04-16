# Needle Dash — Рывок иглой

## Тип: `melee`

## Описание
Игрок совершает стремительный рывок в направлении прицела.
Во время рывка (длительность `dash_duration`) игрок движется со скоростью `dash_speed`.
Все враги на пути рывка (в радиусе `hit_radius`) получают `damage` урона и отбрасываются с силой `knockback` + подброс `knockback_up`.

## Визуал
Частицы пыли при старте рывка. Игрок неуязвим к управлению во время рывка.

```toml
[config]
id = 3
name = "Needle Dash"
types = ["melee"]
cooldown = 2.0
color = [1.0, 0.3, 0.3]
damage = 35.0
knockback = 700.0
knockback_up = 200.0
dash_speed = 900.0
dash_duration = 0.2
hit_radius = 50.0
```
