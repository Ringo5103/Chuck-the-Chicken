extends Area3D

@export var value : int = 100
@export var reset_time : float = 180	#in seconds
var reset_timer : float = 0
var disappearing = false
var disappeared = false
@onready var player = $"/root/World/Player"

func _on_body_entered(body: Node3D):
	if disappearing == false && disappeared == false:
		if body.is_in_group("Player"):
			pickUpRing()

func pickUpRing():
	player.pickUpRing(value)
	disappearing = true

func _process(delta):
	if disappearing == true && disappeared == false:
		scale -= Vector3(delta,delta,delta)*5
		if scale.x <= 0.025:
			disappeared = true
			disappearing = false
			visible = false
	elif disappeared == true && disappearing == false:
		if reset_timer < reset_time:
			reset_timer += delta
			if reset_timer >= reset_time:
				visible = true
		else:
			scale += Vector3(delta,delta,delta)*5
			if scale.x >= 1:
				disappeared = false
				disappearing = false
				scale = Vector3(1, 1, 1)
				reset_timer = 0
