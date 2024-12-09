extends CharacterBody2D

var screensize = Vector2.ZERO

@export var speed = 200  # Normal speed
@export var sprint_speed = 350  # Sprint speed
@export var gravity = 1000  # Gravity force
@export var jump_force = -500  # Upward jump force
@export var geode_scene : PackedScene
@export var bullet_scene : PackedScene
@export var fire_rate = 0.25
var can_shoot = true

enum {INIT, ALIVE, BOOSTED, DEAD}
var state = INIT

func _ready():
	add_to_group("player")
	screensize = get_viewport_rect().size
	change_state(ALIVE)
	$GunCooldown.wait_time = fire_rate
	velocity = Vector2.ZERO  # Start with no velocity

func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
		BOOSTED:
			$CollisionShape2D.set_deferred("disabled", true)
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
	state = new_state

func _process(delta):
	get_input()
	update_animation()

func get_input():
	if state in [DEAD, INIT]:
		return
	
	# Determine movement speed based on sprint key
	var movement_speed = speed
	if Input.is_action_pressed("run"):  # Assuming "sprint" is Shift or custom input
		movement_speed = sprint_speed

	# Horizontal movement
	var horizontal_input = Input.get_axis("turn_left", "turn_right")
	velocity.x = horizontal_input * movement_speed

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# Shooting
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
	if horizontal_input != 0:
		$AnimatedSprite2D.scale.x = horizontal_input  # Left (-1) or Right (1)
		
func update_animation():
	
	var anim = $AnimatedSprite2D
	if Input.is_action_pressed("shoot"):
		anim.play("shooting")  # Shooting
	elif velocity.x == 0 and is_on_floor():
		anim.play("idle")  # No movement, play idle
	elif Input.is_action_pressed("run") and velocity.x != 0:
		anim.play("running")  # Sprinting
	elif velocity.x != 0:
		anim.play("walk")  # Moving but not sprinting
	elif Input.is_action_pressed("jump") and !is_on_floor():
		anim.play("jump")  # Jumping

	else:
		anim.play("idle")  # Default to idle if none of the above

func _physics_process(delta):
	# Apply gravity if not on the floor
	if !is_on_floor():
		velocity.y += gravity * delta

	# Move using velocity
	move_and_slide()

	# Clamp position to keep the player within screen bounds


func shoot():
	if state == BOOSTED:
		return

	# Get the mouse position relative to the player
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()

	# Check if the mouse is in front of the player based on their facing direction
	if $AnimatedSprite2D.scale.x > 0 and direction_to_mouse.x >= 0:
		# Facing right and mouse is to the right
		spawn_bullet(direction_to_mouse)
	elif $AnimatedSprite2D.scale.x < 0 and direction_to_mouse.x <= 0:
		# Facing left and mouse is to the left
		spawn_bullet(direction_to_mouse)
func spawn_bullet(direction: Vector2):
	can_shoot = false
	$GunCooldown.start()
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = $Muzzle.global_position  # Set bullet's initial position at the muzzle
	bullet.start(direction)  # Set bullet's initial direction

func _on_gun_cooldown_timeout() -> void:
	can_shoot = true
