extends Node3D

@onready var shootSound = preload("res://player/gun/FiveSeveN_Shoot_003.wav")
@onready var arm = $"../../../.."
var tween

func shoot():
	$AudioStreamPlayer.stream = shootSound
	$AudioStreamPlayer.play()
	var tween = get_tree().create_tween()
	tween.tween_property(arm, "rotation_degrees:z", -7.9, .1).as_relative()
	tween.tween_property(arm, "rotation_degrees:z", 7.9, .1).as_relative()
