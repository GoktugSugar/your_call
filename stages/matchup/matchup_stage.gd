class_name MatchupStage
extends DoodlesStage
## Who Would Win: a barroom "who would win a fight" argument. Two sides with "vs" between them, each over
## its label; a side that is many of something is drawn as a crowd of small copies, with the count in
## its label. Pointing at a side lifts it and clicking backs it, or the choice row's keys pick one; the
## pick is circled in amber and the other side dissolves. The reveal colours each bar in its side's
## colour. Stage data:
## [codeblock]
## {"type": "matchup", "sides": [{"doodle": "brawler", "count": 100, "role": "blue"},
##  {"doodle": "gorilla", "role": "secondary"}]}
## [/codeblock]
## A side names a [code]doodle[/code] in a palette [code]role[/code]; with a [code]count[/code] over
## one it is a crowd. [code]{"button": true}[/code] puts up the walking button itself, squared up to
## fight. [code]{"kills": true}[/code] makes a crowd of everyone the player has killed in the run, the
## last bear among them if she was shot. [code]asks[/code] picks the question's ask by what the run
## remembers: [code][{"if": "button_shot", "ask": "shot"}, {"ask": "spared"}][/code], the first that
## holds.
## Placeholders, in its labels only: [code]{kills}[/code], how many the player has killed.

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["kills"]

## The walking button, for a side that is the button itself.
@export var walker_scene: PackedScene
## How the walking button holds its arms, squared up.
@export var fighter_arms: ButtonArmPose
## What sits between the two sides.
@export var vs_text := "vs"

@export_group("Crowds")
## The most copies a crowd draws, whatever its count.
@export_range(1, 60) var crowd_most := 12
## A crowd of up to this many draws each one a little bigger.
@export_range(1, 20) var few_most := 5
## The size of each copy in a crowd, and in a small crowd, as a share of its natural size.
@export_range(0.05, 1.0, 0.01) var crowd_size := 0.36
@export_range(0.05, 1.0, 0.01) var few_size := 0.5
## How wide a crowd spreads.
@export_range(10.0, 600.0, 1.0) var crowd_width := 330.0
## How far each row of a crowd steps back, up the page.
@export_range(0.0, 120.0, 0.5) var crowd_row_step := 26.0
## The walking button's size, standing in for a doodle.
@export_range(0.1, 3.0, 0.01) var button_size := 1.15
## The size of the last bear among the dead, as a share of her size on the gun's stage.
@export_range(0.05, 2.0, 0.01) var bear_size := 0.45
## The palette role the dead are drawn in.
@export var dead_role := &"red"

var _roles: Array[StringName] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var sides: Array = for_question.stage.get("sides", [])
	for i in slots.size():
		var entry: Dictionary = sides[i] if i < sides.size() and sides[i] is Dictionary else {}
		_roles.append(StringName(str(entry.get("role", ""))))
		var side := _make_side(entry)
		if side != null:
			slots[i].add_child(side)
			_doodles[i] = side
	var labels := option_labels()
	for i in words.size():
		_place_word(words[i], labels[i] if i < labels.size() else "", slots[i].position)
	or_label.text = vs_text
	_place_or()


func fills() -> Dictionary:
	return {"kills": Numbers.grouped(maxi(run.kills.count, 1))}


func fill_keys() -> Dictionary:
	return {"kills": str(maxi(run.kills.count, 1))}


## The bar voted in each side's colour, the pick still named in amber.
func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	split.roles = _roles.duplicate()
	return split


func leave() -> void:
	for side in _doodles:
		if side != null:
			for child in side.get_children():
				if child is WalkingButton:
					(child as WalkingButton).fade_words()
	await super.leave()


func _make_side(entry: Dictionary) -> DoodleGroup:
	var role := StringName(str(entry.get("role", "")))
	if bool(entry.get("button", false)):
		return _button_side()
	if bool(entry.get("kills", false)):
		return _dead_side(str(entry.get("doodle", "brawler")), role if role != &"" else dead_role)
	var count := int(entry.get("count", 1))
	var id := str(entry.get("doodle", ""))
	if count > 1:
		var shown := mini(count, crowd_most)
		return DoodleGroup.crowd(id, shown, role, few_size if count <= few_most else crowd_size, crowd_width, crowd_row_step)
	return DoodleGroup.single(id, role, 1.0)


## The walking button itself, standing in for a doodle, squared up to fight.
func _button_side() -> DoodleGroup:
	var group := DoodleGroup.new()
	if walker_scene == null:
		return group
	var walker := walker_scene.instantiate() as WalkingButton
	walker.scale = Vector2.ONE * button_size
	group.add_child(walker)
	walker.alive = true
	if fighter_arms != null:
		walker.hold_arms(fighter_arms)
	return group


## Everyone the player has killed in the run, as a crowd of [param id] in [param role], with the last
## bear in front if she was among them.
func _dead_side(id: String, role: StringName) -> DoodleGroup:
	var count := maxi(run.kills.count, 1)
	var shown := mini(count, crowd_most)
	var group := DoodleGroup.crowd(id, shown, role, few_size if count <= few_most else crowd_size, crowd_width, crowd_row_step)
	if run.kills.has(&"bear") and SoulKind.exists(&"bear"):
		var bear := SoulKind.find(&"bear").make()
		bear.scale *= bear_size
		bear.color_override = role
		group.add_child(bear)
	return group
