extends CharacterBody2D

var screensize = Vector2.ZERO
@export var health = 100
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


func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	add_to_group("player")
	screensize = get_viewport_rect().size
	change_state(ALIVE)
	$GunCooldown.wait_time = fire_rate

func _on_gun_cooldown_timeout():
	can_shoot = true

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

# This function handles local player input and synchronizes it via RPC for remote players
func _process(delta):
	if is_multiplayer_authority():
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

	# Synchronize input across the network
	rpc("synchronize_input", horizontal_input, velocity.y, Input.is_action_pressed("jump"), Input.is_action_pressed("shoot"))
	
	
	if horizontal_input != 0:
		$AnimatedSprite2D.scale.x = horizontal_input  # Left (-1) or Right (1)
		update_muzzle_position()

# RPC function to synchronize input across peers
@rpc
func synchronize_input(horizontal_input: float, vertical_velocity: float, is_jumping: bool, is_shooting: bool):
	# Update the local player's state based on synchronized inputs
	if state in [DEAD, INIT]:
		return
	
	# Horizontal movement
	velocity.x = horizontal_input * speed
	velocity.y = vertical_velocity  # Update vertical velocity (e.g., from gravity)

	# Update jump state
	if is_jumping and is_on_floor():
		velocity.y = jump_force
	
	# Handle shooting state
	if is_shooting and can_shoot:
		shoot()
		
	

# Update animation based on state
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

# Movement logic in physics process
func _physics_process(delta):
	if is_multiplayer_authority():
		if !is_on_floor():
			velocity.y += gravity * delta  # Apply gravity if not on the ground

		# Move the player
		move_and_slide()

# Shooting logic
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

# Function to spawn a bullet
func spawn_bullet(direction: Vector2):
	can_shoot = false
	$GunCooldown.start()
	
	if bullet_scene == null:
		print("Bullet scene is missing!")
		return
	
	var bullet = bullet_scene.instantiate()
	if bullet == null:
		print("Failed to instantiate bullet!")
		return
	
	# Add the bullet to the current scene tree
	get_tree().root.add_child(bullet)
	bullet.global_position = $Muzzle.global_position  # Ensure $Muzzle exists in the scene
	
	if bullet.has_method("start"):
		bullet.start(direction)  # Pass direction to the bullet's logic
	else:
		print("Bullet scene does not have a 'start' method.")

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	print("Player has died!")
	change_state(DEAD)

func update_muzzle_position():
	if $AnimatedSprite2D.scale.x > 0:
		$Muzzle.position.x = abs($Muzzle.position.x)  # Move muzzle to the right
	else:
		$Muzzle.position.x = -abs($Muzzle.position.x)  # Move muzzle to the lef
