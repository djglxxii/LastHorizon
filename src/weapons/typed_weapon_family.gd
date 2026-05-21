extends Resource
class_name TypedWeaponFamily

# Archetypes are stored as integer ordinals in .tres files:
# SINGLE = one straight projectile, SPREAD = fan pattern, PIERCE = straight projectile that keeps traveling through hits.
enum WeaponArchetype { SINGLE, SPREAD, PIERCE }

@export var family_id := "debug_plasma"
@export var display_name := "Debug Plasma"
@export var tint_color := Color(0.3, 0.95, 1.0)
@export var archetype: WeaponArchetype = WeaponArchetype.SINGLE
@export var spread_count := 1
@export var spread_angle_degrees := 0.0
@export var pierce := false
@export var max_energy := 100.0
@export var firing_cost := 1.0
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


func normalized_spread_count() -> int:
	return maxi(spread_count, 1)
