# Пассивные способности TangleBattle

**25 пассивок.** Каждая описана в `XX_name.md` (XX = enum id).
Канонические данные — в `data/passives.json`.

## Система
- Проигравшие выбирают **1 из 3** случайных пассивок между раундами.
- Действуют до конца матча, **стакаются**.
- Таймер выбора 15с, автовыбор средней при таймауте.

## Редкости
| Редкость | Код | Цвет | Шанс (базовый) |
|----------|-----|------|----------------|
| Common | 0 | Серый | 45% |
| Uncommon | 1 | Зелёный | 30% |
| Rare | 2 | Синий | 18% |
| Legendary | 3 | Золотой | 7% |
| Mythic | 4 | Красный/особый | редко |

`Lucky Star` (id 20) сдвигает распределение в пользу более высоких
редкостей.

## Все пассивки
| ID | Название | Файл | Доступные редкости | Краткое описание |
|----|----------|------|--------------------|------------------|
| 0 | Poison Projectile | [00_poison_projectile.md](00_poison_projectile.md) | C/U/R/L/M | Снаряды отравляют |
| 1 | Phoenix | [01_phoenix.md](01_phoenix.md) | R/L/M | Возрождение после смерти |
| 2 | Tank | [02_tank.md](02_tank.md) | C/U/R/L/M | +HP, -скорость |
| 3 | Lifesteal | [03_lifesteal.md](03_lifesteal.md) | C/U/R/L/M | Хил от нанесённого урона |
| 4 | Thread Master | [04_thread_master.md](04_thread_master.md) | C/U/R/L | Бонусы к нитке/grapple |
| 5 | Wide Impact | [05_wide_impact.md](05_wide_impact.md) | C/U/R/L | +радиус взрывов/AoE |
| 6 | Quick Hands | [06_quick_hands.md](06_quick_hands.md) | C/U/R/L | Сокращение КД |
| 7 | Fire Thread | [07_fire_thread.md](07_fire_thread.md) | L | Огненная нитка |
| 8 | Ricochet | [08_ricochet.md](08_ricochet.md) | U/R/L | Отскоки снарядов |
| 9 | Regeneration | [09_regeneration.md](09_regeneration.md) | R/L | HP/сек регенерация |
| 10 | Explosive Power | [10_explosive_power.md](10_explosive_power.md) | C/U/R/L | +урон+радиус взрывов |
| 11 | Swift Feet | [11_swift_feet.md](11_swift_feet.md) | C/U/R/L | +скорость, полёт |
| 12 | Projectile Master | [12_projectile_master.md](12_projectile_master.md) | C/U/R/L | +урон/скорость снарядов |
| 13 | Glass Cannon | [13_glass_cannon.md](13_glass_cannon.md) | C/U/R/L/M | ++урон, --HP |
| 14 | Iron Skin | [14_iron_skin.md](14_iron_skin.md) | C/U/R/L/M | Снижение входящего урона |
| 15 | Shockwave | [15_shockwave.md](15_shockwave.md) | C/U/R/L/M | Отталкивание при парировании |
| 16 | Lightning Strike | [16_lightning_strike.md](16_lightning_strike.md) | U/R/L/M | Замедление при ударе |
| 17 | Heavy Impact | [17_heavy_impact.md](17_heavy_impact.md) | C/U/R/L | +сила столкновений |
| 18 | Homing Projectiles | [18_homing_projectiles.md](18_homing_projectiles.md) | U/R/L/M | Наведение снарядов |
| 19 | Burst Fire | [19_burst_fire.md](19_burst_fire.md) | R/L/M | Залповая стрельба |
| 20 | Lucky Star | [20_lucky_star.md](20_lucky_star.md) | C/U/R/L/M | Удача (редкие пассивки чаще) |
| 21 | Spirit Burst | [21_spirit_burst.md](21_spirit_burst.md) | M | Эссенции при парировании |
| 22 | Shield Mastery | [22_shield_mastery.md](22_shield_mastery.md) | C/U/R/L/M | -КД щита |
| 23 | Parry Burst | [23_parry_burst.md](23_parry_burst.md) | R/L/M | Серия парирований |
| 24 | Phase Shot | [24_phase_shot.md](24_phase_shot.md) | L/M | Снаряды через стены и щит |

Обозначения: **C** = Common, **U** = Uncommon, **R** = Rare, **L** =
Legendary, **M** = Mythic.

## Mythic-only пассивки
Только Mythic (топ-редкость, выпадают редко даже с Lucky Star):
- **Spirit Burst** (id 21) — эссенции при парировании

Имеют доступ к Mythic + другим:
- Phoenix (R/L/M), Glass Cannon, Iron Skin, Lucky Star, Shockwave,
  Lightning Strike, Homing Projectiles, Burst Fire, Shield Mastery,
  Parry Burst, Phase Shot, Poison Projectile, Tank, Lifesteal.

## Синергии (примеры)
- **Shield Mastery + Parry Burst + Spirit Burst** — Mythic-комбо: щит
  с минимальным КД, серия парирований, каждое выпускает эссенции.
- **Burst Fire + Homing Projectiles + Projectile Master** —
  залповый поток снарядов с наведением и усиленным уроном.
- **Glass Cannon + Lifesteal** — высокий урон + восстановление, но
  один промах при низком HP смертелен.
- **Phase Shot + Burst Fire** — несколько проходящих сквозь стены
  снарядов на залп — почти невозможно увернуться на стенных картах.
