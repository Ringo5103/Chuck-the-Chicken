extends CharacterBody3D
@export var SPEED = 5		#default is 3
@export var JUMP_VELOCITY = 9

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.5
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
var aiming = false
var zoom = 0
var unzoom = 0
var equippedWeapon
var health = 100
var id = 10000
var interactSelected = 0
var interactMenuOpen = false
var controllable = true

var timeSinceJump : float = 0
var doubleJumped = false
var doubleJumpCooldown = 3
var doubleJumpCooldownTimer : float = 0
var jumpedRotation 
var prevYRot : float
var velocityAdditions : Vector3 = Vector3(0.0, 0.0, 0.0)
var dashDuration : float = 2 #dash duration in seconds
var dashTimer : float = 0
var dashMoveModifier = 0
var damaged = false
@onready var dashVelocity = JUMP_VELOCITY / 2
@onready var ring = preload("res://assets/environment/rings/dropped_ring.tscn")
@onready var worldRings = $"/root/World/Rings"
var dropRingsTimer = 0

@export var runSpeedMult : float = 2
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
@export var gunArm : Node3D
@export var gun : Node3D
@export var deathScreen : ColorRect

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
	if dead == false:
		if Input.is_action_just_pressed("run"):
			if aiming == false:
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

		if Input.is_action_just_pressed("aim"):
			startAim()
			print("aim")
		elif Input.is_action_just_released("aim"):
			stopAim()

		if Input.is_action_just_pressed("shoot"):
			shoot()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if aiming == false:
				yRotation.rotate_y(-event.relative.x * 0.005 * (aimSensitivity * sensitivityMult))
				head.rotate_x(-event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
				mouseInput = event.relative
			elif aiming == true:
				yRotation.rotate_y(-event.relative.x * 0.005 * (aimSensitivity * sensitivityMult))
				var prevHeadX = head.rotation.x
				head.rotate_x(-event.relative.y * 0.005 * (aimSensitivity * sensitivityMult))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
				mouseInput = event.relative
				#if prevHeadX != head.rotation.x:
					#gunArm.rotation.z += prevHeadX - head.rotation.x
				gunArm.rotation_degrees.z = -head.rotation_degrees.x - 65


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if controllable == true:
#		getInteraction()

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction
		var moveSpeed = SPEED
		if timeSinceJump > 0:
			timeSinceJump += delta
		if dashTimer > 0:
			dashTimer -= delta
			dashMoveModifier = dashVelocity * dashTimer
			if damaged == true:
				dashMoveModifier *= -1
			if dashTimer <= 0:
				dashTimer = 0
				dashMoveModifier = 0
				damaged = false
		
		#if aiming == false:
		if damaged == false && dead == false:
			direction = (yRotation.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		elif damaged == true:
			direction = yRotation.transform.basis.z
		else:
			direction = null
	
		if doubleJumped == true:
			$Chuck2.rotation.y = yRotation.rotation.y
		elif direction:
			$Chuck2.rotation.y = yRotation.rotation.y + -input_dir.angle() + deg_to_rad(270)
	
		if running == true:
			moveSpeed *= runSpeedMult
		if direction:
			#if is_on_floor():
			#else:
				#if yRotation.rotation.y != prevYRot:
					#var rotChange = yRotation.rotation.y - prevYRot
					#$Chuck2.rotation.y += rotChange
			velocity.x = direction.x * moveSpeed
			velocity.z = direction.z * moveSpeed
		else:
			velocity.x = move_toward(velocity.x, 0, moveSpeed)
			velocity.z = move_toward(velocity.z, 0, moveSpeed)
		
		if dead == false:
			var dashDirection = -$Chuck2.global_transform.basis.z.normalized()
			#if !($AnimationPlayer.is_playing() == true && $AnimationPlayer.current_animation == "Shoot"):
			velocity += dashDirection * dashMoveModifier
		move_and_slide()
		if aiming == false:
			if direction != Vector3(0.0, 0.0, 0.0) && is_on_floor() == true:		#if on the floor and moving, do walk or run animation
				if $AnimationPlayer.is_playing() == false:
					if running == true:
						$AnimationPlayer.play("Run_2")
					else:
						$AnimationPlayer.play("Walk")
				elif $AnimationPlayer.current_animation == "Walk" && running == true:
						$AnimationPlayer.play("Run_2")
				elif $AnimationPlayer.current_animation == "Run_2" && running == false:
						$AnimationPlayer.play("Walk")
			elif direction == Vector3(0.0, 0.0, 0.0) && $AnimationPlayer.is_playing() && ($AnimationPlayer.current_animation == "Walk" || $AnimationPlayer.current_animation == "Run_2"):		#if not moving and animation "walk" or "run" is playing
				$AnimationPlayer.play("RESET")
			if !is_on_floor() && $AnimationPlayer.is_playing() && ($AnimationPlayer.current_animation == "Walk" || $AnimationPlayer.current_animation == "Run_2"):		#if not on the floor and animation "walk" or "run" is playing
				$AnimationPlayer.play("RESET")
			#if is_on_floor() && ($AnimationPlayer.current_animation == "DoubleJump" || $AnimationPlayer.current_animation == "Jump") && $AnimationPlayer.is_playing():
				#$AnimationPlayer.play("RESET")
			
			#move_and_slide()
			# Handle jump.
			if dead == false:
				if Input.is_action_just_pressed("jump") and (is_on_floor() || doubleJumped == false):
					if !is_on_floor() && doubleJumped == false:
						doubleJumped = true
						$AnimationPlayer.play("DoubleJump")
						#velocity.z -= JUMP_VELOCITY * 2
						dashTimer = dashDuration
						#$Chuck2.rotation.y = yRotation.rotation.y + -input_dir.angle() + deg_to_rad(270)
						#doubleJumpCooldownTimer = doubleJumpCooldown
					else:
						$AnimationPlayer.play("Jump")
					timeSinceJump += delta
					velocity.y += JUMP_VELOCITY
					jumpedRotation = $Chuck2.rotation.y
				if is_on_floor():					#reset after landing
					damaged = false
					dashTimer = 0
					dashMoveModifier = 0
					if doubleJumped == true:		#reset after double jump
						$AnimationPlayer.play("RESET")
						print("touched ground after double jump")
						doubleJumped = false
						timeSinceJump = 0
						jumpedRotation = null
					elif timeSinceJump >= 0.05:		#reset after single jump
						$AnimationPlayer.play("RESET")
						timeSinceJump = 0
						jumpedRotation = null
			else:
				if is_on_floor():					#reset after landing
					damaged = false
					dashTimer = 0
					dashMoveModifier = 0
					if timeSinceJump >= 0.05:
						timeSinceJump = 0
						jumpedRotation = null
		elif dead == false:
			if Input.is_action_just_pressed("jump") and is_on_floor():
				timeSinceJump += delta
				velocity.y += JUMP_VELOCITY
				$AnimationPlayer.play("AimJump")
			if is_on_floor() && timeSinceJump >= 0.05:					#reset after landing
				$AnimationPlayer.play("AimRESET")
				timeSinceJump = 0
				
			if direction != Vector3(0.0, 0.0, 0.0) && is_on_floor() == true:		#if on the floor and moving, do walk or run animation
				if $AnimationPlayer.is_playing() == false:
					$AnimationPlayer.play("AimWalk")
			elif direction == Vector3(0.0, 0.0, 0.0) && $AnimationPlayer.is_playing() && ($AnimationPlayer.current_animation == "AimWalk" || $AnimationPlayer.current_animation == "Run_2"):		#if not moving and animation "walk" or "run" is playing
				$AnimationPlayer.play("AimRESET")
			if !is_on_floor() && $AnimationPlayer.is_playing() && ($AnimationPlayer.current_animation == "AimWalk" || $AnimationPlayer.current_animation == "Run_2"):		#if not on the floor and animation "walk" or "run" is playing
				$AnimationPlayer.play("AimRESET")
		else:
			if is_on_floor():					#reset after landing
				damaged = false
				dashTimer = 0
				dashMoveModifier = 0
				timeSinceJump = 0
				jumpedRotation = null
		
		var zoomModifier = 5
		if Input.is_action_just_pressed("zoom in") && camera.position.z > 1.031:
			camera.position.z -= 0.1 * zoomModifier
			camera.position.y -= 0.0315 * zoomModifier
		elif Input.is_action_just_pressed("zoom out") && camera.position.z < 14.531:
			camera.position.z += 0.1 * zoomModifier
			camera.position.y += 0.0315 * zoomModifier
		
		

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
				

#		if aiming == false && unzoom == 0:
#			#raycastHolder.rotation.x = lerp(raycastHolder.rotation.x, 0.0, 10 * delta)
#			#raycast.rotation.y = lerp(raycast.rotation.y, 0.0, 10 * delta)
#
#			CamTilt(input_dir.x, delta)
#			weaponTilt(input_dir.x, delta)
#			weaponSway(delta)
#			weaponBob(velocity.length(), delta)
			
func _process(delta):
	if prevYRot != yRotation.rotation.y:
		prevYRot = yRotation.rotation.y
	if dropRingsTimer > 0:
		dropRingsTimer -= delta
		if dropRingsTimer <= 0:
			dropRingsTimer = 0
			dropRings()
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

	if aiming == true:
		$Chuck2.rotation.y = yRotation.rotation.y

	if kills > lastKills:
		print("kills: " + str(kills))
	lastKills = kills

	if lastRings != rings:
		ringLabel.text = str(rings)
	lastRings = rings


func die():
	#dying = true
	#get_tree().reload_current_scene()
	#$AnimationPlayer.play("Die")
	$AnimationPlayer.play("Die")
	dead = true
	deathScreen.visible = true

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
	if aiming == false && raycast.is_colliding() && distanceTo <= reachDistance:			#interact
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
							print("interactSelected" + str(interactSelected))
							if interactSelected < interact.size()-1:
								interactSelected += 1
							else:
								interactSelected = 0
						elif Input.is_action_just_pressed("interact down") || Input.is_action_just_pressed("scroll down"):
							print("interactSelected" + str(interactSelected))
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
	velocity.y += JUMP_VELOCITY
	#velocity += dashDirection
	dashTimer = dashDuration
	damaged = true
	timeSinceJump += .001
	if rings > 0:
		$AnimationPlayer.play("Jump")
		dropRingsTimer = .2
	else:
		die()
		#$AnimationPlayer.play("Die")

func dropRings():
	if rings > 0:
		for i in rings:
			rings -= 1
			var dropRing = ring.instantiate()
			worldRings.add_child(dropRing)
			dropRing.global_position = global_position
			dropRing.global_position.y += 1.5

func startAim():
	if aiming == false && is_on_floor() && running == false && !($AnimationPlayer.current_animation == "Aim" && $AnimationPlayer.is_playing()): 		#if not aiming and running, and if aim animation not playing
		$AnimationPlayer.play("Aim")
		aiming = true
		var tween = get_tree().create_tween()
		tween.tween_property(gunArm, "rotation_degrees:z", -head.rotation_degrees.x - 65, .3)

func stopAim():
	#if aiming == true && running == false && !($AnimationPlayer.current_animation == "Aim" && $AnimationPlayer.is_playing()): 		#if not aiming and running, and if aim animation not playing
	if aiming == true && running == false: 		#if not aiming and running, and if aim animation not playing
		$AnimationPlayer.play_backwards("Aim")
		aiming = false
		var tween = get_tree().create_tween()
		tween.tween_property(gunArm, "rotation_degrees:z", 0, .3)

func shoot():
	if aiming == true && !($AnimationPlayer.current_animation == "Aim" && $AnimationPlayer.is_playing()):		#if aiming and aim animation not playing
		if gun.shooting == false:
			#$AnimationPlayer.play("Shoot")
			gun.shoot()
