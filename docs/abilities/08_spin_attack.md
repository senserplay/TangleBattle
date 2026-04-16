# Spin Attack — Вращающаяся атака

## Тип: `melee`, `explosion`

## Описание
Атака по кругу на 360 градусов. Все враги в радиусе `radius` получают `damage` урона и отбрасываются от игрока с силой `knockback` + подброс `knockback_up`.
Не требует направления прицела — бьёт во все стороны.

## Визуал
Расширяющееся кольцо вокруг игрока длительностью `visual_duration` секунд.

```toml
[config]
id = 8
name = "Spin Attack"
types = ["melee", "explosion"]
cooldown = 1.5
color = [1.0, 0.8, 0.2]
damage = 30.0
knockback = 800.0
knockback_up = 400.0
radius = 120.0
visual_duration = 0.2
```
