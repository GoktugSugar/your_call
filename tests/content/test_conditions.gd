extends GutTest
## Options and lines that only some runs see: walking each chapter through every set of facts a run can
## reach, every question offers at least two options whose shares add up to about the whole crowd,
## every line with a condition is said on some run, and every fact a condition names is one an option
## remembers or the run knows.

const CHAPTERS_DIR := "res://content/chapters"
## How far a run's shown shares may stray from the whole crowd before they are scaled to it.
const SLACK := 6.0
## Facts the run remembers from its stages rather than from an option's data.
const STAGE_FACTS: PackedStringArray = ["button_woke", "button_auctioned", "button_shot", "button_spared"]

var _chapters: Array[ChapterData] = []


func before_all() -> void:
	var loader := ContentLoader.new(Profile.axis_ids())
	for file in DirAccess.get_files_at(CHAPTERS_DIR):
		if file.get_extension() == "json":
			var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(file))
			if chapter != null:
				_chapters.append(chapter)


## Every set of facts a run can have reached at each question of [param chapter], by question id, as
## lists of runs, starting from a run that remembers nothing.
func _reachable(chapter: ChapterData) -> Dictionary:
	var runs: Array[PackedStringArray] = [PackedStringArray()]
	var at := {}
	for beat in chapter.beats:
		var question := beat as QuestionData
		if question == null:
			continue
		at[question.id] = runs
		var next: Array[PackedStringArray] = []
		var seen := {}
		for facts in runs:
			var options := question.shown_options(_run_of(facts))
			if options.is_empty():
				options = PackedInt32Array([-1])
			for i in options:
				var after := PackedStringArray(facts)
				if i >= 0:
					for fact in question.options[i].remember:
						if not fact in after:
							after.append(fact)
				after.sort()
				var key := ",".join(after)
				if not seen.has(key):
					seen[key] = true
					next.append(after)
		runs = next
	return at


func _run_of(facts: PackedStringArray) -> RunState:
	var run := RunState.new()
	for fact in facts:
		run.remember(StringName(fact))
	return run


func test_every_run_is_offered_a_choice_whose_shares_add_up() -> void:
	var offenders := PackedStringArray()
	for chapter in _chapters:
		var reachable := _reachable(chapter)
		for beat in chapter.beats:
			var question := beat as QuestionData
			if question == null or question.is_tableau() or not question.has_conditional_options():
				continue
			for facts: PackedStringArray in reachable[question.id]:
				var shown := question.shown_options(_run_of(facts))
				var total := 0.0
				for i in shown:
					total += question.options[i].crowd
				if shown.size() < 2 or absf(total - RevealSplit.WHOLE) > SLACK:
					offenders.append("%s with [%s]: %d options adding up to %s" % [question.id, ",".join(facts),
							shown.size(), total])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_line_with_a_condition_is_said_on_some_run() -> void:
	var offenders := PackedStringArray()
	for chapter in _chapters:
		var reachable := _reachable(chapter)
		for beat in chapter.beats:
			var question := beat as QuestionData
			if question == null:
				continue
			for line in question.all_lines():
				if line.requires.is_empty() and line.excludes.is_empty():
					continue
				var said := false
				for facts: PackedStringArray in reachable[question.id]:
					said = said or line.holds(_run_of(facts))
				if not said:
					offenders.append(line.id)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_fact_a_condition_names_is_one_a_run_can_remember() -> void:
	var known := PackedStringArray(STAGE_FACTS)
	for chapter in _chapters:
		for beat in chapter.beats:
			if beat is QuestionData:
				for option in (beat as QuestionData).options:
					known.append_array(option.remember)
	var offenders := PackedStringArray()
	for chapter in _chapters:
		for beat in chapter.beats:
			var conditions: Array[PackedStringArray] = []
			if beat is QuestionData:
				for option in (beat as QuestionData).options:
					conditions.append(option.requires)
					conditions.append(option.excludes)
			for line in beat.all_lines():
				conditions.append(line.requires)
				conditions.append(line.excludes)
			for facts in conditions:
				for fact in facts:
					if not fact in known:
						offenders.append("%s: %s" % [beat.id, fact])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_the_dragon_offers_one_way_out_whoever_came_along() -> void:
	var situational: Array[StringName] = [&"together", &"their_hands", &"loose_beast", &"everything"]
	for chapter in _chapters:
		var boss := chapter.find_beat(&"boss") as QuestionData
		if boss == null:
			continue
		for facts: PackedStringArray in _reachable(chapter)[&"boss"]:
			var count := 0
			for i in boss.shown_options(_run_of(facts)):
				if boss.options[i].id in situational:
					count += 1
			assert_eq(count, 1, "with [%s]" % ",".join(facts))
