extends Resource
class_name TypedWeaponFamily

@export var family_id := "debug_plasma"
@export var max_energy := 100.0
@export var firing_cost := 5.0
@export var fire_interval := 0.1
@export var projectile_speed := 760.0
@export var projectile_damage := 3.0
@export var projectile_sprite: Texture2D


func normalized_max_energy() -> float:
	return maxf(max_energy, 0.0)


func normalized_firing_cost() -> float:
	return maxf(firing_cost, 0.0)


func normalized_fire_interval() -> float:
	return maxf(fire_interval, 0.01)
