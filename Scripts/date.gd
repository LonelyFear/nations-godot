extends Label

var timeSystem : TimeSystem

func _ready() -> void:
	timeSystem = get_parent().get_parent().find_child("TimeSystem")

func _process(delta: float) -> void:
	text = ""
	if timeSystem:
		var dayText : String = "%02d" % timeSystem.day
		var monthText : String = "%02d" % timeSystem.month
		var yearText : String = str(timeSystem.year)
		text = "%s/%s/%s" % [dayText,monthText,yearText]
