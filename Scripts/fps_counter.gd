extends Label

@export var frameCounter : float
@export var timeCounter : float
@export var lastFramerate : float
@export var refreshTime : float = 0.5

func _process(delta: float) -> void:
	if timeCounter < refreshTime:
		timeCounter += delta
		frameCounter += 1
	else:
		lastFramerate = frameCounter/timeCounter;
		frameCounter = 0
		timeCounter = 0.0
	text = "FPS: " + str(roundi(lastFramerate))
