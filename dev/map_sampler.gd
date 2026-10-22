extends Node2D
## Development only: the nuke stage's world map with a pin in every country on the list, each named, so
## the coastlines and where the pins land can be judged. With [code]--pin=ISO[/code] it shows only that
## country's pin, then draws the mushroom cloud on at it, as the stage does.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/map_sampler.tscn --pin=IN \
##     --out=C:/somewhere/shot --times=1,3
## [/codeblock]

## The map.
@export var world: WorldMap
## The countries the pins go in.
@export_file("*.json") var countries_path := "res://content/countries.json"
## Size of the country codes beside the pins.
@export_range(8, 60) var code_size := 18
## Seconds before the mushroom cloud starts with [code]--pin[/code].
@export_range(0.0, 10.0, 0.05) var cloud_delay := 1.0
## Seconds the mushroom cloud takes to draw on.
@export_range(0.05, 10.0, 0.05) var cloud_draw := 1.4


func _ready() -> void:
	var only := str(DevArgs.parse().get("pin", ""))
	var last_spot := Vector2.ZERO
	for country in NukeStage.load_countries(countries_path):
		var iso := str(country.get("iso", ""))
		if not only.is_empty() and iso != only:
			continue
		var pin := MapPin.new()
		pin.position = world.position + world.project(float(country.get("lon", 0.0)), float(country.get("lat", 0.0)))
		add_child(pin)
		last_spot = pin.position
		var code := Label.new()
		code.text = iso
		code.add_theme_font_size_override(&"font_size", code_size)
		code.add_theme_color_override(&"font_color", InkPalette.get_default().secondary)
		code.position = pin.position + Vector2(6.0, -code_size * 1.2)
		add_child(code)
	if only.is_empty():
		return
	await get_tree().create_timer(cloud_delay).timeout
	var cloud := MushroomCloud.new()
	cloud.position = last_spot
	add_child(cloud)
	cloud.draw_on(cloud_draw)
