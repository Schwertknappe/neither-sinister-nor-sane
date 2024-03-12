extends CharacterBody3D

## Export Variables
# Toggles
@export var roll_anim_enabled := true
@export var manual_freelook_enabled := true

# Movement variables
@export var run_speed := 7.0
@export var crouch_speed := 3.0
@export var slide_speed := 11.0

const slide_boost := 0.2
@export var slide_jump_boost := 6.0
const jump_velocity := 4.5
@export var wall_jump_velocity := 4.0
const crouching_depth := -0.8
const free_look_tilt_amount := 8
@export var wall_jump_max := 3
var wall_jumps_left := wall_jump_max

@export var wall_gravity = 20.0

# Headbobbing
const headbob_speed_multiplier := 2.5
const headbob_intensity_multiplier := 0.015

# Input variables
@export var mouse_sensitivity := 0.24
@export var controller_sensitivity := 250

## Script Variables
const lerp_speed := 14.0
const air_lerp_speed := 4.0

var current_speed := 5.0
var last_velocity := Vector3.ZERO
var horizontal_speed := 0.0
var direction = Vector3.ZERO
var slide_vector = Vector2.ZERO

var headbob_vector = Vector2.ZERO
var headbob_index = 0.0
var headbob_current_intensity = 0.0

var distance_to_floor_vector = Vector3.ZERO
var distance_to_floor = 0.0

var last_stable_ground := Vector3.ZERO


# Movement States
enum MovementState {
	RUNNING,
	SPRINTING,
	CROUCHING,
	SLIDING,
	AIRBORNE
}
var free_looking = false
var grounded_last_frame := true
var on_wall_last_frame := false
var jumping := false


var current_state := MovementState.RUNNING

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


## Functions

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Handle Mouse Camera Input
	if event is InputEventMouseMotion:
		# Looking Sideways
		if free_looking:
			%Neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		# Looking Up/Down
		%Head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))

