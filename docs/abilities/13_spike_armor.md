# Spike Armor — Шипастая броня

## Тип: `contact`, `reflect`

## Описание
Игрок активирует шипастую броню на `armor_duration` секунд.
Во время действия:
1. При столкновении с другим игроком (радиус `contact_radius`) — тот получает `contact_damage` урона и отбрасывается с силой `contact_knockback`.
2. При получении любого урона — источник урона также получает 100% этого урона обратно (reflect). Сам игрок всё равно получает полный урон.
3. Контактный урон наносится не чаще `contact_cooldown` секунд одному и тому же игроку.

## Визуал
При активации из клубка плавно выдвигаются `spike_count` шипов (анимация `spike_grow_time` секунд).
При окончании действия шипы плавно убираются (`spike_shrink_time` секунд).
Шипы вращаются вокруг клубка во время действия.

```toml
[config]
id = 13
name = "Spike Armor"
types = ["contact", "reflect"]
cooldown = 6.0
color = [0.85, 0.85, 0.85]
armor_duration = 2.0
contact_damage = 20.0
contact_knockback = 500.0
contact_radius = 40.0
contact_cooldown = 0.5
spike_count = 8
spike_grow_time = 0.2
spike_shrink_time = 0.3
```
