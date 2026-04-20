# Способности TangleBattle

**17 активных способностей.** Каждая описана в `XX_name.md` (XX = enum id
из `ability_registry.gd`). Канонические данные — в `data/abilities.json`.
Система типов урона — в `docs/DAMAGE_TYPES.md`.

## Все способности
| ID | Название | Файл | Типы | КД |
|----|----------|------|------|-----|
| 0 | Yarn Toss | [01_yarn_toss.md](01_yarn_toss.md) | projectile | 1.2 |
| 1 | Needle Dash | [03_needle_dash.md](03_needle_dash.md) | melee | 2.0 |
| 2 | Yarn Bomb | [05_yarn_bomb.md](05_yarn_bomb.md) | explosion | 2.5 |
| 3 | Thread Pull | [06_thread_pull.md](06_thread_pull.md) | melee | 1.5 |
| 4 | Spin Attack | [08_spin_attack.md](08_spin_attack.md) | melee, explosion | 1.5 |
| 5 | Grenade | [10_grenade.md](10_grenade.md) | projectile, explosion | 2.5 |
| 6 | Rocket Launcher | [11_rocket_launcher.md](11_rocket_launcher.md) | projectile, explosion | 3.0 |
| 7 | Stink Cloud | [12_stink_cloud.md](12_stink_cloud.md) | trap, dot | 5.0 |
| 8 | Spike Armor | [13_spike_armor.md](13_spike_armor.md) | contact, reflect | 6.0 |
| 9 | Swap | [14_swap.md](14_swap.md) | utility | 4.0 |
| 10 | Boomerang | [15_boomerang.md](15_boomerang.md) | projectile | 2.5 |
| 11 | Guided Rocket | [16_guided_rocket.md](16_guided_rocket.md) | projectile, explosion | 5.0 |
| 12 | Tripwire | [17_tripwire.md](17_tripwire.md) | trap | 2.0 |
| 13 | Grab Throw | [13_grab_throw.md](13_grab_throw.md) | melee | 3.0 |
| 14 | Black Hole | [14_black_hole.md](14_black_hole.md) | trap, dot | 12.0 |
| 15 | Portal Gate | [15_portal_gate.md](15_portal_gate.md) | utility | 8.0 |
| 16 | Heaven's Wrath | [16_heavens_wrath.md](16_heavens_wrath.md) | projectile, explosion | 10.0 |

> ⚠️ Префиксы XX в именах файлов исторически НЕ совпадают с enum-ID
> (legacy numbering). Канонические значения — `data/abilities.json` и
> `ability_registry.gd::enum`.

## Особенности механик
- **Способности без цели** (Thread Pull, Swap, Grab Throw) **не тратят
  кулдаун при промахе** — позволяют пробовать снова без штрафа.
- **Portal Gate** работает в 2 нажатия — первое ставит первый портал,
  второе ставит парный и активирует пару.
- **Black Hole** не различает врагов и союзников — призывающий тоже
  попадает в зону притяжения.
- **Heaven's Wrath** запускает 6 столбов с задержкой 0.07с — узкая
  полоса аннигиляции 720px шириной, до 330 урона при идеальном попадании.
- **Активная нитка автоматически обрывается** при teleport через portal,
  swap и grab — иначе rope anchor возвращал бы игрока обратно (fix v0.5).

## Удалённые (для истории)
- Thread Whip (ближний бой)
- Wool Shield (отдельная способность; теперь щит — встроенная механика)
- Knit Wall (стена)
- Thread Blink (телепорт)
- Tangle Trap (ловушка)
