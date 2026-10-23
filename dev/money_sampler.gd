extends Node2D
## Development only: the money chapter's stages with a wallet already spent, for judging their layout.
## [code]--show=receipt[/code] (the default) prints the receipt for a run that bought a lot and passed
## on more; [code]--show=buyback[/code] lays out the buyback's rows; [code]--show=shop[/code] stages the
## stranger's years after a few were bought. [code]--bought=N[/code] limits how many things were bought.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/money_sampler.tscn --show=receipt \
##     --out=C:/somewhere/shot --times=3
## [/codeblock]

## The chapter whose questions the stages are set up from.
@export_file("*.json") var chapter_path := "res://content/chapters/ch3_money.json"
## What the wallet starts with.
@export var start := 10000
## Things bought, in order: question id, receipt name, doodle, price, how many.
@export var bought: Array[PackedStringArray] = [
	PackedStringArray(["free_food", "Free food for life", "burrito", "1800", "1"]),
	PackedStringArray(["charisma", "Charisma", "charisma_figure", "3500", "1"]),
	PackedStringArray(["iq", "Ten More IQ", "iq_head", "2500", "1"]),
	PackedStringArray(["years", "A stranger's years", "stranger_clock", "2400", "3"]),
	PackedStringArray(["forgetting", "The cheap forgetting", "drifting_memory", "40", "1"]),
	PackedStringArray(["truth", "The truth", "question_mark", "900", "1"]),
	PackedStringArray(["cucumber", "The cucumber", "cucumber", "100", "1"]),
]
## Things passed on: question id, receipt name, doodle, price.
@export var passed: Array[PackedStringArray] = [
	PackedStringArray(["poverty", "End Poverty", "charity_hand", "10000"]),
	PackedStringArray(["rewind", "Rewind", "back_arrow", "6000"]),
	PackedStringArray(["no_pain", "No More Pain", "plaster", "4500"]),
	PackedStringArray(["one_voice", "One More Voice", "voice_head", "3400"]),
	PackedStringArray(["memory", "Perfect Memory", "sharp_head", "2800"]),
]
## How many years of the stranger's to have bought before the shop is shown.
@export_range(0, 40) var years_bought := 2
## Where the dialogue box sits in the game, outlined faintly for judging the layout.
@export var dialogue_box := Rect2(320.0, 830.0, 1280.0, 216.0)


func _ready() -> void:
	var args := DevArgs.parse()
	var show := str(args.get("show", "receipt"))
	var run := RunState.new()
	var wallet := run.open_wallet(start)
	var limit := int(args.get("bought", str(bought.size())))
	for entry in bought.slice(0, limit):
		var item := Purchase.make(StringName(entry[0]), entry[1], entry[2], int(entry[3]))
		item.units = int(entry[4])
		wallet.buy(item)
	for entry in passed:
		wallet.pass_on(Purchase.make(StringName(entry[0]), entry[1], entry[2], int(entry[3])))
	var beat_id: StringName = {"receipt": &"receipt", "buyback": &"buyback", "shop": &"years"}.get(show, &"receipt")
	var stage := _stage_for(beat_id, run)
	if stage == null:
		return
	await stage.enter()
	if show == "receipt":
		await stage.play_consequence(-1)
	elif show == "shop":
		for i in years_bought:
			await stage.play_consequence(0)
	queue_redraw()


func _draw() -> void:
	draw_rect(dialogue_box, InkPalette.get_default().faded, false, 2.0)


func _stage_for(beat_id: StringName, run: RunState) -> Stage:
	var loader := ContentLoader.new(Profile.axis_ids())
	var chapter := loader.load_chapter(chapter_path)
	var question := chapter.find_beat(beat_id) as QuestionData if chapter != null else null
	if question == null:
		push_error("money sampler: no %s in %s" % [beat_id, chapter_path])
		return null
	var type := str(question.stage.get("type", ""))
	var stage := (load(QuestionPlayer.STAGE_SCENE % [type, type]) as PackedScene).instantiate() as Stage
	stage.run = run
	add_child(stage)
	stage.setup(question)
	return stage
