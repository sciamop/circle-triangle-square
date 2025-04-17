extends Node

signal shape_collected(shape_type: String)
signal insight_area_entered
signal insight_area_exited

var collected_shapes: Array[String] = []

var has_seen_onboarding: bool = false    
var has_seen_shapes_onboarding: bool = false 
var has_seen_blueprint_onboarding: bool = false 
var has_seen_enemy_onboarding: bool = false
var has_grappling_hook: bool = false
var has_pick_axe: bool = false
var has_seen_circles_onboarding: bool = false
var has_seen_triangles_onboarding: bool = false
var has_seen_squares_onboarding: bool = false
var has_seen_cat_onboarding: bool = false
var has_completed_checkpoint: bool = false
