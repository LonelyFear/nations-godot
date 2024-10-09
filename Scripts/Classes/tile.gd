extends Area2D
class_name Tile

var height : int = 0
var nation : Nation = null
var tileDict = {}
var tilePos : Vector2
var canExpand : bool = false

var border : bool = false
var borderNation : bool = false

# Tile Stats
var population : int
var integratedPop : int
var manpower : int
var maxManpower : int

var troops : int = 0
var ocean : bool = false
var borderingNations : Array[Nation]
var borderingTiles : Array[Tile]
var popGrowthRate : float = 0.01/12
var timeSystem : TimeSystem
@export var tileSprite : Sprite2D

var expanded : bool = false
var integration : float = 0
signal updateBorders
signal sendNation(nation : Nation)

var nationInfo : NationInfoPanel
# Input
var mouseHovering : bool = false

func tileInit():
	timeSystem = get_parent().get_parent().find_child("TimeSystem")
	
	if ocean:
		nation = null
	else:
		addPops()
	
	for x in range(-1,2):
		for y in range(-1,2):
			if Vector2(x,y) == Vector2(0,0):
				pass
			var testedTile : Tile = getBorder(x,y)
			if testedTile && !updateBorders.is_connected(testedTile.onBorderUpdate):
				updateBorders.connect(testedTile.onBorderUpdate)
	onBorderUpdate()
	colorTile()
	if nation:
		changePopulation(0,0,true)

func dayUpdate():
	expanded = false
	if nation:
		if nation.capital == self:
			capitalUpdate()
		
		#print(population)
		intgrateTile()
		if border:
			neutralExpansion()
			if nation.enemies.size() > 0 && troops > 0 && borderNation:
				attackTile(randi_range(-1,1), randi_range(-1,1))
				pass
			if !borderNation || !borderingEnemy():
				demobilizeTroops()
			if borderNation:
				reinforceLine()

func monthUpdate():
	if !ocean:
		#growPop()
		pass

func capitalUpdate():
	pass

func intgrateTile():
	if integration < 1 && randi_range(0,100) < 5:
		integration += 0.1
		if integration >= 1:
			changePopulation()

func demobilizeTroops():
	nation.manpower += troops
	troops = 0
	nation.recalcArmies()

func reinforceLine():
	for border : Tile in borderingTiles:
		if border.nation == nation && border.borderNation && border.troops < 1 && troops > 1:
			border.troops = troops/2
			troops -= troops/2

func borderingEnemy() -> bool:
	for border : Tile in borderingTiles:
		if nation.enemies.has(border.nation):
			return true
	return false
# Warfare
func attackTile(x,y):
	var tile = getBorder(x,y)
	if tile && tile != self && nation.enemies.has(tile.nation) && troops > 0:
		battle(tile)
		#tile.troops -= randi_range(0, 500)
		#troops -= randi_range(0, 500)

func battle(defTile : Tile):
	var defNation : Nation = defTile.nation
	
	if defTile.troops > 0:
		var losses : int = calcLosses(self, defTile, false)
		troops -= losses
		nation.recalcArmies()
		losses = calcLosses(defTile, self, true)
		defTile.troops -= losses
		defNation.recalcArmies()
		if troops < 0:
			troops = 0
		if defTile.troops < 0:
			defTile.troops = 0
	
	# Capturing tile
	if troops > 0 && defTile.troops < 1:
		takeTile(defTile)
		defTile.troops = troops
		troops = 0
	elif troops < 1 && defTile.troops > 0:
		# Counterattacks
		takeTile(self)
		self.troops = defTile.troops
		defTile.troops = 0

func calcLosses(a : Tile, b : Tile, defending : bool) -> int:
	var totalLosses : int
	
	var aTroops = a.troops
	var bTroops = b.troops
	var techDifference : int = a.nation.techLevel - b.nation.techLevel
	for i in bTroops:
		if randi_range(clampi(1 + techDifference, 1, 10), 10)  < 5:
			if nation.capital.integration >= 1:
				totalLosses += 1
			else:
				totalLosses += 2
	# Return 
	if totalLosses < 0:
		totalLosses = 0
	return totalLosses

func onBorderUpdate():
	if borderingTiles.is_empty():
		getBorderingTiles()
	else:
		getBorders()
	if nation:
		nation.getBorders()

func growPop():
	var popFloor = floor(population * popGrowthRate)
	var popB = (population * popGrowthRate) - popFloor
	var totalPopGrowth = popFloor
	if popB < 1:
		if randf() < popB:
			totalPopGrowth += 1
	changePopulation(totalPopGrowth)

