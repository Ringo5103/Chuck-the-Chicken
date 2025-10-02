extends CharacterBody3D
@export var SPEED = 5		#default is 3
@export var JUMP_VELOCITY = 10

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.3
var equipped = null
var aimSensitivity : float = 1
var sensitivityMult : float = 2.5
var kills = 0
var lastKills = kills
var knockbackMultiplier
var dying = false
var spinning = false
var dead = false
var crouched = false
const identity = "Player"
var rings : int = 0
var rng = RandomNumberGenerator.new()
var lastRings : int = rings
var spawnPoint
var defaultRotation
var defaultRotationHead
var defaultRotationCamera
var defaultWeaponHolderPos : Vector3
var mouseInput : Vector2
var reloading = false
var running = false
var zoomed = false
var zoom = 0
var unzoom = 0
var equippedWeapon
var health = 100
var id = 10000
var interactSelected = 0
var interactMenuOpen = false
var controllable = true

var doubleJumped = false
var doubleJumpCooldown = 3
var doubleJumpCooldownTimer : float = 0

@export var runSpeedMult : float = 1
@export var reachDistance = 2
@export var raycast : Node3D
@export var head : Node3D
@export var camera : Node3D
@export var weaponHolder : Node3D
@export var raycastHolder : Node3D
@export var crosshairLabel : Node3D
@export var crosshairLabelAbove : Node3D
@export var crosshairLabelBelow : Node3D
@export var yRotation : Node3D
@export var ringLabel : Control

func _ready():
	spawnPoint = global_transform
	defaultRotation = global_rotation
	defaultRotationHead = head.global_rotation
	defaultRotationCamera = camera.global_rotation
	defaultWeaponHolderPos = weaponHolder.position
	ringLabel.text = str(rings)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if Input.is_action_just_pressed("suicide"):
		die()

	#	if Input.is_action_just_pressed("debug1"):
	#		trippylaugh()

	if Input.is_action_just_pressed("run"):
		if zoomed == false:
			running = true
#			$Head/CameraAnimator.play("sprint")
	elif Input.is_action_just_released("run"):
		if running == true:
			running = false
#			$Head/CameraAnimator.play_backwards("sprint")

	if Input.is_action_just_pressed("crouch"):
		if crouched == false:
			$AnimationPlayer.play("crouch")
			crouched = true
		else:
			$AnimationPlayer.play_backwards("crouch")
			crouched = false

