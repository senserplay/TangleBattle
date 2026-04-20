# Lucky Star — Счастливая звезда

## Описание
Повышает шанс выпадения **редких пассивок** при выборе между раундами.
Каждое очко удачи (`luck_bonus`) сдвигает распределение редкости в пользу
более высоких редкостей. Стакается с другими источниками удачи.

## Редкости
| Редкость | Удача | Эффект (примерный) |
|----------|-------|--------------------|
| Common | +1 | Чуть чаще Uncommon |
| Uncommon | +2.5 | Заметно чаще Rare |
| Rare | +4 | Часто Rare/Legendary |
| Legendary | +6 | Редко-уже Common |
| Mythic | +10 | Почти всегда Rare+ |

Не имеет штрафов — чистая utility-пассивка.

```toml
[config]
id = 20
name = "Lucky Star"
description = "Повышает шанс редких пассивок"
icon = "lucky"
available_rarities = [0, 1, 2, 3, 4]

[rarities.common]
luck_bonus = 1.0

[rarities.uncommon]
luck_bonus = 2.5

[rarities.rare]
luck_bonus = 4.0

[rarities.legendary]
luck_bonus = 6.0

[rarities.mythic]
luck_bonus = 10.0
```
