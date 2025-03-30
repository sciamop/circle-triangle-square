extends Area2D

var forceX: int = 1000
var forceY: int = 1000
var dirX: int = 1000
var dirY: int = 1000
@export var attack_cooldown: float = 0.5

var damage: int = 10
@onready var game_manager: Node2D = $"/root/Game"
@onready var player: CharacterBody2D = $"../../../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player_attack")
	#set_deferred("disabled", true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	position = Vector2(-10,-20)

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().name.contains("enemy") && player.attacking:
		var enemy = area.get_parent()
		enemy.apply_central_impulse(Vector2(66,22) * player.direction)
		game_manager.pause_game()
		enemy.take_damage(damage)
