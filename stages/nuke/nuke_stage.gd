class_name NukeStage
extends Stage
## The cancer and nuke button: one red button that cures cancer for everyone, forever, at the price of
## one country chosen at random. Press it and a hand-drawn world map inks itself in, a red pin comes
## down and goes round and round over it while the imp talks, then drops onto a country from the
## bundled list. Its name and its people ink on beside it, and a small mushroom cloud doodles onto the
## spot. Stage data:
## [codeblock]
## {"type": "nuke", "button": "red", "countries": "res://content/countries.json",
##  "bands": [{"under": 100000, "key": "tiny"}, ..., {"key": "huge"}],
##  "caption": "{people} people, give or take"}
## [/codeblock]
## The option whose outcome has [code]press[/code] presses the button. The imp says the question's
## [code]spin[/code] lines while the pin goes round.
## Outcomes: [code]home[/code] when the pin lands on the player's own country, read from the system's
## region; otherwise the country's code when the pressing option has a reaction for that country;
## otherwise the key of the first band the country's people fall [code]under[/code] (a band with no
## [code]under[/code] takes the rest).
## Placeholders: [code]{country}[/code] the country's name and [code]{people}[/code] how many live there.

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["country", "people"]
## The outcome when the pin lands on the player's own country.
const HOME := &"home"
## The set of lines the imp says while the pin goes round.
const SPIN_SET := &"spin"

## The button.
@export var button: PushButton
## The world map, hidden until the button is pressed.
@export var world: WorldMap
## The pin.
@export var pin: MapPin
## The mushroom cloud.
@export var cloud: MushroomCloud
## The name of the country the pin lands on.
@export var name_label: Label
## Its people, under its name.
@export var caption_label: Label

@export_group("Map")
## Seconds the map takes to ink itself in.
@export_range(0.05, 10.0, 0.05) var map_draw := 1.8
## Seconds the button takes to fade once pressed.
@export_range(0.0, 3.0, 0.05) var button_fade := 0.5

@export_group("Pin")
## Where the pin comes in from, on the canvas, before it starts going round.
@export var pin_entry := Vector2(960.0, -80.0)
## Seconds the pin takes to come down onto the map.
@export_range(0.05, 3.0, 0.05) var pin_entry_time := 0.6
## Half the width and height of the loop the pin goes round over the map.
@export var spin_radii := Vector2(420.0, 170.0)
## Seconds the pin takes to go once round.
@export_range(0.2, 10.0, 0.05) var spin_period := 1.6
## Seconds the pin keeps going round after the imp has finished, before it drops.
@export_range(0.0, 5.0, 0.05) var spin_after := 0.3
## Seconds the pin takes to drop onto its country.
@export_range(0.05, 3.0, 0.05) var drop_time := 0.55
## Whirs while the pin goes round, for as long as it does.
@export var whirr_sound: SoundCue = preload("res://game/audio/cues/pin_whirr.tres")
## Thunks as the pin drops onto the country.
@export var drop_sound: SoundCue = preload("res://game/audio/cues/pin_drop.tres")

@export_group("Words")
## Size of the country's name.
@export_range(8, 200) var name_size := 56
## Palette role of the country's name: amber, as the imp's lines colour it, so it stands off the ink map.
@export var name_role := &"amber"
## Size of the line under it.
@export_range(8, 120) var caption_size := 34
## Palette role of the line under it.
@export var caption_role := &"secondary"
## Width of the halo of paper round the words, so the coastlines never run through them. Zero for none.
@export_range(0, 40) var halo_size := 10
## Palette role of the halo.
@export var halo_role := &"paper"
## Gap between the top of the mushroom cloud and the words over it.
@export_range(0.0, 200.0, 1.0) var words_gap := 16.0
## Seconds the words take to fade in.
@export_range(0.0, 3.0, 0.05) var words_fade := 0.5
## The words stay inside this part of the canvas, clear of the imp's wings.
@export var words_area := Rect2(290.0, 90.0, 1340.0, 700.0)

@export_group("Cloud")
## Seconds the mushroom cloud takes to doodle itself on.
@export_range(0.05, 5.0, 0.05) var cloud_draw := 1.4
## Booms, muffled, as the cloud doodles itself on.
@export var boom_sound: SoundCue = preload("res://game/audio/cues/boom.tres")
## Seconds the stage holds once the cloud is up.
@export_range(0.0, 5.0, 0.05) var after_hold := 0.8

