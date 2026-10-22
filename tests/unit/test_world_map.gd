extends GutTest
## The nuke stage's world map: it projects longitude and latitude onto itself edge to edge, every
## country on the list falls inside it on or right beside land, and the pin and the mushroom cloud draw.

const COUNTRIES_PATH := "res://content/countries.json"
## How far from a coastline or an island dot a pin may land, in map pixels: the smallest states are
## specks, and a tip on the coast still reads as landing on the country.
const SHORE_SLACK := 10.0

var _map: WorldMap


func before_each() -> void:
	_map = WorldMap.new()
	add_child_autofree(_map)


func test_the_corners_and_the_middle_project_onto_the_map_edges_and_origin() -> void:
	var half := _map.map_size * 0.5
	assert_almost_eq(_map.project(_map.lon_range.x, _map.lat_range.x), -half, Vector2.ONE * 0.01)
	assert_almost_eq(_map.project(_map.lon_range.y, _map.lat_range.y), half, Vector2.ONE * 0.01)
	var middle := Vector2((_map.lon_range.x + _map.lon_range.y) * 0.5, (_map.lat_range.x + _map.lat_range.y) * 0.5)
	assert_almost_eq(_map.project(middle.x, middle.y), Vector2.ZERO, Vector2.ONE * 0.01)


func test_a_longitude_west_of_the_left_edge_comes_round_from_the_right() -> void:
	assert_almost_eq(_map.project(-175.0, 0.0).x, _map.project(185.0, 0.0).x, 0.01)


func test_every_country_is_on_the_map() -> void:
	var offenders := PackedStringArray()
	for country in NukeStage.load_countries(COUNTRIES_PATH):
		if not _map.covers(float(country["lon"]), float(country["lat"])):
			offenders.append(str(country["iso"]))
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_pin_lands_on_or_beside_land() -> void:
	var lines := _map._build_lines(InkStyle.get_default(), InkPalette.get_default())
	var offenders := PackedStringArray()
	for country in NukeStage.load_countries(COUNTRIES_PATH):
		var at := _map.project(float(country["lon"]), float(country["lat"]))
		if not _on_land(at, lines):
			offenders.append(str(country["iso"]))
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_the_pin_and_the_cloud_draw_lines() -> void:
	var pin := MapPin.new()
	var cloud := MushroomCloud.new()
	add_child_autofree(pin)
	add_child_autofree(cloud)
	assert_gt(pin._build_lines(InkStyle.get_default(), InkPalette.get_default()).size(), 0)
	assert_gt(cloud._build_lines(InkStyle.get_default(), InkPalette.get_default()).size(), 0)


## Whether [param at] is inside a landmass, or within [constant SHORE_SLACK] of a coast or an island dot.
## The two inland seas are loops too, and a pin inside one would count as land; none is.
func _on_land(at: Vector2, lines: Array[InkLine]) -> bool:
	for line in lines:
		if line.dot_radius > 0.0:
			if at.distance_to(line.path[0]) <= SHORE_SLACK:
				return true
			continue
		if Geometry2D.is_point_in_polygon(at, line.path):
			return true
		for point in line.path:
			if at.distance_to(point) <= SHORE_SLACK:
				return true
	return false
