extends Node3D

@onready var shootSound = preload("res://player/gun/FiveSeveN_Shoot_003.wav")
@onready var arm = $"../../../.."
@onready var laser = $RayCast3D/MeshInstance3D
var tween
var shooting = false
@onready var raycast = $RayCast3D
@onready var player = $"/root/World/Player"
@export var damage : float = 50
@onready var blood = preload("res://player/gun/blood_splash.tscn")
@export var blood_splash = true
@export var ringCost = 50

func shoot():
	if shooting == false && player.rings >= ringCost:
		player.rings -= ringCost
		if player.rings <= 0:
			laser.visible = false
		$AudioStreamPlayer.stream = shootSound
		$AudioStreamPlayer.play()
		hitscan()
		var tween = get_tree().create_tween()
		tween.tween_property(arm, "rotation_degrees:z", -7.9, .1).as_relative()
		tween.parallel().tween_property(self, "shooting", true, .001)
		tween.tween_property(arm, "rotation_degrees:z", 7.9, .1).as_relative()
		tween.parallel().tween_property(self, "shooting", false, .2)

func _process(delta):
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var cast_point = raycast.global_transform.origin.distance_to(raycast.get_collision_point())
		laser.mesh.height = cast_point
		laser.position.y = -cast_point / 2
	else:
		laser.mesh.height = 100
		laser.position.y = -50
	if player.aiming == true:
		if player.rings >= ringCost:
			laser.visible = true
		else:
			laser.visible = false
	else:
		laser.visible = false

func hitscan():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("NPC"):		#if raycast colliding with an NPC
			if collider.dead == false:
				if blood_splash == true:		#do blood particles
					var splash = blood.instantiate()
					collider.add_child(splash)
					splash.global_position = raycast.get_collision_point()
					splash.emitting = true
				collider.damage(damage)			#damage npc
