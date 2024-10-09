extends Node2D

@onready var map : TileMapLayer = $"Map"

var noise : FastNoiseLite = FastNoiseLite.new()

var worldSize : Vector2 = Vector2(144,81)

var heightMap = {}

var tilesMap = {}
var rocks = {}
var boulders = {}
var terrain = {}

func _ready() -> void:
	startWorldGen()

func startWorldGen():
	heightMap = addNoiseMaps([createNoiseMap(), createNoiseMap(), createNoiseMap(FastNoiseLite.TYPE_VALUE)])
	for x in worldSize.x:
		for y in worldSize.y:
			var currentTile : Vector2 = Vector2(x,y)
			# Sets map to water
			map.set_cell(currentTile, 1,Vector2i(1,0))
			tilesMap[currentTile] = Tile.new()
			var tileHeight = round(heightMap[currentTile] * 8.5) - 1
			map.set_cell(currentTile, 1,Vector2i(clamp(tileHeight, 1, 5),0))
			
			tilesMap[currentTile].height = clamp(tileHeight, 1, 5) - 1

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
	noise.seed = randi()
	noise.noise_type = noiseType
	noise.fractal_octaves = octaves
	
	var noiseMap = {}
	for x in worldSize.x:
		for y in worldSize.y:
			var noiseValue = 2*(abs(noise.get_noise_2d(x,y)))
			noiseMap[Vector2(x,y)] = noiseValue
	return noiseMap
