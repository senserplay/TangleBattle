# Wide Impact — Широкий удар

## Описание
Увеличивает радиус/размер всех способностей с площадным эффектом:
- Ближний бой (dash, spin), spike armor.
- Взрывы (yarn_bomb, …).
- Ловушки и облака.
- **Heaven's Wrath**: ширина столбов света и расстояние между ними.
- **Portal Gate**: радиус свапа + визуал портала и частиц.

Не влияет на скорость и урон снарядов.

## Редкости

| Редкость | Радиус | Штраф |
|----------|--------|-------|
| Common | +25% радиус | -20% урон |
| Uncommon | +40% радиус | -10% урон |
| Rare | +60% радиус | без штрафа |
| Legendary | +80% радиус | +15% урон бонус |

```toml
[config]
id = 5
name = "Wide Impact"
description = "Увеличивает радиус способностей"
icon = "radius"

[rarities.common]
positive = "+25% радиус способностей"
negative = "-20% урон"
radius_multiplier = 1.25
damage_multiplier = 0.8

[rarities.uncommon]
positive = "+40% радиус способностей"
negative = "-10% урон"
radius_multiplier = 1.4
damage_multiplier = 0.9

[rarities.rare]
positive = "+60% радиус способностей"
negative = ""
radius_multiplier = 1.6
damage_multiplier = 1.0

[rarities.legendary]
positive = "+80% радиус способностей"
negative = "+15% урон бонус"
radius_multiplier = 1.8
damage_multiplier = 1.15
```
