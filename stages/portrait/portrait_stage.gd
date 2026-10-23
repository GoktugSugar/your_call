class_name PortraitStage
extends Stage
## The player's portrait, for The Portrait: a scale for each axis of the silent profile, one under the
## next, its two poles named at its ends, with a mark sliding to where the player leans, read against how
## often the axis came up. The imp goes down them, each scale lighting amber while he says his line for
## it: the stage data's line set for the pole the player leans toward, or for the middle when they lean
## neither way. No numbers. A tableau, its lines said scale by scale.
## Stage data: [code]{"type": "portrait", "middle": 0.15}[/code], and line sets named for each axis and
## [code]first[/code], [code]second[/code] or [code]middle[/code], such as [code]one_many_first[/code].
## Outcome: [code]portrait[/code].

## The scales, laid out from the top: where the first one's middle is, and the gap down to the next.
@export var first_scale := Vector2(960.0, 160.0)
@export_range(10.0, 300.0, 1.0) var scale_gap := 82.0
## How long each scale is.
@export_range(10.0, 1600.0, 1.0) var scale_length := 640.0
## Size and palette role of the poles' names.
@export_range(8, 120) var pole_size := 32
@export var pole_role := &"secondary"
## The gap between a scale's end and its pole's name.
@export_range(0.0, 100.0, 1.0) var pole_gap := 18.0
## How many nudges' worth of doubt a leaning is read against, so an axis that came up once does not read
## as all the way over. Keep it in step with the posting's.
@export_range(0.0, 20.0, 0.1) var lean_prior := 2.0
## How far from the middle a lean must be to count as leaning, when the data does not say.
@export_range(0.0, 1.0, 0.01) var default_middle := 0.15
## Seconds a mark takes to slide to where the player leans.
@export_range(0.05, 3.0, 0.05) var slide_time := 0.7

var _scales: Array[PortraitScale] = []
var _axes := PackedStringArray()
var _labels: Array[Label] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var poles := Profile.axis_poles()
	_axes = Profile.axis_ids()
	for i in _axes.size():
		var scale_line := PortraitScale.new()
		scale_line.length = scale_length
		scale_line.position = first_scale + Vector2(0.0, i * scale_gap)
		add_child(scale_line)
		_scales.append(scale_line)
		var names: PackedStringArray = poles.get(_axes[i], PackedStringArray())
		if names.size() == 2:
			_name_pole(names[0], scale_line.position - Vector2(scale_length * 0.5 + pole_gap, 0.0), HORIZONTAL_ALIGNMENT_RIGHT)
			_name_pole(names[1], scale_line.position + Vector2(scale_length * 0.5 + pole_gap, 0.0), HORIZONTAL_ALIGNMENT_LEFT)


func enter() -> void:
	for label in _labels:
		create_tween().tween_property(label, ^"modulate:a", 1.0, enter_duration).from(0.0)
	await super.enter()


func leave() -> void:
	for label in _labels:
		create_tween().tween_property(label, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


## Down the scales: each lights, its mark slides to the lean, and the imp says his line for it.
func play_consequence(_index: int) -> StringName:
	var middle := float(question.stage.get("middle", default_middle))
	for i in _axes.size():
		var axis := StringName(_axes[i])
		var lean := run.profile.lean(axis, lean_prior)
		var scale_line := _scales[i]
		scale_line.lit = true
		create_tween().tween_property(scale_line, ^"lean", lean, slide_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var side := "middle" if absf(lean) < middle else ("first" if lean < 0.0 else "second")
		var lines := LineData.for_run(question.lines_in(StringName("%s_%s" % [axis, side])), run)
		if not lines.is_empty():
			await dialogue.say(fill(lines))
			await dialogue.close()
		scale_line.lit = false
	return &"portrait"


func _name_pole(text: String, at: Vector2, align: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", pole_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(pole_role))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = align
	add_child(label)
	label.size = label.get_combined_minimum_size()
	label.position = Vector2(at.x - (label.size.x if align == HORIZONTAL_ALIGNMENT_RIGHT else 0.0), at.y - label.size.y * 0.5)
	label.modulate.a = 0.0
	_labels.append(label)
