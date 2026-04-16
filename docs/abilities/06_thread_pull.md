# Thread Pull — Притяжение нитью

## Тип: `melee`

## Описание
Игрок выпускает нить, которая хватает ближайшего врага в направлении прицела (порог dot product `aim_threshold`).
Враг в радиусе `max_range` притягивается к игроку с силой `pull_force` + подброс `pull_up`, и получает `damage` урона.
Выбирается враг с наибольшим dot product к направлению прицела.

## Визуал
Нет специального визуала кроме эффекта откидывания на враге.

```toml
[config]
id = 6
name = "Thread Pull"
types = ["melee"]
cooldown = 1.5
color = [0.5, 1.0, 0.5]
damage = 20.0
pull_force = 800.0
pull_up = 200.0
max_range = 400.0
aim_threshold = 0.5
```
