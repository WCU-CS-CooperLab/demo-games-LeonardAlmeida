extends Node2D
@export var rock_scene : PackedScene
@export var geode_scene : PackedScene


var screensize = Vector2.ZERO
var geode_count = -1  # Var to track geode count
var geode_label  # Ref to the label node





func _ready():

	geode_label = get_node("Player/Control/RichTextLabel")

	screensize = get_viewport().get_visible_rect().size
	for i in 10:
		spawn_rock(10)
		

func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)

func _on_geode_picked_up():
	geode_count += 1
	update_geode_label()

func update_geode_label():
	if geode_label:
		geode_label.text = "Geodes: %d " % geode_count 
