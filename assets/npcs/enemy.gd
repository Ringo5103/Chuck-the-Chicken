extends RigidBody3D

var health = 100
var dead = false

#func _on_body_entered(body):
	#if body.is_in_group("Player"):
		#body.damage()

func _ready():
	set_contact_monitor(true)
	max_contacts_reported = 3

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


func _on_body_entered(body):
	print("enemy body entered")
	if body.is_in_group("Player"):
		body.damage()