func changePopulation(amount : int = 0, newIntegration : float = 0, newTile : bool = false):
	var oldPop = population
	var oldIntegration = integration
	population += amount
	integration += newIntegration
	
	if nation:
		nation.updatingTiles[self] = [oldPop, oldIntegration]
		nation.recalcPop(newTile)
		
func addPops():
	#population = randi_range(50,2000)
	population = 500

func nationUpdate():
	nation.addTile(self)

func getBorders():
	border = false
	borderNation = false
	borderingNations = []
	for x in range(-1,2):
		for y in range(-1,2):
			if Vector2(x,y) == Vector2(0,0):
				pass
			var tile = getBorder(x,y)
			if tile:
				if tile.nation != nation:
					borderingNations.append(tile.nation)
					border = true
					if tile.nation != null:
							borderNation = true
				elif tile.nation == nation:
					pass

func getBorderingTiles():
	borderingTiles = []
	for x in range(-1,2):
		for y in range(-1,2):
			if Vector2(x,y) == Vector2(0,0):
				pass
			if getBorder(x,y):
				borderingTiles.append(getBorder(x,y))

func neutralExpansion():
	for x in range(-1,2):
		for y in range(-1,2):
			if Vector2(x,y) == Vector2(0,0):
				pass
			if randi_range(1,100) < 5:
				neutralExpand(x,y)

func getBorder(x : int = 0, y : int = 0) -> Tile:
	var offset : Vector2 = Vector2(x,y)
	if (tilePos + offset).x >= 0 && (tilePos + offset).x < get_parent().worldSize.x && (tilePos + offset).y >= 0 && (tilePos + offset).y < get_parent().worldSize.y:
		return tileDict[tilePos + offset]
	return null

func changeNation(newNation : Nation, integrated : bool = false):
	if nation:
		nation.removeTile(self)
	if integrated:
		integration = 1
	else:
		integration = 0
	
	nation = newNation
	newNation.addTile(self)
	nationUpdate()
	onBorderUpdate()
	updateBorderingTiles()
	colorTile()

func updateBorderingTiles():
	for tile in borderingTiles:
		tile.getBorders()

func neutralExpand(x : int = 0, y : int = 0):
	var offset : Vector2 = Vector2(x,y)
	var targetTile = getBorder(x,y)
	if (targetTile && !targetTile.ocean && !targetTile.nation):
		takeTile(targetTile, true)

func takeTile(tile : Tile, integrated : bool = false):
	expanded = true
	#tile.supply = 0
	tile.changeNation(nation, integrated)

func _process(delta: float) -> void:
	if detectClick():
		sendNation.emit(nation)
	if tileSprite:
		colorTile()

func colorTile():
	var newColor : Color
	
	if ocean:
		modulate = Color.BLUE
		$"CapitalOverlay".hide()
		return
	
	if !ocean && nationInfo.nation && nationInfo.nation != nation:
		var relations : Relations
		if nation:
			relations = nation.allNations[nationInfo.nation]
		if nation && !relations.enemy:
			newColor = nation.nationColor * 0.5 + Color.BLACK * 0.5
		elif nation && relations.enemy:
			newColor = nation.nationColor * 0.1 + Color.RED * 0.9
		else:
			newColor = Color.WHITE * 0.2 + Color.BLACK * 0.8
	elif !ocean:
		if nation:
			newColor = nation.nationColor
		else:
			newColor = Color.WHITE
	
	# Darkens the borders of empires
	if border && nation && troops < 1:
		newColor = newColor * 0.9 + Color.BLACK * 0.1
	elif border && nation:
		newColor = newColor * 0.5 + Color.BLACK * 0.5
	# Supply color
	#if nation:
	#	newColor = (newColor * (integration)) + ((Color.RED * 0.4 + nation.nationColor * 0.6) * (1 - integration))
	
	if nation && nation.capital == self:
		$"CapitalOverlay".show()
	else:
		$"CapitalOverlay".hide()
	
	tileSprite.modulate = newColor
	#if troops > 0 && nation:
	#	modulate = nation.nationColor
	#else:
	#	modulate = Color.WHITE
	

func detectClick() -> bool:
	if mouseHovering && Input.is_action_just_pressed("Click"):
		return true
	return false

func _on_mouse_entered() -> void:
	mouseHovering = true

func _on_mouse_exited() -> void:
	mouseHovering = false

func nationCountUpdate():
	pass
