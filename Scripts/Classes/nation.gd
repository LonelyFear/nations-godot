extends Node
class_name Nation

var nationName : String
var nationColor : Color = Color.RED
var population : int = 0
var manpower : int = 0
var maxManpower : int = 0
var troops : int = 0
var tiles : Array[Tile]
var capital : Tile = null
var updatingTiles = {}
var borderingNations : Array[Nation]
var integratedPop : int = 0

var techLevel : int = 0
var allNations = {}

var enemies : Array[Nation]

func createRandomNation() -> Nation:
	var newNation : Nation = Nation.new()
	newNation.nationColor = Color8(randi_range(1,230), randi_range(1,230), randi_range(1,230))
	var nationNames : Array[String] = ["Fearian", "Korlandian", "Zaristian", "Welikoslavian", "Imperian", "Saxonian", "Angilan", "Zeppalian", "Rossyan", "Dervish", "Tali", "Owuxan", "Skorvese", "Sinuep Snea", "United", "Arctursean"]
	var nationSuffixes : Array[String] = ["Kingdom", "Republic", "Empire", "Commune", "State", "Federation", "Order", "States"]
	newNation.nationName = nationNames[randi_range(0, nationNames.size() - 1)] + " " + nationSuffixes[randi_range(0, nationSuffixes.size() - 1)] 
	newNation.techLevel = randi_range(1,10)
	return newNation

func dayUpdate():
	updateEnemies()
	if tiles.size() > 0:
		#calcMaxMp()
		if !capital || capital.nation != self:
			capital = changeCapital()
		borderRelationDecay()
		declareWar()
		manpowerUpdate()
		if enemies.size() > 0 && manpower > 0:
			reinforceTiles()


func manpowerUpdate():
	var mpIncrease = randi_range(10,200)
	if (manpower + mpIncrease) + troops > maxManpower:
		mpIncrease = maxManpower - (manpower + troops)
	if mpIncrease < 0:
		mpIncrease = 0
	manpower += mpIncrease
	if (manpower + troops > maxManpower):
		manpower = maxManpower - troops
	if (manpower < 1):
		manpower = 0

func sortByTroops(a, b):
	if a.troops < b.troops:
		return true
	return false

func changeCapital() -> Tile:
	var attempts : int = 0
	var capitalCanditate : Tile = tiles.pick_random()
	while attempts < 10:
		attempts += 1
		if capitalCanditate.integration >= 1:
			return capitalCanditate
		else:
			capitalCanditate = tiles.pick_random()
	return capitalCanditate

func reinforceTiles():
	tiles.sort_custom(sortByTroops)
	for tile : Tile in tiles:
		if !tile.border:
			pass
		for enemy in enemies:
			if tile.borderingNations.has(enemy):
				var deploymentSize : int = 10
				if manpower > deploymentSize && tile.troops <= 2000 && troops + deploymentSize <= maxManpower:
					manpower -= deploymentSize
					tile.troops += deploymentSize
					
					pass
			else:
				pass

func borderRelationDecay():
	if borderingNations.size() > 0:
		for nation in allNations:
			if borderingNations.has(nation) && randf_range(0,100) < 1 && !allNations[nation].ally && !allNations[nation].enemy:
				allNations[nation].opinion -= 1

func declareWar():
	for nation : Nation in allNations:
			var relations : Relations = allNations[nation]
			if borderingNations.has(nation) && !allNations[nation].enemy && relations.opinion < -10 && randf_range(0,100) < 1 + (abs(relations.opinion + 10) * 0.25):
				relations.enemy = true
	updateEnemies()

func updateEnemies():
	if !tiles.size() > 0:
		for nation : Nation in allNations:
			var relations : Relations = allNations[nation]
			relations.enemy = false
			nation.allNations[self].enemy = false
			enemies.erase(nation)
	
	for nation : Nation in allNations:
		var relations : Relations = allNations[nation]
		# Fixing us being at war and them not
		nation.allNations[self].enemy = relations.enemy
		# Fixing own enemies
		if relations.enemy && !enemies.has(nation):
			enemies.append(nation)
		if !relations.enemy && enemies.has(nation):
			enemies.erase(nation)


func monthUpdate():
	pass

func removeTile(tile : Tile):
	population -= tile.population
	if tile.integration >= 1:
		integratedPop -= tile.population
		calcMaxMp()
	tiles.erase(tile)

func addTile(tile : Tile):
	if !tiles.has(tile):
		tiles.append(tile)
		population += tile.population
		if tile.integration >= 1:
			integratedPop += tile.population
			calcMaxMp()

func getAllNations():
	if tiles.size() > 0:
		var tile = tiles[0]
		var worldgen : Worldgen = tile.get_parent()
		if worldgen:
			for nation in worldgen.nations:
				if nation != self:
					if !allNations.has(nation):
						allNations[nation] = Relations.new()
					elif allNations[nation] == null:
						allNations[nation] = Relations.new()

func getBorders():
	borderingNations.clear()
	for tile : Tile in tiles:
		for nation in tile.borderingNations:
			if !borderingNations.has(nation) && nation:
				borderingNations.append(nation)
	#for nation in borderingNations:
	#	print(nation.nationName)

func changePop(amount : int):
	while amount > 0:
		for tile in tiles:
			var change = randi_range(0, amount / 4)
			tile.changePopulation(change)

func recalcPop(newTile : bool = false):
	#var newPop : int = 0
	#integratedPop = 0
	#if tiles:
	#	for tile in tiles:
	#		newPop += tile.population
	#		integratedPop += tile.population * tile.integration
	#population = newPop
	#maxManpower = round(integratedPop * 0.05)
	for tile : Tile in updatingTiles:
		if !newTile:
			population -= updatingTiles[tile][0]
		
		population += tile.population
		if tile.integration >= 1:
			integratedPop += tile.population
		
		calcMaxMp()
		updatingTiles.erase(tile)

func calcMaxMp():
	maxManpower = integratedPop * 0.05
func recalcArmies():
	troops = 0
	if tiles:
		for tile in tiles:
			if tile.troops > 0:
				troops += tile.troops
