extends ColorRect

@onready var resumeButton = $PauseMenuVbox/Resume
@onready var quitButton = $PauseMenuVbox/Quit
@onready var player = $"/root/World/Player"
@export var deathScreen :ColorRect

func _ready():
	quitButton.visible = true
	resumeButton.visible = true
	visible = false

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		if visible == false:
			if deathScreen.visible == true:
				deathScreen.visible = false
			visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			_on_resume_pressed()
	elif Input.is_action_just_pressed("respawn"):
		if deathScreen.visible == true:
			get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()


func _on_resume_pressed():
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if player.dead == true:
		deathScreen.visible = true
