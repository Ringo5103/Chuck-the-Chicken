extends Area3D

var value :int = 100
var disappear = false
@onready var player = $"/root/World/Player"

func _on_body_entered(body: Node3D):
	if disappear == false:
		if body.is_in_group("Player"):
			pickUpRing()

func pickUpRing():
	player.pickUpRing(value)
	disappear = true

func _process(delta):
	if disappear == true:
		scale -= Vector3(delta,delta,delta)*5
		if scale.x <= 0.025:
			queue_free()
