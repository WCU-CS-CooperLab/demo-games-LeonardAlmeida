# geode.gd

extends Area2D
@export var geode_animations = ["copper", "gold", "iron", "stone1", "stone2"]
var animated_sprite: AnimatedSprite2D  # Ref to AnimatedSprite2D

func _ready():
	animated_sprite = $AnimatedSprite2D
	
	# Rand choose an anim
	var random_animation = geode_animations[randi() % geode_animations.size()]
	
	# play animation
	animated_sprite.play(random_animation)
	add_to_group("geode")

func geode_grabbed():
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var main = get_tree().root.get_node("Main")  # Adjust if your main node has a different name
		main._on_geode_picked_up()
		geode_grabbed()
		