#	if Input.is_action_just_pressed("aim"):
#		startAim()
#	elif Input.is_action_just_released("aim"):
#		stopAim()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if zoomed == false:
				yRotation.rotate_y(-event.relative.x * 0.005 * (aimSensitivity * sensitivityMult))
				head.rotate_x(-event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
				mouseInput = event.relative
			elif zoomed == true:
				rotate_y(-event.relative.x * 0.005 * (.1 * aimSensitivity * sensitivityMult))
				head.rotate_x(-event.relative.y * 0.005 * (.1 * aimSensitivity * sensitivityMult))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

				raycastHolder.rotate_x(-event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
				raycast.rotate_y(-event.relative.x * 0.005 * (aimSensitivity * sensitivityMult))
				if equippedWeapon:
					equippedWeapon.rotate_y(-event.relative.x * 0.005 * (aimSensitivity * sensitivityMult))
					if equippedWeapon.aimRotation == "x":
						equippedWeapon.model.rotate_x(-event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
					elif equippedWeapon.aimRotation == "-x":
						equippedWeapon.model.rotate_x(event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
					elif equippedWeapon.aimRotation == "z":
						equippedWeapon.model.rotate_z(-event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
					elif equippedWeapon.aimRotation == "-z":
						equippedWeapon.model.rotate_z(event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if controllable == true:
#		getInteraction()

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (yRotation.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var moveSpeed = SPEED
		if running == true:
			moveSpeed *= runSpeedMult
		if direction:
			if is_on_floor():
				$Chuck2.rotation.y = yRotation.rotation.y + -input_dir.angle() + deg_to_rad(270)
			velocity.x = direction.x * moveSpeed
			velocity.z = direction.z * moveSpeed
		else:
			velocity.x = move_toward(velocity.x, 0, moveSpeed)
			velocity.z = move_toward(velocity.z, 0, moveSpeed)
		if (direction != Vector3(0.0, 0.0, 0.0)) && ($AnimationPlayer.is_playing() == false) && (is_on_floor() == true):
			print("Walk")
			$AnimationPlayer.play("Walk")
			$AnimationPlayer.speed_scale = 2
		elif direction == Vector3(0.0, 0.0, 0.0) && $AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "Walk":
			$AnimationPlayer.stop()
			$AnimationPlayer.speed_scale = 1
		if !is_on_floor() && $AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "Walk":
			$AnimationPlayer.stop()
		move_and_slide()
		
		# Handle jump.
		if Input.is_action_just_pressed("jump") and (is_on_floor() || doubleJumped == false):
			if !is_on_floor() && doubleJumped == false:
				doubleJumped = true
				$Chuck2.rotation.y = yRotation.rotation.y + -input_dir.angle() + deg_to_rad(270)
				#doubleJumpCooldownTimer = doubleJumpCooldown
			velocity.y = JUMP_VELOCITY
		if is_on_floor() && doubleJumped == true:
			doubleJumped = false

		if unzoom == 1:
			raycastHolder.rotation.x = lerp(raycastHolder.rotation.x, 0.0, 10 * delta)
			raycast.rotation.y = lerp(raycast.rotation.y, 0.0, 10 * delta)
			if raycastHolder.rotation.x < 0.001 && raycast.rotation.y < 0.001:
				unzoom = -1
				raycastHolder.rotation.x = 0
				raycast.rotation.y = 0
		if unzoom < 0:
			unzoom += delta * 5
			if unzoom >= 0:
				unzoom = 0
				mouseInput = Vector2.ZERO

#		if zoomed == false && unzoom == 0:
#			#raycastHolder.rotation.x = lerp(raycastHolder.rotation.x, 0.0, 10 * delta)
#			#raycast.rotation.y = lerp(raycast.rotation.y, 0.0, 10 * delta)
#
#			CamTilt(input_dir.x, delta)
#			weaponTilt(input_dir.x, delta)
#			weaponSway(delta)
#			weaponBob(velocity.length(), delta)
			
func _process(delta):
	#$"/root/World/SubViewportContainer/SubViewport/PlayerCam2".global_transform = camera.global_transform

#	if (Input.is_action_just_pressed("scroll up") || Input.is_action_just_pressed("scroll down")) && reloading == false && interactMenuOpen == false:		#change weapon begin
#		changeWeapons()
	#if doubleJumpCooldownTimer > 0:
		#doubleJumpCooldownTimer -= delta
		#if doubleJumpCooldownTimer <= 0:
			#doubleJumped = false
			#doubleJumpCooldownTimer = 0

	if spinning == true:
		head.rotation_degrees.y += 25

	if kills > lastKills:
		print(kills)
	lastKills = kills

	if lastRings != rings:
		ringLabel.text = str(rings)
	lastRings = rings

#	if equippedWeapon == null:
#		crosshair.visible = false
#	elif equippedWeapon.readied == true:
#		crosshair.visible = true

func die():
	#dying = true
	#get_tree().reload_current_scene()
	$AnimationPlayer.play("Die")

func respawn():
	Global.totalKills += kills
	Global.prevKills = kills
	get_tree().change_scene_to_file("res://scenes/death.tscn")
	#get_tree().reload_current_scene()

func getInteraction():
	var distanceTo = raycast.global_transform.origin.distance_to(raycast.get_collision_point())
	crosshairLabel.text = ""
	crosshairLabelBelow.text = ""
	crosshairLabelAbove.text = ""
	crosshairLabelBelow.get_children()[0].visible = false
	crosshairLabelAbove.get_children()[0].visible = false
	interactMenuOpen = false
	if zoomed == false && raycast.is_colliding() && distanceTo <= reachDistance:			#interact
		var collider = raycast.get_collider()
		if collider != null:
			if collider.is_in_group("Interactable"):
				var interact = collider.interactText
				var key = InputHelper.get_keyboard_or_joypad_input_for_action("interact")
				var keyText
				if key is InputEventKey:
					keyText = key.as_text()
					if keyText.contains(" (Physical)"):
						keyText = keyText.replace(" (Physical)", "")
				elif key is InputEventMouseButton:
					keyText = "Mouse " + str(key.button_index)
				var pressText = "Press " + keyText + " to "

				if interact is String:
					crosshairLabel.text = pressText + interact
					crosshairLabelBelow.text = ""
					crosshairLabelAbove.text = ""
					if Input.is_action_just_pressed("interact"):
						collider.interact()
				elif interact is Array:
					interactMenuOpen = true
					if interact.size() < 3:
						crosshairLabel.text = pressText + interact[0]
						if Input.is_action_just_pressed("interact up") || Input.is_action_just_pressed("scroll up"):
							print(interactSelected)
							if interactSelected < interact.size()-1:
								interactSelected += 1
							else:
								interactSelected = 0
						elif Input.is_action_just_pressed("interact down") || Input.is_action_just_pressed("scroll down"):
							print(interactSelected)
							if interactSelected > 0:
								interactSelected -= 1
							else:
								interactSelected = interact.size()-1
						if interactSelected == 0:
							crosshairLabel.text = pressText + interact[0]
							crosshairLabelBelow.text = pressText + interact[1]
							crosshairLabelBelow.get_children()[0].visible = true
							crosshairLabelAbove.text = ""
							crosshairLabelAbove.get_children()[0].visible = false
						elif interactSelected == 1:
							crosshairLabel.text = pressText + interact[1]
							crosshairLabelAbove.text = pressText + interact[0]
							crosshairLabelAbove.get_children()[0].visible = true
							crosshairLabelBelow.text = ""
							crosshairLabelBelow.get_children()[0].visible = false
					if Input.is_action_just_pressed("interact"):
						collider.interact(interactSelected)

func pickUpRing(value : float):
	rings += value
	$RingSound.play()

func damage():
	die()