@export_group("Testing")
## A country code to treat as the player's own, instead of the system's region. Empty reads the region.
@export var home_override := ""
## A country code the pin always lands on. Empty picks at random.
@export var target_override := ""

## How far into a bounce eased out, as a share of its time, it first strikes home: one over this.
const _BOUNCE_LANDS := 2.75

var _countries: Array[Dictionary] = []
var _target := {}
var _home := ""
var _press := -1
var _spinning := false
var _spin_phase := 0.0


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	button.look = ButtonLook.find(StringName(str(data.get("button", "red"))))
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("press", false)):
			_press = i
	button.hover_changed.connect(func(hovered: bool) -> void: option_hovered.emit(_press if hovered else -1))
	button.clicked.connect(func() -> void: option_committed.emit(_press))
	_countries = load_countries(str(data.get("countries", "")))
	_home = home_override if not home_override.is_empty() else region_code()
	_target = _pick_target()
	for drawing: InkDrawing in [world, pin, cloud]:
		drawing.visible = false
	for label: Label in [name_label, caption_label]:
		label.modulate.a = 0.0
	var palette := InkPalette.get_default()
	name_label.add_theme_font_size_override(&"font_size", name_size)
	name_label.add_theme_color_override(&"font_color", palette.color(name_role))
	caption_label.add_theme_font_size_override(&"font_size", caption_size)
	caption_label.add_theme_color_override(&"font_color", palette.color(caption_role))
	for label: Label in [name_label, caption_label]:
		label.add_theme_constant_override(&"outline_size", halo_size)
		label.add_theme_color_override(&"font_outline_color", palette.color(halo_role))
	set_process(false)


func _process(delta: float) -> void:
	if not _spinning:
		return
	_spin_phase += delta / spin_period
	pin.position = world.position + _spin_point(_spin_phase)


func set_choosing(active: bool) -> void:
	button.live = active and _press >= 0


func highlight_option(index: int) -> void:
	button.highlighted = index >= 0 and index == _press


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	button.highlighted = false
	if index != _press or _target.is_empty():
		await get_tree().create_timer(after_hold, false).timeout
		return &""
	await button.press()
	button.dissolve_away(button_fade)
	world.visible = true
	await world.draw_on(map_draw).finished
	await _spin_while_he_talks()
	await _drop_on_target()
	await _name_the_target()
	pin.dissolve_away(cloud_draw * 0.5)
	cloud.position = pin.position
	cloud.visible = true
	run.kills.add(&"people", int(_target.get("people", 0)))
	Sfx.play(boom_sound)
	await cloud.draw_on(cloud_draw).finished
	await get_tree().create_timer(after_hold, false).timeout
	return _outcome()


func fills() -> Dictionary:
	if _target.is_empty():
		return {}
	return {"country": str(_target.get("name", "")), "people": Numbers.grouped(int(_target.get("people", 0)))}


