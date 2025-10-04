extends VBoxContainer

@onready var resumeButton = $Resume
@onready var quitButton = $Quit

func _ready():
	quitButton.visible = true
	resumeButton.visible = true
	visible = false

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		if visible == false:
			visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			_on_return_pressed()

func _on_return_pressed():
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_quit_pressed():
	get_tree().quit()
