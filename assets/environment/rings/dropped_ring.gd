extends RigidBody3D

@export var value : int = 100
var disappearing = false
var disappeared = false
var pickUpimer = .5
var canPickUp = false
@onready var player = $"/root/World/Player"

func _ready():
	randomize()
	var impulseStrength = randf_range(.5,3.5)
	apply_random_upward_impulse(impulseStrength)

func apply_random_upward_impulse(strength: float):
	# Generate random angles for horizontal components (X and Z)
	var random_angle_xz = randf_range(0, 2 * PI) 
	# Calculate horizontal components
	var x_component = cos(random_angle_xz) * strength
	var z_component = sin(random_angle_xz) * strength
	var y_component = strength * 2 # Upward direction in 3D is positive Y

	var impulse_vector = Vector3(x_component, y_component, z_component)
	apply_central_impulse(impulse_vector)
#
func _on_body_entered(body: Node3D):
	pass
	#if disappearing == false && disappeared == false:
		#if body.is_in_group("Player"):
			#pickUpRing()
#
func pickUpRing():
	player.pickUpRing(value)
	disappearing = true
#
func _process(delta):
	if pickUpimer > 0:
		pickUpimer -= delta
		if pickUpimer <= 0:
			pickUpimer = 0
			canPickUp = true
	
	if disappearing == true && disappeared == false:
		scale -= Vector3(delta,delta,delta) * 5
		if scale.x <= 0.025:
			disappeared = true
			disappearing = false
			visible = false
			queue_free()


func _on_area_3d_body_entered(body):
	if disappearing == false && disappeared == false && canPickUp == true:
		if body.is_in_group("Player"):
			pickUpRing()
