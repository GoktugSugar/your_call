extends GutTest
## The bundled list of countries the pin in 2.10 can land on: every entry is complete and placeable,
## and its name follows the text rules, since the player reads it on the map and in the imp's line.

const COUNTRIES_PATH := "res://content/countries.json"
const KEYS: PackedStringArray = ["iso", "name", "people", "lat", "lon"]

var _countries: Array = []


func before_all() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(COUNTRIES_PATH))
	if data is Dictionary:
		_countries = data.get("countries", [])


func test_there_are_countries() -> void:
	assert_gt(_countries.size(), 0)


func test_every_country_is_complete_and_unique() -> void:
	var offenders := PackedStringArray()
	var seen := {}
	for country: Dictionary in _countries:
		for key in KEYS:
			if not country.has(key):
				offenders.append("%s: no %s" % [country.get("name", "?"), key])
		var iso := str(country.get("iso", ""))
		if seen.has(iso):
			offenders.append("%s is listed twice" % iso)
		seen[iso] = true
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_country_can_be_placed_and_counted() -> void:
	var offenders := PackedStringArray()
	for country: Dictionary in _countries:
		if float(country.get("people", 0)) <= 0.0:
			offenders.append("%s has no people" % country.get("name", "?"))
		if absf(float(country.get("lat", 0.0))) > 90.0 or absf(float(country.get("lon", 0.0))) > 180.0:
			offenders.append("%s is off the globe" % country.get("name", "?"))
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_no_name_has_a_dash_or_a_tag() -> void:
	var offenders := PackedStringArray()
	for country: Dictionary in _countries:
		var name := str(country.get("name", ""))
		if Markup.has_dash(name) or Markup.has_tags(name) or Markup.has_stray_brace(name):
			offenders.append(name)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))
