extends RigidBody2D

@export var geode_scene : PackedScene
var screensize = Vector2.ZERO
var size
var radius 
var scale_factor = 0.2

func start(_position, _velocity, _size):
	position = _position
	size = _size
func _ready():
	add_to_group("rock")
	
func _physics_process(delta):
	if position.x > screensize.x:
		position.x = 0
	if position.x < 0:
		position.x = screensize.x
	if position.y > screensize.y:
		position.y = 0
	if position.y < 0:
		position.y = screensize.y
		
func explode():
	if geode_scene == null:
		print("Error: geode_scene is null!")
	var geode = geode_scene.instantiate()
	geode.position = position + Vector2(0, +5) # Set its position to the current position of the rock

	# Defer both adding the geode to the scene and freeing the rock
	print("Adding geode to parent:", get_parent())
	get_tree().root.call_deferred("add_child", geode)  # Add directly to root
	call_deferred("queue_free")  # Defer the removal of the current rock instance
