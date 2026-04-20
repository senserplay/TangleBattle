extends RefCounted
## Background layer presets — theme name → bg_layers Array.
## Used by custom_map.gd (map editor) and the map-editor UI dropdown.

const THEMES: Array[String] = [
	"forest_blue",
	"desert",
	"iceberg",
	"ocean",
	"winter_night",
	"halloween",
]

const PALETTES: Array[String] = [
	"stone", "wood", "sand", "water", "lava_ice",
]


static func get_layers(theme: String) -> Array:
	match theme:
		"forest_blue":
			var bg := "res://assets/textures/backgrounds/forest_blue/"
			return [
				{"path": bg + "00_sky.png",          "mode": "fill",        "scroll": 0.00},
				{"path": bg + "01_forest_far.png",   "mode": "bottom_tile", "scroll": 0.08, "y": 180.0},
				{"path": bg + "02_forest_mid_far.png","mode":"bottom_tile", "scroll": 0.18, "y": 150.0},
				{"path": bg + "03_forest_mid.png",   "mode": "bottom_tile", "scroll": 0.28, "y": 120.0},
				{"path": bg + "04_forest_close.png", "mode": "bottom_tile", "scroll": 0.40, "y": 80.0},
				{"path": bg + "05_particles_back.png","mode":"bottom_tile","scroll": 0.45, "y": 0.0, "tint": Color(1,1,1,0.7)},
				{"path": bg + "06_forest_front.png", "mode": "bottom_tile", "scroll": 0.55, "y": 40.0},
				{"path": bg + "07_particles_front.png","mode":"bottom_tile","scroll": 0.68, "y": 0.0, "tint": Color(1,1,1,0.6)},
				{"path": bg + "09_mist.png",         "mode": "bottom_tile", "scroll": 0.35, "y": 120.0, "tint": Color(1,1,1,0.55)},
				{"path": bg + "08_bushes.png",       "mode": "bottom_tile", "scroll": 0.85, "y": 40.0},
			]
		"desert":
			var bg := "res://assets/textures/backgrounds/desert/"
			return [
				{"path": bg + "00_background.png","mode": "fill",        "scroll": 0.00},
				{"path": bg + "01_stars.png",     "mode": "fill",        "scroll": 0.02, "tint": Color(1,1,1,0.6)},
				{"path": bg + "02_sun.png",       "mode": "fill",        "scroll": 0.04},
				{"path": bg + "03_clouds.png",    "mode": "top_tile",    "scroll": 0.10, "y": 120.0},
				{"path": bg + "04_mountains.png", "mode": "bottom_tile", "scroll": 0.18, "y": 160.0},
				{"path": bg + "05_dune_far.png",  "mode": "bottom_tile", "scroll": 0.28, "y": 120.0},
				{"path": bg + "06_dune_mid.png",  "mode": "bottom_tile", "scroll": 0.42, "y": 80.0},
				{"path": bg + "07_dune_close.png","mode": "bottom_tile", "scroll": 0.60, "y": 50.0},
				{"path": bg + "08_dune_front.png","mode": "bottom_tile", "scroll": 0.85, "y": 20.0},
			]
		"iceberg":
			var bg := "res://assets/textures/backgrounds/iceberg/"
			return [
				{"path": bg + "00_sky.png",             "mode": "fill",        "scroll": 0.00},
				{"path": bg + "01_cloud.png",           "mode": "top_tile",    "scroll": 0.08, "y": 120.0},
				{"path": bg + "02_mountains.png",       "mode": "bottom_tile", "scroll": 0.20, "y": 200.0},
				{"path": bg + "03_iceberg_reflex.png",  "mode": "bottom_tile", "scroll": 0.38, "y": 100.0},
				{"path": bg + "04_iceberg.png",         "mode": "bottom_tile", "scroll": 0.55, "y": 50.0},
				{"path": bg + "05_water_reflex.png",    "mode": "bottom_tile", "scroll": 0.75, "y": 30.0, "tint": Color(1,1,1,0.75)},
				{"path": bg + "06_water.png",           "mode": "bottom_tile", "scroll": 0.90, "y": 10.0, "tint": Color(1,1,1,0.5)},
			]
		"ocean":
			var bg := "res://assets/textures/backgrounds/ocean/"
			return [
				{"path": bg + "00_sky_sun.png",    "mode": "fill",        "scroll": 0.00},
				{"path": bg + "01_sun_light.png",  "mode": "fill",        "scroll": 0.05, "tint": Color(1,1,1,0.85)},
				{"path": bg + "02_clouds.png",     "mode": "top_tile",    "scroll": 0.10, "y": 120.0},
				{"path": bg + "03_mountains.png",  "mode": "bottom_tile", "scroll": 0.22, "y": 180.0},
				{"path": bg + "04_sea.png",        "mode": "bottom_tile", "scroll": 0.42, "y": 100.0},
				{"path": bg + "05_sand.png",       "mode": "bottom_tile", "scroll": 0.70, "y": 40.0},
				{"path": bg + "06_wave.png",       "mode": "bottom_tile", "scroll": 0.90, "y": 10.0, "tint": Color(1,1,1,0.85)},
			]
		"winter_night":
			var bg := "res://assets/textures/backgrounds/winternight/"
			return [
				{"path": bg + "00_sky.png",          "mode": "fill",        "scroll": 0.00},
				{"path": bg + "01_backmountain.png", "mode": "bottom_tile", "scroll": 0.12, "y": 220.0},
				{"path": bg + "02_midmountain.png",  "mode": "bottom_tile", "scroll": 0.28, "y": 170.0},
				{"path": bg + "03_midforest.png",    "mode": "bottom_tile", "scroll": 0.50, "y": 110.0},
				{"path": bg + "04_frontfloor.png",   "mode": "bottom_tile", "scroll": 0.85, "y": 40.0},
			]
		"halloween":
			var bg := "res://assets/textures/backgrounds/halloween/"
			return [
				{"path": bg + "00_castle_bg.png", "mode": "fill",        "scroll": 0.00},
				{"path": bg + "01_moon.png",      "mode": "fill",        "scroll": 0.04, "tint": Color(1,1,1,0.95)},
				{"path": bg + "02_clouds.png",    "mode": "top_tile",    "scroll": 0.10, "y": 120.0, "tint": Color(1,1,1,0.75)},
				{"path": bg + "03_fog_back1.png", "mode": "bottom_tile", "scroll": 0.18, "y": 200.0, "tint": Color(1,1,1,0.55)},
				{"path": bg + "04_fog_back2.png", "mode": "bottom_tile", "scroll": 0.25, "y": 170.0, "tint": Color(1,1,1,0.50)},
				{"path": bg + "05_castle.png",    "mode": "bottom_tile", "scroll": 0.35, "y": 180.0},
				{"path": bg + "06_trees1.png",    "mode": "bottom_tile", "scroll": 0.50, "y": 120.0},
				{"path": bg + "07_trees2.png",    "mode": "bottom_tile", "scroll": 0.60, "y": 80.0},
				{"path": bg + "08_fog_front1.png","mode": "bottom_tile", "scroll": 0.70, "y": 50.0, "tint": Color(1,1,1,0.60)},
				{"path": bg + "09_fog_front2.png","mode": "bottom_tile", "scroll": 0.80, "y": 30.0, "tint": Color(1,1,1,0.55)},
				{"path": bg + "10_land.png",      "mode": "bottom_tile", "scroll": 0.92, "y": 10.0},
			]
	return []


static func get_bg_color(theme: String) -> Color:
	match theme:
		"forest_blue":  return Color(0.15, 0.22, 0.30)
		"desert":       return Color(0.40, 0.30, 0.25)
		"iceberg":      return Color(0.55, 0.72, 0.86)
		"ocean":        return Color(0.42, 0.55, 0.68)
		"winter_night": return Color(0.08, 0.10, 0.18)
		"halloween":    return Color(0.08, 0.06, 0.14)
	return Color(0.1, 0.1, 0.15)
