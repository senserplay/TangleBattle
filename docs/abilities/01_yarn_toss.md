# Yarn Toss — Бросок клубка

## Тип: `projectile`

## Описание
Дальняя атака. Игрок выпускает снаряд в направлении прицела.
Снаряд летит со скоростью `speed`, при попадании наносит `damage` урона, отбрасывает с силой `knockback` + подброс `knockback_up`, и оглушает на `stun_duration` секунд.
Снаряд имеет радиус `projectile_radius` и исчезает при столкновении с платформой или через `lifetime` секунд.

## Визуал
Круглый клубок цвета игрока с трейлом. Размер определяется `projectile_radius`.

```toml
[config]
id = 1
name = "Yarn Toss"
types = ["projectile"]
cooldown = 1.2
color = [0.4, 0.8, 1.0]
damage = 35.0
knockback = 800.0
knockback_up = 200.0
stun_duration = 0.5
speed = 900.0
projectile_radius = 12.0
lifetime = 3.0
```
