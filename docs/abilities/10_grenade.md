# Grenade — Граната

## Тип: `projectile`, `explosion`

## Описание
Способность с зарядкой. Зажатие кнопки способности начинает заряд.
Скорость броска = `min_throw_speed` + заряд * (`max_throw_speed` - `min_throw_speed`).
Заряд копится `charge_time` секунд до максимума.
Если держать дольше `overcharge_time` секунд — граната взрывается в руках.
При отпускании кнопки граната бросается СТРОГО в направлении прицела со скоростью заряда.
Граната подвержена гравитации, отскакивает от платформ (`bounce_damping`).
Взрывается через `fuse_time` секунд ИЛИ при контакте с вражеским игроком.
Взрыв наносит `damage` * falloff урона и отбрасывает с силой `knockback` * falloff + подброс `knockback_up` * falloff в радиусе `explosion_radius`.
Граната не взрывается при контакте с владельцем в течение первых `owner_safe_time` секунд.

## Визуал
Мигающий круг с фитилём. Скорость мигания увеличивается.
При зарядке — растущее кольцо вокруг игрока.
При взрыве — расширяющиеся круги.

```toml
[config]
id = 10
name = "Grenade"
types = ["projectile", "explosion"]
cooldown = 2.5
color = [0.8, 0.3, 0.1]
min_throw_speed = 800.0
max_throw_speed = 2000.0
charge_time = 1.0
overcharge_time = 2.5
bounce_damping = 0.5
fuse_time = 2.0
owner_safe_time = 0.3
explosion_radius = 180.0
damage = 50.0
knockback = 1100.0
knockback_up = 500.0
player_detect_radius = 20.0
grenade_radius = 14.0
```
