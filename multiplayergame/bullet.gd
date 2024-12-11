extends Area2D

@export var speed = 1000
@export var damage = 25

var velocity = Vector2.ZERO

func _ready():
	add_to_group("bullet")  # Add this rock to the "rocks" group
	
func start(bullet_direction: Vector2):
	velocity = bullet_direction.normalized() * speed

func _process(delta):
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()





func _on_bulletarea_body_entered(body: Node2D) -> void:
	if body.is_in_group("rock"):
		body.explode()
		queue_free()
	if body.is_in_group("player"):  # Ensure players are in the "player" group
		body.take_damage(damage)
		queue_free() 
