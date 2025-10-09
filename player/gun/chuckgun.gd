extends Node3D

@onready var shootSound = preload("res://player/gun/FiveSeveN_Shoot_003.wav")
@onready var arm = $"../../../.."
@onready var laser = $RayCast3D/MeshInstance3D
var tween
var shooting = false
@onready var raycast = $RayCast3D

func shoot():
	if shooting == false:
		$AudioStreamPlayer.stream = shootSound
		$AudioStreamPlayer.play()
		var tween = get_tree().create_tween()
		tween.tween_property(arm, "rotation_degrees:z", -7.9, .1).as_relative()
		tween.parallel().tween_property(self, "shooting", true, .001)
		tween.tween_property(arm, "rotation_degrees:z", 7.9, .1).as_relative()
		tween.parallel().tween_property(self, "shooting", false, .2)

func laserAimToggle():
	laser.visible = !laser.visible

func _process(delta):
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var cast_point = raycast.global_transform.origin.distance_to(raycast.get_collision_point())
		laser.mesh.height = cast_point
		laser.position.y = -cast_point / 2
	else:
		laser.mesh.height = 100
		laser.position.y = -50