func fill_keys() -> Dictionary:
	var iso := str(_target.get("iso", ""))
	return {"country": iso, "people": iso}


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	for label: Label in [name_label, caption_label]:
		fade.tween_property(label, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func option_point(index: int) -> Vector2:
	return button.press_point() if index >= 0 and index == _press else Vector2.INF


## The countries in the list at [param path], each with its code, name, people, latitude and longitude.
static func load_countries(path: String) -> Array[Dictionary]:
	var countries: Array[Dictionary] = []
	var loader := ContentLoader.new()
	var data: Variant = loader.read_json(path)
	if data is Dictionary:
		for country: Variant in data.get("countries", []):
			if country is Dictionary:
				countries.append(country)
	for problem in loader.problems:
		push_error(problem)
	return countries


## The player's own country, as a two letter code from the system's region, or empty when it has none.
static func region_code() -> String:
	for part in OS.get_locale().split("_"):
		if part.length() == 2 and part == part.to_upper():
			return part
	return ""


## The key of the first of [param bands] that [param people] fall under; a band with no
## [code]under[/code] takes the rest.
static func band_of(people: int, bands: Array) -> StringName:
	for band: Variant in bands:
		if band is Dictionary and (not band.has("under") or people < int(band["under"])):
			return StringName(str(band.get("key", "")))
	return &""


## Every way this stage can fill its question's lines, for the voice tools and the tests: the line
## for the player's own country with every country, and each band's lines with the countries in it.
static func fill_variants(for_question: QuestionData) -> Dictionary:
	var variants := {}
	var countries := load_countries(str(for_question.stage.get("countries", "")))
	var bands: Array = for_question.stage.get("bands", [])
	for option in for_question.options:
		for result: StringName in option.reactions:
			for line: LineData in option.reactions[result]:
				if line.placeholders().is_empty():
					continue
				var sets: Array = []
				for country in countries:
					var iso := str(country.get("iso", ""))
					var fits := result == HOME or StringName(iso) == result \
							or (not option.reactions.has(StringName(iso)) and band_of(int(country.get("people", 0)), bands) == result)
					if fits:
						sets.append({"fills": {"country": str(country.get("name", "")),
								"people": Numbers.grouped(int(country.get("people", 0)))},
								"keys": {"country": iso, "people": iso}})
				variants[line.id] = sets
	return variants


## What the imp reacts to: the player's own country, a country he has a line for, or its size.
func _outcome() -> StringName:
	var iso := StringName(str(_target.get("iso", "")))
	if not _home.is_empty() and str(iso) == _home:
		return HOME
	if _press >= 0 and question.options[_press].reactions.has(iso):
		return iso
	return band_of(int(_target.get("people", 0)), question.stage.get("bands", []))


func _pick_target() -> Dictionary:
	if _countries.is_empty():
		return {}
	if not target_override.is_empty():
		for country in _countries:
			if str(country.get("iso", "")) == target_override:
				return country
	return _countries[randi() % _countries.size()]


## The pin comes down onto the map and goes round and round while the imp says his piece.
func _spin_while_he_talks() -> void:
	pin.position = pin_entry
	pin.visible = true
	pin.draw_on(pin_entry_time)
	_spin_phase = 0.0
	var arrive := create_tween()
	arrive.tween_property(pin, ^"position", world.position + _spin_point(0.0), pin_entry_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await arrive.finished
	_spinning = true
	set_process(true)
	var whirr := Sfx.play(whirr_sound)
	var lines := question.lines_in(SPIN_SET)
	if not lines.is_empty():
		await dialogue.say(lines, false, true)
		await dialogue.close()
	await get_tree().create_timer(spin_after, false).timeout
	_spinning = false
	set_process(false)
	Sfx.release(whirr)


## Where on its loop over the map the pin is, [param phase] turns round, from the middle of the map.
func _spin_point(phase: float) -> Vector2:
	var angle := phase * TAU
	return Vector2(cos(angle) * spin_radii.x, sin(angle) * spin_radii.y)


func _drop_on_target() -> void:
	var spot := world.position + world.project(float(_target.get("lon", 0.0)), float(_target.get("lat", 0.0)))
	var drop := create_tween()
	drop.tween_property(pin, ^"position", spot, drop_time).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# A bounce eased out first strikes home just over a third of the way through.
	drop.parallel().tween_callback(Sfx.play.bind(drop_sound)).set_delay(drop_time / _BOUNCE_LANDS)
	await drop.finished


## The country's name and its people ink on over the pin, high enough to clear the cloud to come,
## and kept clear of the edges: under the pin when there is no room over it.
func _name_the_target() -> void:
	name_label.text = str(_target.get("name", ""))
	caption_label.text = str(question.stage.get("caption", "{people}")).format(fills())
	name_label.reset_size()
	caption_label.reset_size()
	var width := maxf(name_label.size.x, caption_label.size.x)
	var height := name_label.size.y + caption_label.size.y
	var top := Vector2(pin.position.x - width * 0.5, pin.position.y - cloud.height - words_gap - height)
	if top.y < words_area.position.y:
		top.y = pin.position.y + words_gap
	top.x = clampf(top.x, words_area.position.x, words_area.end.x - width)
	name_label.position = Vector2(top.x + (width - name_label.size.x) * 0.5, top.y)
	caption_label.position = Vector2(top.x + (width - caption_label.size.x) * 0.5, top.y + name_label.size.y)
	var fade := create_tween().set_parallel(true)
	for label: Label in [name_label, caption_label]:
		fade.tween_property(label, ^"modulate:a", 1.0, words_fade)
	await fade.finished
