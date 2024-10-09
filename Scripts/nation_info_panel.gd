extends Panel
class_name NationInfoPanel
var nation : Nation
@onready var nameLabel : Label = $"NationName"
@onready var popLabel : Label = $"NationPop"
@onready var techLabel : Label = $"NationTech"
@onready var sizeLabel : Label = $"NationSize"
@onready var manpowerLabel : Label = $"NationManpower"
@onready var troopLabel : Label = $"NationTroops"
@onready var enemyLabel : Label = $"NationEnemies"

var mouseHover : bool
var newPos : Vector2
var dragging : bool
func _process(delta: float) -> void:
	if !nation:
		hide()
	else:
		show()
		displayNationInfo()

func getNationInfo(newNation : Nation):
	nation = newNation

func displayNationInfo():
	nameLabel.text = nation.nationName
	popLabel.text = "Population: " + str(nation.population) + "/" + str(nation.integratedPop) 
	techLabel.text = "Tech: " + str(nation.techLevel) 
	sizeLabel.text = "Size: " + str(nation.tiles.size()) + " Tiles"
	manpowerLabel.text = "Manpower: " + str(nation.manpower) + "/" + str(nation.maxManpower)
	troopLabel.text = "Troops: " + str(nation.troops)
	enemyLabel.text = "Enemies: " + formatEnemies()

func formatEnemies() -> String:
	if nation.enemies.size() < 1:
		return "None"
	
	var string : String
	for enemy in nation.enemies:
		string += enemy.nationName + ", "
	return string

func format(value : int):
	var text = ""
	while value >= 1000:
		text += ",%03d" % (value % 1000)
		value /= 1000
	return str(value) + text

func _physics_process(delta: float) -> void:
	var velocity : Vector2
	if dragging:
		velocity = (newPos - position) * Vector2(30,-30)
		position += velocity

func _on_mouse_entered() -> void:
	mouseHover = true


func _on_mouse_exited() -> void:
	mouseHover = false


func _on_gui_input(event: InputEvent) -> void:
	var dragDist : float
	var dir : Vector2
	if event is InputEventMouse:
		if event.is_pressed() && mouseHover:
			dragDist = position.distance_to(get_viewport().get_mouse_position())
			dir = (get_viewport().get_mouse_position() - position).normalized()
			
			dragging = true
			newPos = get_viewport().get_mouse_position() - dragDist * dir
		else:
			dragging = false
	elif event is InputEventMouse:
		if dragging:
			newPos = get_viewport().get_mouse_position() - dragDist * dir
