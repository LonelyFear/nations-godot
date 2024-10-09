extends Node2D
class_name Worldgen
var noise : FastNoiseLite = FastNoiseLite.new()

var worldSize : Vector2 = Vector2(144,81)
var tileScale : float = 2

var heightMap = {}
var rocks = {}
var boulders = {}
var terrain = {}

var tileMap = {}
var nations : Array[Nation]
var UILayer : CanvasLayer
var timeSystem : TimeSystem
signal worldgenFinished
signal nationCountUpdate

func _ready() -> void:
	UILayer = get_parent().find_child("UILayer")
	timeSystem = get_parent().find_child("TimeSystem")
	startWorldGen()
	connectTiles()
	addRandomNations(10)
	worldgenFinished.emit()

func startWorldGen():
	var nationCount = 5
	heightMap = addNoiseMaps([createNoiseMap(), createNoiseMap(), createNoiseMap(FastNoiseLite.TYPE_VALUE)])
	worldSize = round(worldSize/tileScale)
	for x in worldSize.x:
		for y in worldSize.y:
			
			var newTile : Tile = preload("res://Scenes/tile.tscn").instantiate()
			newTile.position = Vector2(x + 0.5,y + 0.5) * (tileScale * 8)
			newTile.scale = Vector2(tileScale,tileScale)
			var tileHeight = round(heightMap[Vector2(x,y)] * 8.5) - 1
			newTile.height = clamp(tileHeight, 1, 5) - 1
			newTile.tileDict = tileMap
			newTile.tilePos = Vector2(x,y)
			
			if timeSystem:
				timeSystem.daySignal.connect(newTile.dayUpdate)
				timeSystem.monthSignal.connect(newTile.monthUpdate)
				
			if newTile.height < 1:
				newTile.ocean = true
			add_child(newTile)
			tileMap[Vector2(x,y)] = newTile
	

func connectTiles():
	for tilePos in tileMap:
		var tile : Tile = tileMap[tilePos]
		tile.tileDict = tileMap
		worldgenFinished.connect(tile.tileInit)
		var nationInfo : NationInfoPanel = UILayer.find_child("NationInfo")
		if nationInfo:
			tile.sendNation.connect(nationInfo.getNationInfo)
			tile.nationInfo = nationInfo

func addRandomNations(amount : int):
	for i in amount:
		var testedPos = Vector2(randi_range(0, worldSize.x - 1), randi_range(0, worldSize.y - 1))
		while !tileMap[testedPos] || tileMap[testedPos].nation || tileMap[testedPos].ocean:
			testedPos = Vector2(randi_range(0, worldSize.x - 1), randi_range(0, worldSize.y - 1))
		var newNation : Nation = Nation.new().createRandomNation()
		if timeSystem:
			timeSystem.daySignal.connect(newNation.dayUpdate)
			#timeSystem.monthSignal.connect(newNation.monthUpdate)
		
		tileMap[testedPos].changeNation(newNation, true)
		nations.append(newNation)
	
	for nation in nations:
		nation.getAllNations()

func _process(delta: float) -> void:
	for nation in nations:
		if nation.tiles.size() < 1:
			for enemy : Nation in nation.enemies:
				enemy.allNations[nation].enemy = false
				#enemy.updateEnemies()
			nations.erase(nation)
			for n in nations:
				n.getAllNations()

func addNoiseMaps(maps : Array) -> Dictionary:
	rocks = createNoiseMap(FastNoiseLite.TYPE_VALUE)
	boulders = createNoiseMap()
	terrain = createNoiseMap()
	
	var mergedMap = {}
	for x in worldSize.x:
		for y in worldSize.y:
			var pos = Vector2(x,y)
			mergedMap[pos] = (rocks[pos] * 0.3) + (boulders[pos] * 0.3) + (terrain[pos] * 0.4)
	return mergedMap

func createNoiseMap(noiseType := noise.TYPE_PERLIN, octaves := 8) -> Dictionary:
	# Seed 45 is the baltics
	noise.seed = 45
	noise.noise_type = noiseType
	noise.fractal_octaves = octaves
	
	var noiseMap = {}
	for x in worldSize.x:
		for y in worldSize.y:
			var noiseValue = 2*(abs(noise.get_noise_2d(x,y)))
			noiseMap[Vector2(x,y)] = noiseValue
	return noiseMap
