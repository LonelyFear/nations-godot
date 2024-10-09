extends Node
class_name TimeSystem

var day : int = 1
var month : int = 1
var year : int = 1800
var dayTime : float = 0.1

signal daySignal
signal monthSignal
signal yearSignal

func _process(delta: float) -> void: 
	dayTime -= delta
	if (dayTime < 0):
		incrementTime()
		#print(str(day) + "/" + str(month) + "/" + str(year))
		dayTime = 0.1

func incrementTime():
	day += 1
	daySignal.emit()
	if (day > 30):
		day = 1
		month += 1
		monthSignal.emit()
		if (month > 12):
			month = 1
			year += 1
			yearSignal.emit()
