extends CharacterBody3D

var health = 100
var dead = false
var speed = 6

#AI
var turnInterval : Vector2 = Vector2(3,9)		#how long to wait before turning, Vector2(x = minimum time, y = maximum time)
var turnTimer = 0
var walkLength : Vector2 = Vector2(2, 6)		#how long to walk for, Vector2(x = minimum time, y = maximum time)
var walkTimer = 0
var standLength : Vector2 = Vector2(2, 5)		#how long to stand for after walking, Vector2(x = minimum time, y = maximum time)
var standTimer = 0
var turningAround = false
var target
var state = "roaming"		#ai behavior state, can be "roaming" or "targeting"

#func _on_body_entered(body):
	#if body.is_in_group("Player"):
		#body.damage()

func _ready():
	randomize()
	turnTimer = randf_range(turnInterval.x, turnInterval.y)
	walkTimer = randf_range(walkLength.x, walkLength.y)
	state = "roaming"

func damage(dmg : float):
	if dead == false:
		health -= dmg
		if health <= 0:
			health = 0
			dead = true
			die()

func die():
	$human.visible = false
	set_collision_layer_value(1, false)

func _process(delta):
	if dead == false:
		if state == "roaming":
			roam(delta)
		elif state == "targeting":
			targeting(delta)

func targeting(delta):
	#var direction = (target.position - position).normalized()
	#velocity.x = direction.x * speed
	#velocity.z = direction.z * speed
	look_at(Vector3(target.global_position.x, self.global_position.y, target.global_position.z), Vector3.UP)
	rotation_degrees.y += 180
	walk()
	if target.dead == true:
		state = "roaming"

func roam(delta):
	if $EdgeRayCast.is_colliding() == true && $WallRayCast.is_colliding() == false && $FrontArea.has_overlapping_bodies() == false && turningAround == false:
		if turnTimer > 0:				#timer counts down until 0, then calls turn()
			turnTimer -= delta
			if turnTimer <= 0:
				turnTimer = 0
				turn()
				
		if walkTimer > 0:				#timer counts down until 0, and calls walk() until then
			walkTimer -= delta
			if walkTimer <= 0:
				walkTimer = 0
				#velocity = Vector3(0,0,0)
				standTimer = randf_range(standLength.x, standLength.y)
			else:
				walk()
		elif standTimer > 0:				#timer counts down until 0, and calls walk() until then
			standTimer -= delta
			if standTimer <= 0:
				standTimer = 0
				walkTimer = randf_range(walkLength.x, walkLength.y)
	elif turningAround == false:
		turningAround = true
		var turnDegrees = randf_range(100, 180)
		if randi_range(0,1) == 1:
			turnDegrees *= -1
		var tween = get_tree().create_tween()
		tween.tween_property(self, "rotation_degrees:y", turnDegrees, 1).as_relative()
		tween.tween_callback(endTurnAround)

func endTurnAround():
	turningAround = false

func turn():
	var turnDegrees = randf_range(20, 100)
	if randi_range(0,1) == 1:
		turnDegrees *= -1
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees:y", turnDegrees, 1).as_relative()
	turnTimer = randf_range(turnInterval.x, turnInterval.y) + 1					#plus 1 to account for time spent turning
	

func walk():
	var direction = global_transform.basis.z.normalized()
	velocity = direction * speed
	move_and_slide()


func _on_damage_area_body_entered(body):
	print("enemy body entered")
	if body.is_in_group("Player"):
		body.damage()


func _on_view_body_entered(body):
	if body.is_in_group("Player"):
		print("targeting")
		target = body
		state = "targeting"