func _physics_process(delta):
	# Make Input Vector available
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Handle Gamepad Camera Input
	var look_dir_y = Input.get_axis("look_left", "look_right")
	var look_dir_x = Input.get_axis("look_up", "look_down")
	
	# Handle camera turning
	if free_looking:
		%Neck.rotate_y(deg_to_rad(-look_dir_y * controller_sensitivity * delta))
		%Neck.rotation.y = clamp(%Neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
	else:
		rotate_y(deg_to_rad(-look_dir_y * controller_sensitivity * delta))
	
	%Head.rotate_x(deg_to_rad(-look_dir_x * controller_sensitivity * delta))
	%Head.rotation.x = clamp(%Head.rotation.x,deg_to_rad(-75),deg_to_rad(85))
	
	## Handle movement states
	if is_on_floor():
		_handle_movement_states(delta, input_dir)
	
	_handle_freelook_states(delta)
	_handle_headbob(delta, input_dir)
	
	# Add the gravity.
	if not is_on_floor():
		# Standard air gravity
		if is_on_wall_only() and distance_to_floor > 0.5:
		## Contact with wall
			# check if player has just made contact with wall this frame
			if velocity.y > 0.0:
				velocity.y = 0
			else:
				velocity.y = -wall_gravity * delta
		else:
			velocity.y -= gravity * delta
		current_state = MovementState.AIRBORNE
	
	# Handle landing animations
	if is_on_floor():
		if last_velocity.y < 0.0:
			if last_velocity.y < -10.0 and roll_anim_enabled:
				%CameraAnimationPlayer.play("roll")
			else:
				%CameraAnimationPlayer.play("land")
			wall_jumps_left = wall_jump_max
	
	# Handle blob shadow and floor detection
	if %Floor_Check.is_colliding():
		distance_to_floor_vector = position - %Floor_Check.get_collision_point()
		distance_to_floor = distance_to_floor_vector.length()
		if distance_to_floor > 0.5:
			%Blob_Shadow.albedo_mix = lerp(%Blob_Shadow.albedo_mix, 1.0, delta*lerp_speed)
		else:
			%Blob_Shadow.albedo_mix = lerp(%Blob_Shadow.albedo_mix, 0.0, delta*lerp_speed*2)
	else:
		distance_to_floor = 10.0
	
	
	## Translate input vector into direction depending ground contact
	# Case: Player is on the ground or on a wall
	if is_on_floor() or is_on_wall_only():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else:
		# Case: Player is in the air and moving -> slower movement control
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
	
	# Set Wall maneuvering variables
	if is_on_wall_only():
		direction.x /= 5.0
		direction.z /= 5.0
	
	# Status management for coyote time
	if jumping:
		jumping = !(is_on_floor() or is_on_wall_only())
	elif (!is_on_floor() and grounded_last_frame) or (!is_on_wall_only() and on_wall_last_frame):
		%Coyote_Time.start()
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and !jumping:
		if (is_on_floor() or %Coyote_Time.get_time_left() > 0) or ((is_on_wall_only() or %Coyote_Time.get_time_left() > 0) and wall_jumps_left > 0 and abs(%Neck.rotation.y) > 1.8):
			%Coyote_Time.stop()
			_jump()
	
	# lock movement direction if currently sliding
	if current_state == MovementState.SLIDING:
		direction = (transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
		current_speed = (%Slide_Timer.get_time_left() + slide_boost) * slide_speed
	
	# Handle the movement/deceleration.
	if direction:
		if current_state == MovementState.SLIDING or !is_on_floor():
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = direction.x * (current_speed * input_dir.length())
			velocity.z = direction.z * (current_speed * input_dir.length())
	else:
		# Deceleration
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	if is_on_floor():
		last_stable_ground = position
	
	if Input.is_action_pressed("respawn"):
		respawn()
	
	horizontal_speed = Vector2(velocity.x, velocity.z).length()
	%AnimationTree.set("parameters/BlendSpace1D/blend_position", velocity.length()/current_speed)
	
	last_velocity = velocity
	grounded_last_frame = is_on_floor()
	on_wall_last_frame = is_on_wall_only()
	
	move_and_slide()
	


func _handle_movement_states(delta, input_dir):
	if Input.is_action_pressed("crouch") or current_state == MovementState.SLIDING:
		
		## Crouching and Sliding
		current_speed = lerp(current_speed, crouch_speed, delta*lerp_speed)
		
		%Head.position.y = lerp(%Head.position.y,crouching_depth,delta*lerp_speed)
		%Standing_Collision_Shape.disabled = true
		%Crouching_Collision_Shape.disabled = false
			
		# Slide Begin Logic
		if current_state != MovementState.SLIDING:
			if (horizontal_speed > run_speed * 0.6) and input_dir != Vector2.ZERO:
				current_state = MovementState.SLIDING
				%Slide_Timer.start()
				slide_vector = input_dir
				free_looking = true
			else:
				# only set state to crouching if not currently sliding
				current_state = MovementState.CROUCHING
	
	# dont allow standing after previously crouching if there is no space to stand
	elif !%Height_Check.is_colliding():
		
		## Standing/Walking
		%Head.position.y = lerp(%Head.position.y,0.0,delta*lerp_speed)
		%Standing_Collision_Shape.disabled = false
		%Crouching_Collision_Shape.disabled = true
		
		current_state = MovementState.RUNNING
		if input_dir != Vector2.ZERO:
			current_speed = lerp(current_speed, run_speed, delta*(lerp_speed/4))
		else:
			current_speed = lerp(current_speed, 0.0, delta*lerp_speed)

func _handle_headbob(delta, input_dir):
	headbob_current_intensity = (horizontal_speed * headbob_intensity_multiplier)
	headbob_index += (horizontal_speed * headbob_speed_multiplier) * delta
	
	# conditions WHEN to headbob
	if is_on_floor() and current_state != MovementState.SLIDING and input_dir != Vector2.ZERO:
		headbob_vector.y = sin(headbob_index)
		headbob_vector.x = sin(headbob_index/2) + 0.5
		
		%Eyes.position.y = lerp(%Eyes.position.y, headbob_vector.y*(headbob_current_intensity), delta*lerp_speed)
		%Eyes.position.x = lerp(%Eyes.position.x, headbob_vector.x*(headbob_current_intensity/1.5), delta*lerp_speed)
	else:
		%Eyes.position.y = lerp(%Eyes.position.y, 0.0, delta*lerp_speed)
		%Eyes.position.x = lerp(%Eyes.position.x, 0.0, delta*lerp_speed)

func _handle_freelook_states(delta):
	if (Input.is_action_pressed("free_look") and manual_freelook_enabled) or current_state == MovementState.SLIDING or is_on_wall_only():
		free_looking = true
		if current_state == MovementState.SLIDING:
			%Eyes.rotation.z = lerp(%Eyes.rotation.z, -deg_to_rad(7.0), delta*lerp_speed)
		else:
			%Eyes.rotation.z = -deg_to_rad(%Neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		%Eyes.rotation.z = lerp(%Eyes.rotation.z, 0.0, delta*lerp_speed)
		%Neck.rotation.y = lerp(%Neck.rotation.y, 0.0, delta*lerp_speed)

func _jump():
	# Normal Jump / for all jumps
	%CameraAnimationPlayer.play("jump")
	jumping = true
	velocity.y = jump_velocity
	current_state = MovementState.AIRBORNE
	
	# Slide Jump
	if current_state == MovementState.SLIDING:
		velocity.y += slide_jump_boost * (%Slide_Timer.get_wait_time()-%Slide_Timer.get_time_left())
		%Slide_Timer.stop()
	
	# Wall Jump
	elif is_on_wall_only():
		rotation.y += %Neck.rotation.y
		%Neck.rotation.y = 0.0
		free_looking = false
		move_and_slide()
		direction.x = -transform.basis.z.x
		direction.z = -transform.basis.z.z
		#direction.x = get_slide_collision(0).get_normal().x
		#direction.z = get_slide_collision(0).get_normal().z
		current_speed = wall_jump_velocity
		wall_jumps_left -= 1

func _on_slide_timer_timeout():
	free_looking = false
	# Reset current movement state
	if Input.is_action_pressed("crouch"):
		current_state = MovementState.CROUCHING
	elif Input.is_action_pressed("sprint"):
		current_state = MovementState.SPRINTING
	else:
		current_state = MovementState.RUNNING

func respawn():
	position = last_stable_ground
	velocity = Vector3.ZERO
	direction = Vector3.ZERO
