class_name PostingStage
extends Stage
## The Posting, the last beat of The Portrait: where the player goes next in the void, picked by the
## axis they leaned on hardest and which way, read against how often it came up. Whatever they become
## inks on large in the middle of the page: a lever, a plea's words, the booth's curtain, the gavel at
## last, the trolley, the rails, a clerk with forms, a push button, the die, the crowd's bars, the map's
## pin, or nothing at all, the paper itself. A portrait that leans nowhere far takes the imp's own job,
## and he steps out into the middle of the page. A tableau; its outcome names the posting, and the
## question's endings fire by it.
## Stage data:
## [codeblock]
## {"type": "posting", "nowhere": 0.2, "nowhere_posting": "imp", "plea": {"text": "Please, not me."},
##  "postings": {"one_many": ["plea", "lever"], "mercy_justice": ["curtain", "gavel"], ...}}
## [/codeblock]
## [code]postings[/code] names, for each axis, the posting for its first pole and for its second.
## Outcomes: the posting's name.

## Where the posting stands, its ground.
@export var posting_spot := Vector2(960.0, 640.0)
## How big each kind of posting is drawn.
@export_range(0.2, 6.0, 0.01) var doodle_scale := 1.8
@export_range(0.2, 6.0, 0.01) var control_scale := 2.6
@export_range(0.2, 6.0, 0.01) var figure_scale := 1.7
## How far the rails run either side of the middle.
@export_range(10.0, 1000.0, 1.0) var rails_half := 520.0
## Size of a plea's words.
@export_range(8, 200) var plea_size := 64
## The crowd's bars: their shares, the length of a whole one, and the gap between them.
@export var crowd_shares := PackedFloat32Array([62.0, 27.0, 11.0])
@export_range(10.0, 1600.0, 1.0) var crowd_length := 620.0
@export_range(10.0, 200.0, 1.0) var crowd_gap := 64.0
## Where the clerk holds the forms, from its feet, and how big.
@export var forms_offset := Vector2(36.0, -150.0)
@export_range(0.1, 3.0, 0.01) var forms_scale := 0.7
## How many nudges' worth of doubt a leaning is read against. Keep it in step with the portrait's.
@export_range(0.0, 20.0, 0.1) var lean_prior := 2.0
## How far a lean must reach before it decides the posting, when the data does not say.
@export_range(0.0, 1.0, 0.01) var default_nowhere := 0.2
## Seconds the posting takes to ink on, and the stage holds after.
@export_range(0.05, 5.0, 0.05) var ink_time := 1.4
@export_range(0.0, 5.0, 0.05) var after_hold := 0.6

## The push button, for a posting as a button.
@export var button_scene: PackedScene
## The floating words, for a posting as a plea.
@export var words_scene: PackedScene

var _posting := &""
var _made: Array[Node2D] = []
var _plea: Plea


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_posting = posting_for(run.profile)
	_make(_posting)
	for node in _made:
		node.modulate.a = 0.0


## The posting [param profile] earns: the posting for the pole of the axis it leans on hardest, or the
## stage data's posting for nowhere when no lean reaches far enough.
func posting_for(profile: Profile) -> StringName:
	var postings: Variant = question.stage.get("postings", {})
	var best := &""
	var best_lean := 0.0
	if postings is Dictionary:
		for axis: Variant in postings:
			var lean := profile.lean(StringName(str(axis)), lean_prior)
			if absf(lean) > absf(best_lean):
				best_lean = lean
				best = StringName(str(axis))
	if best == &"" or absf(best_lean) < float(question.stage.get("nowhere", default_nowhere)):
		return StringName(str(question.stage.get("nowhere_posting", "imp")))
	var pair: Array = postings[String(best)]
	return StringName(str(pair[0 if best_lean < 0.0 else 1]))


## The posting inks on, the imp stepping into the middle when it is his job.
func play_consequence(_index: int) -> StringName:
	if _plea != null:
		_plea.write_on()
	var tween := create_tween().set_parallel(true)
	for node in _made:
		tween.tween_property(node, ^"modulate:a", 1.0, ink_time * 0.4)
		if node is InkDrawing:
			tween.tween_property(node, ^"reveal", 1.0, ink_time).from(0.0)
	if _posting == StringName(str(question.stage.get("nowhere_posting", "imp"))) and imp != null:
		await imp.travel_to(posting_spot)
	await tween.finished
	await get_tree().create_timer(after_hold, false).timeout
	return _posting


func _make(posting: StringName) -> void:
	match posting:
		&"lever":
			_place(Lever.new(), control_scale)
		&"plea":
			_plea = words_scene.instantiate() as Plea
			var text: Variant = question.stage.get("plea", {})
			add_child(_plea)
			_plea.set_words(str(text.get("text", "")) if text is Dictionary else "")
			_plea.label.add_theme_font_size_override(&"normal_font_size", plea_size)
			_plea.place(posting_spot)
			_made.append(_plea)
		&"curtain", &"gavel":
			_place(DoodlesStage.make_doodle(String(posting)), doodle_scale)
		&"trolley":
			_place(TrolleyCart.new(), doodle_scale)
		&"rails":
			var rails := Track.new()
			rails.path_points = PackedVector2Array([Vector2(-rails_half, 0.0), Vector2(rails_half, 0.0)])
			_place(rails, 1.0)
		&"clerk":
			var clerk := SoulKind.find(&"stranger").make()
			clerk.scale *= figure_scale
			_place(clerk, -1.0)
			var forms := DoodlesStage.make_doodle("forms")
			if forms != null:
				forms.position = forms_offset * figure_scale
				forms.scale = Vector2.ONE * forms_scale
				clerk.add_child(forms)
		&"button":
			_place(button_scene.instantiate() as Node2D, control_scale)
		&"die":
			_place(Die.new(), control_scale)
		&"crowd":
			for i in crowd_shares.size():
				var bar := CrowdBar.new()
				bar.full_length = crowd_length
				bar.value = crowd_shares[i]
				bar.position = posting_spot + Vector2(-crowd_length * 0.5, -crowd_gap * (crowd_shares.size() - i))
				bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var holder := Node2D.new()
				holder.add_child(bar)
				add_child(holder)
				_made.append(holder)
		&"pin":
			_place(MapPin.new(), control_scale)


## Adds [param node] at the posting's spot, at [param size] times its own size (or as it is, below 0).
func _place(node: Node2D, size: float) -> void:
	if node == null:
		return
	node.position = posting_spot
	if size > 0.0:
		node.scale = Vector2.ONE * size
	add_child(node)
	_made.append(node)
